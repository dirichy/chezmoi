-- 输入 ;s 时显示可用方案；点选与按键选择由 menu_selection 统一处理。

local schemas = require("schema_catalog")

local function schema_switch_translator(input, segment)
	if input ~= ";s" then
		return
	end

	for _, schema in ipairs(schemas) do
		yield(Candidate("schema_switch", segment.start, segment._end, schema.name, schema.key))
	end
end

return schema_switch_translator
