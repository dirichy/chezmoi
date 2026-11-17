-- 输入 ;s 后，通过选择自定义候选项切换输入方案。
-- 结构与选择键处理方式来自 librime-lua 官方 sample/lua/switch.lua。

local menu_index = require("menu_keys")

local kAccepted = 1
local kNoop = 2

local function select(key, env)
	local context = env.engine.context
	if context.input ~= ";s" then
		return kNoop
	end

	local index = menu_index(key, env.engine.schema, 0)
	local schema_id = env.schemas[index]
	if schema_id == nil then
		return kNoop
	end

	context:clear()
	env.engine:apply_schema(Schema(schema_id))
	return kAccepted
end

local function init(env)
	-- Context survives schema changes. This non-transient property marks the session,
	-- so defaults run only once, including when switching via the native F4 menu.
	local context = env.engine.context
	if context:get_property("session_options_initialized") == "" then
		context:set_option("emoji", env.engine.schema.config:get_bool("session_defaults/emoji") == true)
		context:set_option("simp_hint", true)
		context:set_option("simp_record", true)
		context:set_property("session_options_initialized", "1")
	end
	env.schemas = {}
	for index, schema in ipairs(require("schema_catalog")) do
		env.schemas[index - 1] = schema.id
	end
end

local function open(env)
	env.engine.context:push_input("s")
	return kAccepted
end

return { init = init, open = open, select = select }
