local commit_history = ""
local last_space_time = 0
local simp_table = require("tiger.simp_table")
local f = io.popen("uname", "r")
local system = "unknown"
if f then
	system = f:read("a"):gsub("%s", "")
	f:close()
end
local notify
if system == "Linux" then
	notify = function(str)
		io.popen('notify-send "' .. str:gsub('"', '\\"') .. '"'):close()
	end
elseif system == "Darwin" then
	notify = function(str)
		os.execute("osascript -e 'display notification \"" .. str:gsub('"', '\\"') .. '" with title "rime"\'')
	end
else
	notify = function(str) end
end
local function commit_text(env, text)
	local input = env.engine.context.input
	local simp = simp_table[text]
	if simp and input ~= simp then
		notify("use " .. simp .. " instead of " .. input .. " to input " .. text)
	end
	env.engine:commit_text(text)
	env.engine.context:clear()
end
local clear_on_missing_code = function(key, env)
	local input = env.engine.context.input
	local commit = env.engine.context:get_commit_text()
	if key.keycode == string.byte(" ") then
		local ctime = rime_api.get_time_ms()
		if ctime < last_space_time + 100 then
			return 1
		end
		last_space_time = ctime
		if #input == 0 then
			return 2
		end
		if not input:match("^[a-z]") then
			return 2
		end
		commit = commit:gsub("[a-z]", "")
		if #commit == 0 then
			env.engine.context:clear()
			return 1
		end
		commit_history = commit:sub(utf8.offset(commit, -1))
		commit_text(env, commit)
		return 1
	end
	if #input == 0 then
		return 2
	end
	if not input:match("^[a-z]") then
		return 2
	end
	if key.keycode == string.byte(";") and #input % 4 == 1 and string.sub(input, -1, -1) == "z" then
		if #input == 1 then
			commit_text(env, commit_history)
		else
			commit = commit:sub(1, utf8.offset(commit, -1) - 1)
			commit_text(env, commit .. commit:sub(utf8.offset(commit, -1)))
		end
		return 1
	end
	if key.keycode == string.byte(",") or key.keycode == string.byte(".") then
		commit = commit:gsub("[a-z]", "")
		if #commit == 0 then
			env.engine.context:clear()
			return 1
		end
		commit_history = commit:sub(utf8.offset(commit, -1))
		commit_text(env, commit)
		return 2
	end
	return 2
end
return clear_on_missing_code
