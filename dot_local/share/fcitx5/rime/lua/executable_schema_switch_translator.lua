-- 输入 /schema 时显示可用方案；数字选择由 schema_switch processor 处理。

local schemas = {
	{ name = "虎码", key = "1" },
	{ name = "小鹤双拼", key = "2" },
	{ name = "全拼", key = "3" },
}

local function schema_switch_translator(input, segment)
	if input ~= "/schema" then
		return
	end

	for _, schema in ipairs(schemas) do
		yield(Candidate("schema_switch", segment.start, segment._end, schema.name, schema.key))
	end
end

return schema_switch_translator
