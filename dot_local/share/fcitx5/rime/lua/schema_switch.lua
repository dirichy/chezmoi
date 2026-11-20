-- 输入 ;s 后，通过选择自定义候选项切换输入方案。
-- 只描述动作，选择事件和实际切换由 menu_selection 统一处理。
local function action(candidate, env)
	if candidate.type ~= "schema_switch" then return nil end
	local number = tonumber(candidate.comment)
	local id = number and env.schemas[number - 1]
	if id then return { schema = id } end
end

local function init(env)
	-- Context survives schema changes. This non-transient property marks the session,
	-- so defaults run only once, including when switching via the native F4 menu.
	local context = env.engine.context
	if context:get_property("session_options_initialized") == "" then
		context:set_option("emoji", env.engine.schema.config:get_bool("session_defaults/emoji") == true)
		local practice = env.engine.schema.config:get_bool("session_defaults/practice") ~= false
		context:set_option("simp_hint", practice)
		context:set_option("simp_record", practice)
		context:set_property("session_options_initialized", "1")
	end
	env.schemas = {}
	for index, schema in ipairs(require("schema_catalog")) do
		env.schemas[index - 1] = schema.id
	end
end

local function open(env)
	env.engine.context:push_input("s")
	return 1
end

return { init = init, open = open, action = action }
