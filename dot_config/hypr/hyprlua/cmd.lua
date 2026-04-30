local uv = hypr.uv

-- =========================
-- 类型定义
-- =========================

---@class SystemResult
---@field code integer
---@field signal integer
---@field stdout string
---@field stderr string

---@class SystemOptions
---@field cwd? string
---@field env? table<string, string>
---@field callback? fun(result:SystemResult)

---@class SystemProcess
---@field handle uv_process_t
---@field pid integer
---@field stdin uv_pipe_t
---@field stdout uv_pipe_t
---@field stderr uv_pipe_t
---@field _stdout_chunks string[]
---@field _stderr_chunks string[]
---@field _exited boolean
---@field _code integer|nil
---@field _signal integer|nil
---@field _callbacks fun(res:SystemResult)[]
local SystemProcess = {}
SystemProcess.__index = SystemProcess

-- =========================
-- 构造
-- =========================

---@param cmd string[]|string
---@param opts? SystemOptions
---@return SystemProcess
function SystemProcess.new(cmd, opts)
	opts = opts or {}

	local self = setmetatable({}, SystemProcess)

	self._stdout_chunks = {}
	self._stderr_chunks = {}
	self._callbacks = { opts.callback }
	self._exited = false

	self.stdin = uv.new_pipe(false)
	self.stdout = uv.new_pipe(false)
	self.stderr = uv.new_pipe(false)
	local args = nil
	if type(cmd) == "table" then
		args = { unpack(cmd, 2) }
		cmd = cmd[1]
	end

	local handle, pid, err = uv.spawn(cmd, {
		args = args,
		stdio = { self.stdin, self.stdout, self.stderr },
		cwd = opts.cwd,
		env = opts.env,
	}, function(code, signal)
		self:_finalize(code, signal)
	end)
	if not handle then
		print(err)
	end
	self.handle = handle
	self.pid = pid

	uv.read_start(self.stdout, function(err, data)
		self:_on_stdout(err, data)
	end)

	uv.read_start(self.stderr, function(err, data)
		self:_on_stderr(err, data)
	end)

	return self
end

-- =========================
-- 内部方法
-- =========================

---@private
---@param err string|nil
---@param data string|nil
function SystemProcess:_on_stdout(err, data)
	assert(not err, err)
	if data then
		self._stdout_chunks[#self._stdout_chunks + 1] = data
	end
end

---@private
---@param err string|nil
---@param data string|nil
function SystemProcess:_on_stderr(err, data)
	assert(not err, err)
	if data then
		self._stderr_chunks[#self._stderr_chunks + 1] = data
	end
end

---@private
---@param code integer
---@param signal integer
function SystemProcess:_finalize(code, signal)
	self._code = code
	self._signal = signal
	self._exited = true

	self.stdout:read_stop()
	self.stderr:read_stop()

	self.stdout:close()
	self.stderr:close()
	self.stdin:close()
	self.handle:close()

	local res = self:result()

	for _, cb in ipairs(self._callbacks) do
		cb(res)
	end
	self._callbacks = {}
end

-- =========================
-- 公共 API
-- =========================

---@return boolean
function SystemProcess:is_exited()
	return self._exited
end

---@return SystemResult
function SystemProcess:result()
	return {
		code = self._code,
		signal = self._signal,
		stdout = table.concat(self._stdout_chunks),
		stderr = table.concat(self._stderr_chunks),
	}
end

---@param sig? string
---@return nil
function SystemProcess:kill(sig)
	if self.handle and not self._exited then
		uv.process_kill(self.handle, sig or "sigterm")
	end
end

---@return integer
function SystemProcess:get_pid()
	return self.pid
end

-- =========================
-- stdin
-- =========================

---@param data string
---@return nil
function SystemProcess:write(data)
	uv.write(self.stdin, data, function(err)
		assert(not err, err)
	end)
end

---@param line string
---@return nil
function SystemProcess:write_line(line)
	self:write(line .. "\n")
end

---@return nil
function SystemProcess:close_stdin()
	self.stdin:shutdown(function()
		self.stdin:close()
	end)
end

-- =========================
-- coroutine await
-- =========================

---@return SystemResult
function SystemProcess:await()
	if self._exited then
		return self:result()
	end

	local co = coroutine.running()
	assert(co, "await must be in coroutine")

	table.insert(self._callbacks, function(res)
		coroutine.resume(co, res)
	end)

	return coroutine.yield()
end

-- =========================
-- 导出
-- =========================

local M = {}

---@param cmd string[]|string
---@param opts? SystemOptions
---@return SystemProcess
function M.system(cmd, opts)
	return SystemProcess.new(cmd, opts)
end
return M
