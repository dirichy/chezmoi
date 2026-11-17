-- 输入 ;s 时显示可用方案；数字选择由 quick_input 调用 schema_switch 处理。

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
