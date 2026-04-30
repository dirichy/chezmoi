local commit_history = ""
local clear_on_missing_code = function(key, env)
	local input = env.engine.context.input
	local commit = env.engine.context:get_commit_text()
	if key.keycode == string.byte(";") and #input % 4 == 1 and string.sub(input, -1, -1) == "z" then
		if #input == 1 then
			env.engine:commit_text(commit_history)
		else
			commit = commit:sub(1, utf8.offset(commit, -1) - 1)
			env.engine:commit_text(commit .. commit:sub(utf8.offset(commit, -1)))
		end
		env.engine.context:clear()
		return 1
	end
	if key.keycode == string.byte(" ") then
		-- env.engine:commit_text(commit .. "::")
		commit = commit:gsub("[a-z]*$", "")
		commit_history = commit:sub(utf8.offset(commit, -1))
		env.engine:commit_text(string.gsub(commit, "%a*$", ""))
		env.engine.context:clear()
		return 1
	end
	-- env.engine:commit_text(tostring(key.keycode))
	-- env.engine.context:clear()
	return 2
end
return clear_on_missing_code
