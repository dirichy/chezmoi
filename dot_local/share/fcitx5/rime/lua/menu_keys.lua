-- 将菜单按键映射到候选的绝对索引；修饰键由 quick_input 统一检查。
return function(key, schema, selected)
	local code = key.keycode
	if code == 0x20 or code == 0xff0d then return selected end
	local index
	local keys = schema.select_keys
	if keys and keys ~= "" and code >= 0x20 and code < 0x7f then
		local position = keys:find(string.char(code), 1, true)
		if position then index = position - 1 end
	elseif code >= 0x30 and code <= 0x39 then
		index = (code - 0x30 + 9) % 10
	elseif code >= 0xffb0 and code <= 0xffb9 then
		index = (code - 0xffb0 + 9) % 10
	end
	if index == nil then return nil end
	local size = schema.page_size or 8
	return math.floor(selected / size) * size + index
end
