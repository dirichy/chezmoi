-- 键盘与前端点选统一通过 Rime 的候选选择通知执行菜单动作。
local menu_index = require("menu_keys")
local symbol_menu = require("symbol_menu")
local schema_switch = require("schema_switch")
local settings_menu = require("settings_menu")
local command_menu = require("command_menu")
local M = {}

function M.init(env)
	M.fini(env)
	local context = env.engine.context
	-- 有 group 的回调先于引擎默认回调运行。仅菜单动作暂缓自动提交，
	-- 让引擎完成本次选择后，再替换输入或切方案，避免菜单名称上屏。
	env.menu_before_select = context.select_notifier:connect(function(ctx)
		local candidate = ctx:get_selected_candidate()
		if not candidate then return end
		local original = candidate:get_genuine()
		local action = symbol_menu.action(original, env) or schema_switch.action(original, env)
			or settings_menu.action(original, env)
			or command_menu.action(original, env)
		if not action then return end
		env.menu_pending = { action = action, auto_commit = ctx:get_option("_auto_commit") }
		ctx:set_option("_auto_commit", false)
	end, 0)
	env.menu_after_select = context.select_notifier:connect(function(ctx)
		local pending = env.menu_pending
		if not pending then return end
		env.menu_pending = nil
		ctx:clear()
		ctx:set_option("_auto_commit", pending.auto_commit)
		local action = pending.action
		if action.text then
			env.engine:commit_text(action.text)
		elseif action.input then
			ctx.input = action.input
		elseif action.schema then
			env.engine:apply_schema(Schema(action.schema))
		elseif action.option then
			ctx:set_option(action.option, action.value)
		elseif action.command and env.commands[action.command] then
			env.commands[action.command](env)
		end
	end)
end

function M.fini(env)
	if env.menu_before_select then env.menu_before_select:disconnect() end
	if env.menu_after_select then env.menu_after_select:disconnect() end
end

-- 只把按键转换为选择索引；菜单动作全部交给上面的通知处理。
function M.select(key, env)
	local context = env.engine.context
	if key.keycode == 0xff0d then return 2 end -- 回车保留 editor 的原始编码上屏。
	local input = context.input
	if input ~= env.command_prefix and input ~= env.command_prefix .. "s" and input ~= env.command_prefix .. "o"
		and input:sub(1, 1) ~= "/" then return 2 end
	-- /0 到 /10 仍是数字符号查询，不是根菜单选词。
	if context.input == "/" and key.keycode >= 0x30 and key.keycode <= 0x39 then return 2 end
	local segment = context.composition:back()
	if not segment then return 2 end
	local index = menu_index(key, env.engine.schema, segment.selected_index)
	if index == nil or not segment:get_candidate_at(index) then return 2 end
	return context:select(index) and 1 or 2
end

return M
