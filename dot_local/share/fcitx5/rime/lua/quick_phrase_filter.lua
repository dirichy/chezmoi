-- 私人短语必须按原文上屏，避免简繁、Emoji 等滤镜改写姓名或地址。
return function(input)
	for candidate in input:iter() do
		local original = candidate:get_genuine()
		yield(original.type == "quick_phrase" and original or candidate)
	end
end
