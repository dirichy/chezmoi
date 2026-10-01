-- 输入 /schema 后，通过选择自定义候选项切换输入方案。
-- 结构与选择键处理方式来自 librime-lua 官方 sample/lua/switch.lua。

local function select_index(key, env)
	local ch = key.keycode
	local index = -1
	local select_keys = env.engine.schema.select_keys

	if select_keys ~= nil and select_keys ~= "" and not key:ctrl() and ch >= 0x20 and ch < 0x7f then
		local pos = string.find(select_keys, string.char(ch), 1, true)
		if pos ~= nil then
			index = pos - 1
		end
	elseif ch >= 0x30 and ch <= 0x39 then
		index = (ch - 0x30 + 9) % 10
	elseif ch >= 0xffb0 and ch <= 0xffb9 then
		index = (ch - 0xffb0 + 9) % 10
	elseif ch == 0x20 then
		index = 0
	end

	return index
end

local kAccepted = 1
local kNoop = 2

local function selector(key, env)
	if key:release() or key:alt() then
		return kNoop
	end

	local context = env.engine.context
	if context.input ~= "/schema" then
		return kNoop
	end

	local index = select_index(key, env)
	local schema_id = env.schemas[index]
	if schema_id == nil then
		return kNoop
	end

	context:clear()
	env.engine:apply_schema(Schema(schema_id))
	return kAccepted
end

local function init(env)
	env.schemas = {
		[0] = "tiger",
		[1] = "rime_ice",
		[2] = "rime_ice_full",
	}
end

return { init = init, func = selector }
