-- Shared punctuation suffixes and raw/function prefixes, before key_binder/speller.
local symbols = require("quick_symbols")
local schema_switch = require("schema_switch")
local symbol_menu = require("symbol_menu")
local menu_selection = require("menu_selection")
local settings_menu = require("settings_menu")
local M = {}

function M.init(env)
	env.command_prefix = env.engine.schema.config:get_string("input_keys/command_prefix") or ";"
	schema_switch.init(env)
	symbol_menu.init(env)
	menu_selection.init(env)
	env.commands = { s = schema_switch.open, o = settings_menu.open }
	env.keystrokes = nil
	env.commit_guard = nil
	local schema = env.engine.schema.schema_id
	if schema == "tiger" or schema == "tiger_full" then
		env.commit_guard = require("tiger.commit_guard")
		if env.engine.schema.config:get_bool("features/keystroke_stats") ~= false then
			env.keystrokes = require("tiger.keystroke_stats")
			env.keystrokes.init(env)
			env.commands.k = env.keystrokes.toggle
		end
	end
end

function M.fini(env)
	menu_selection.fini(env)
end

function M.func(key, env)
	if key:release() then return 2 end
	local context = env.engine.context
	local plain_key = not (key:ctrl() or key:alt() or key:super() or context:get_option("ascii_mode"))
	local enabled = plain_key and context.caret_pos == #context.input
	if enabled then
		if context.input == "" and key.keycode == 0x2f then
			context:push_input("/")
			return 1
		end
		local result = symbol_menu.handle_key(key, env)
		if result == 1 then return result end
		result = menu_selection.select(key, env)
		if result == 1 then return result end
		if context.input == env.command_prefix and key.keycode >= string.byte("a") and key.keycode <= string.byte("z") then
			local command = env.commands[string.char(key.keycode)]
			if command then return command(env) end
		end
		local code = key.keycode
		local letter = (code >= 0x61 and code <= 0x7a) or (code >= 0x41 and code <= 0x5a)
		-- 仅 / 后的数字和 /1 后的 0 属于编码，其余数字保留原生选词。
		local digit_prefix = (context.input == "/" and code >= 0x30 and code <= 0x39)
			or (context.input == "/1" and code == 0x30)
		-- 任意英文查询都留给菜单匹配；不要求它已经是某个路径的前缀。
		if ((context.input:match("^/[A-Za-z]*$") or context.input:match("^/q[A-Za-z0-9_/-]*$")) and letter) or digit_prefix then
			context:push_input(string.char(code))
			return 1
		end
	end
	-- Count all other press events, including keys later consumed by Tiger's submission component.
	if env.keystrokes then env.keystrokes.observe(env) end
	if plain_key and env.commit_guard then
		local result = env.commit_guard(key, env)
		if result == 1 then return result end
	end
	if not enabled then return 2 end
	local code, input = key.keycode, context.input
	local schema = env.engine.schema.schema_id
	local text
	if code == string.byte(env.command_prefix) then
		if input == "" then
			context:push_input(env.command_prefix) -- Keep the prefix pending instead of committing punctuation.
			return 1
		end
		text = symbols[input]
	elseif code >= string.byte("a") and code <= string.byte("z") then
		local char = string.char(code)
		if input == env.command_prefix then
			text = env.command_prefix .. char
		elseif schema == "rime_ice" and ((input == "j" and char == "j") or (input == "t" and char == "t")) then
			text = input .. char
		end
	end
	if not text then return 2 end
	env.engine:commit_text(text)
	context:clear()
	return 1
end

return M
