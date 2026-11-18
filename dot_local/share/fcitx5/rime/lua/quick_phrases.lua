-- 将本机明文 Lua 短语表转换为 / 符号菜单的数据定义。
local M = {}

function M.definitions()
	local definitions, seen = {}, {}
	if not rime_api or not rime_api.get_user_data_dir then return definitions end
	-- 空环境只供加载字面数据；不用 require 缓存，初始化时读取新表。
	local chunk = loadfile(rime_api.get_user_data_dir() .. "/lua/quick_phrase_data.lua", "t", {})
	if not chunk then return definitions end
	local ok, phrases = pcall(chunk)
	if not ok or type(phrases) ~= "table" then return definitions end
	for _, phrase in ipairs(phrases) do
		if type(phrase) == "table" and type(phrase.key) == "string" and phrase.key:match("^[A-Za-z0-9_/-]+$")
			and type(phrase.text) == "string" and phrase.text ~= "" and not seen[phrase.key] then
			-- 原始条目名同时用于直接路径、显示与 fuzzy；补充路径分词及 camelCase 分词。
			local words = phrase.key:gsub("(%l)(%u)", "%1 %2"):gsub("[/_-]", " ")
			definitions[#definitions + 1] = { phrase.key, phrase.key,
				{ phrases = { { text = phrase.text, label = phrase.key } } }, phrase.key .. " " .. words }
			seen[phrase.key] = true
		end
	end
	return definitions
end

return M
