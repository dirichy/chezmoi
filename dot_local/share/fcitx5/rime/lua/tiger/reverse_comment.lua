-- 拼音反查优先显示整词虎码；码表没有词条时，逐字列出实际编码。
local M = {}

function M.init(env)
	env.dictionary = env.engine.schema.config:get_string("translator/dictionary")
	env.reverse = nil
end

local function codes(text, reverse)
	local whole = reverse:lookup(text)
	if whole and whole ~= "" then return whole end
	local parts, found = {}, false
	for _, point in utf8.codes(text) do
		local code = reverse:lookup(utf8.char(point))
		if code and code ~= "" then
			-- 同字多码用 / 分开，字与字之间用空格分开。
			parts[#parts + 1] = code:gsub("%s+", "/")
			found = true
		else
			parts[#parts + 1] = "?" -- 当前方案码表未收录这个字。
		end
	end
	return found and table.concat(parts, " ") or ""
end

function M.func(input, env)
	local segment = env.engine.context.composition:back()
	if not segment or not segment:has_tag("reverse_lookup") or not env.dictionary then
		for candidate in input:iter() do yield(candidate) end
		return
	end
	-- 仅首次使用反查时打开当前方案的原生索引；普通输入不查码。
	if not env.reverse then env.reverse = ReverseLookup(env.dictionary) end
	for candidate in input:iter() do
		local output = candidate
		local genuine = candidate:get_genuine()
		if genuine.type == "reverse_lookup" then
			local comment = codes(genuine.text, env.reverse)
			if comment ~= "" then
				output = ShadowCandidate(candidate, candidate.type, candidate.text, comment, false)
			end
		end
		yield(output)
	end
end

return M
