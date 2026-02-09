local M = {}
local json = hypr.json
local uv = hypr.uv

--- get data from "hyprctl command -j" and convert it into lua table
---@param command string
---@return table
function M.get_data_from_hyprctl(command)
	-- command = "hyprctl " .. command .. " -j"
	-- local pipe = io.popen(command)
	-- local result
	-- if pipe then
	-- 	result = json.decode(pipe:read("*a"))
	-- 	pipe:close()
	-- end
	-- return result
	local out, err, code = M.cmd("hyprctl", { "-j", command })
	if code ~= 0 then
		error(err)
	end
	return json.decode(out)
end

--- return a function to get data from hyprctl
---@param command string
---@return fun():table
function M.function_to_get_data_from_hyprctl(command)
	return function()
		return M.get_data_from_hyprctl(command)
	end
end

M.keyword = setmetatable({}, {
	__index = function(t, k)
		rawset(t, k, function(...)
			M.keyword(k, ...)
		end)
		return rawget(t, k)
	end,
	__call = function(t, command, arg1, ...)
		local args = { ... }
		local arg = arg1
		for index, value in ipairs(args) do
			arg = arg .. "," .. value
		end
		local out, err, code = M.cmd.hyprctl({ "keyword", command, arg })
		return out, err, code
	end,
})
---@type table<string,function>
M.dispatch = setmetatable({}, {
	__index = function(t, k)
		rawset(t, k, function(...)
			M.dispatch(k, ...)
		end)
		return rawget(t, k)
	end,
	__call = function(t, command, arg1, ...)
		local args = { ... }
		local arg = arg1
		for index, value in ipairs(args) do
			arg = arg .. "," .. value
		end
		local out, err, code = M.cmd.hyprctl({ "dispatch", command, arg })
		return out, err, code
	end,
})

local function async_cmd(command, args, opts)
	local callback
	if type(opts) == "function" then
		callback = opts
		opts = {}
	elseif type(opts) == "table" then
		callback = opts.callback
	end
	opts.args = args
	opts.stdio = opts.stdio or { nil, nil, nil }
	local handle
	handle = uv.spawn(command, opts, function(code, signal)
		uv.close(handle)
		if callback then
			callback(code, signal)
		end
	end)
	return handle
end
local ffi = require("ffi")

ffi.cdef([[
  typedef int pid_t;
  typedef int ssize_t;

  pid_t fork(void);
  int pipe(int pipefd[2]);
  int dup2(int oldfd, int newfd);
  int close(int fd);
  int execvp(const char *file, char *const argv[]);
  pid_t waitpid(pid_t pid, int *wstatus, int options);
  ssize_t read(int fd, void *buf, size_t count);
  void _exit(int status);
]])

local function spawn_blocking(cmd, args, opts)
	opts = opts or {}
	local merge_err = opts.merge_err or false

	local pipe_out = ffi.new("int[2]")
	local pipe_err = ffi.new("int[2]")
	assert(ffi.C.pipe(pipe_out) == 0)
	if not merge_err then
		assert(ffi.C.pipe(pipe_err) == 0)
	end

	local pid = ffi.C.fork()
	assert(pid >= 0, "fork failed")

	if pid == 0 then
		-- 子进程
		ffi.C.close(pipe_out[0])
		if not merge_err then
			ffi.C.close(pipe_err[0])
		end

		ffi.C.dup2(pipe_out[1], 1) -- stdout → pipe
		if merge_err then
			ffi.C.dup2(pipe_out[1], 2) -- stderr → 同一个 pipe
		else
			ffi.C.dup2(pipe_err[1], 2) -- stderr → 单独的 pipe
			ffi.C.close(pipe_err[1])
		end
		ffi.C.close(pipe_out[1])

		-- 准备 argv
		local argv = ffi.new("char*[?]", #args + 2)
		argv[0] = ffi.new("char[?]", #cmd + 1, cmd)
		for i, a in ipairs(args) do
			argv[i] = ffi.new("char[?]", #a + 1, a)
		end
		argv[#args + 1] = nil

		ffi.C.execvp(cmd, argv)
		ffi.C._exit(127) -- exec失败
	end

	-- 父进程
	ffi.C.close(pipe_out[1])
	if not merge_err then
		ffi.C.close(pipe_err[1])
	end

	local function read_all(fd)
		local buf = ffi.new("char[4096]")
		local chunks = {}
		while true do
			local n = ffi.C.read(fd, buf, 4096)
			if n <= 0 then
				break
			end
			table.insert(chunks, ffi.string(buf, n))
		end
		return table.concat(chunks)
	end

	local stdout_data = read_all(pipe_out[0])
	ffi.C.close(pipe_out[0])

	local stderr_data = nil
	if not merge_err then
		stderr_data = read_all(pipe_err[0])
		ffi.C.close(pipe_err[0])
	end

	local status = ffi.new("int[1]")
	ffi.C.waitpid(pid, status, 0)
	local code = bit.rshift(status[0], 8) -- exit code 位于高8位

	if merge_err then
		return stdout_data, code
	else
		return stdout_data, stderr_data, code
	end
end

---@type table<string,fun(...):string,string,number>
M.cmd = setmetatable({}, {
	__index = function(t, k)
		rawset(t, k, function(...)
			return M.cmd(k, ...)
		end)
		return rawget(t, k)
	end,
	__call = function(t, command, ...)
		local args = { ... }
		local opts = {}
		if type(args[1]) == "table" then
			if type(args[1][1]) == "string" then
				args = args[1]
			else
				opts = args[1]
				args = {}
			end
		end
		if type(args[#args]) == "table" then
			opts = table.remove(args)
		end
		if opts.async then
			return async_cmd(command, args, opts)
		else
			return spawn_blocking(command, args)
		end
	end,
})

---
---@param fn function
---@param delay integer? time in ms
---@return function
M.debounce = function(fn, delay)
	delay = delay or 200
	local timer = nil
	return function(...)
		local args = { ... }
		if timer then
			timer:stop()
			timer:close()
		end
		timer = uv.new_timer()
		timer:start(delay, 0, function()
			fn(unpack(args))
			timer:stop()
			timer:close()
			timer = nil
		end)
	end
end

return M
