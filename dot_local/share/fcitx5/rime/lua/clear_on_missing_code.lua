local commit_history = ""
local last_space_time = 0
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
		commit = commit:gsub("[a-z]", "")
		if #commit == 0 then
			env.engine.context:clear()
			return 1
		end
		commit_history = commit:sub(utf8.offset(commit, -1))
		env.engine:commit_text(commit)
		env.engine.context:clear()
		return 1
	end
	if #input == 0 then
		return 2
	end
	if key.keycode == string.byte(";") and #input % 4 == 1 and string.sub(input, -1, -1) == "z" then
		if #input == 0 then
			return 2
		end
		if #input == 1 then
			env.engine:commit_text(commit_history)
		else
			commit = commit:sub(1, utf8.offset(commit, -1) - 1)
			env.engine:commit_text(commit .. commit:sub(utf8.offset(commit, -1)))
		end
		env.engine.context:clear()
		return 1
	end
	if key.keycode == string.byte(",") or key.keycode == string.byte(".") then
		commit = commit:gsub("[a-z]", "")
		if #commit == 0 then
			env.engine.context:clear()
			return 1
		end
		commit_history = commit:sub(utf8.offset(commit, -1))
		env.engine:commit_text(commit)
		env.engine.context:clear()
		return 2
	end
	-- env.engine:commit_text(tostring(key.keycode))
	-- env.engine.context:clear()
	return 2
end
return clear_on_missing_code
