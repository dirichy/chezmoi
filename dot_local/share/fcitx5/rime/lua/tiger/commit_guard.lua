-- echo_translator 的字面候选用于稳定候选框；空格和标点不提交其中的空码。
-- 正常字词继续走原生提交，只在已选候选中确有 raw 字面候选时接管。
return function(key, env)
	local code = key.keycode
	local space = code == string.byte(" ")
	if not space and code ~= string.byte(",") and code ~= string.byte(".") then return 2 end
	local context = env.engine.context
	local input = context.input
	if not input:match("^[a-z]+$") then return 2 end

	local translated, text, has_literal = {}, {}, false
	for _, segment in ipairs(context.composition:toSegmentation():get_segments()) do
		local candidate = segment:get_selected_candidate()
		if candidate and candidate.type == "raw" then
			has_literal = true
		elseif candidate then
			translated[#translated + 1] = { text = candidate.text, code = input:sub(segment.start + 1, segment._end) }
			text[#text + 1] = candidate.text
		end
	end
	if not has_literal then return 2 end

	local commit = table.concat(text)
	if commit ~= "" then
		local tracker = require("tiger.simp_tracker")
		for _, entry in ipairs(translated) do tracker.observe(env, entry.text, entry.code) end
		env.engine:commit_text(commit)
	end
	context:clear()
	-- 空格不额外输出；有正常字时继续让原生标点组件输出逗号、句号。
	if space or commit == "" then return 1 end
	return 2
end
