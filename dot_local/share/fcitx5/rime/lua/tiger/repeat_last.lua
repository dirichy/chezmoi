-- z 的第二候选：优先重复连打中的前一个字，否则重复上次上屏的末字。
local function last_character(text)
	if not text or text == "" then return nil end
	return text:sub(utf8.offset(text, -1))
end

local function repeat_text(context, start)
	if start == 0 then
		local previous = context.commit_history:back()
		return last_character(previous and previous.text)
	end
	for _, segment in ipairs(context.composition:toSegmentation():get_segments()) do
		if segment._end == start then
			local candidate = segment:get_selected_candidate()
			if candidate and candidate.type ~= "raw" then return last_character(candidate.text) end
			return nil
		end
	end
end

return function(input, env)
	local context = env.engine.context
	local code = context.input
	local first = true
	for candidate in input:iter() do
		yield(candidate)
		if first and #code % 4 == 1 and code:match("^[a-z]*z$")
			and candidate.start == #code - 1 and candidate._end == #code then
			local text = repeat_text(context, candidate.start)
			if text then
				yield(Candidate("repeat_last", candidate.start, candidate._end, text, "重复末字"))
			end
		end
		first = false
	end
end
