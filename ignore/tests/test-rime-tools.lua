-- Run with an isolated Lua VM; never loads desktop integrations or real input-method state.
local repo = assert(arg[1])
local root = repo .. "/dot_local/share/fcitx5/rime/lua/"
package.path = root .. "?.lua;" .. package.path

function Candidate(kind, start, finish, text, comment)
	return { type = kind, start = start, _end = finish, text = tostring(text), comment = comment,
		get_genuine = function(self) return self end }
end
yield = coroutine.yield

local function notifier()
	local connections = {}
	return {
		connect = function(_, callback, group)
			local connection = { callback = callback, group = group or math.huge, active = true }
			connection.disconnect = function() connection.active = false end
			connections[#connections + 1] = connection
			return connection
		end,
		emit = function(_, context)
			table.sort(connections, function(a, b) return a.group < b.group end)
			for _, connection in ipairs(connections) do
				if connection.active then connection.callback(context) end
			end
		end,
		count = function()
			local count = 0
			for _, connection in ipairs(connections) do
				if connection.active then count = count + 1 end
			end
			return count
		end,
	}
end

local function environment(settings)
	return { engine = { schema = { config = {
		get_string = function(_, key) return settings[key] end,
		get_bool = function(_, key) return settings[key] end,
		get_map = function() return nil end,
	} } } }
end

local function candidates(component, input, env, tag)
	local segment = { start = 0, _end = #input, has_tag = function(_, name) return name == tag end }
	local func = type(component) == "table" and component.func or component
	local thread = coroutine.create(function() func(input, segment, env) end)
	local output = {}
	while coroutine.status(thread) ~= "dead" do
		local ok, value = coroutine.resume(thread)
		assert(ok, value)
		if value then output[#output + 1] = value end
	end
	return output
end

local date = dofile(root .. "executable_date_translator.lua")
local tiger = environment({})
local ice = environment({})
date.init(tiger)
date.init(ice)
assert(#candidates(date, "date", tiger) == 0)
assert(#candidates(date, "/date", tiger) == 0)
assert(#candidates(date, "/d", tiger) == 3)
assert(candidates(date, "/d", ice)[1].text == candidates(date, "/d", tiger)[1].text)
assert(#candidates(date, "/t", ice) == 3)
assert(candidates(date, "/dw", tiger)[1].text:match("^周"))
assert(candidates(date, "/dt", tiger)[2].text:match("[+-]%d%d:%d%d$"))
assert(candidates(date, "/dc", tiger)[1].text:match("年.+月.+日$"))
assert(#candidates(date, "/de", tiger) == 2)
assert(#candidates(date, "/dm", tiger) == 2)
assert(candidates(date, "/ts", tiger)[1].text:match("^%d+$"))
assert(#candidates(date, "/dqq", tiger) == 0 and #candidates(date, "/ddt", tiger) == 0)
assert(candidates(date, "/version", tiger)[1].text == _VERSION)
assert(#candidates(date, "ordinary", ice) == 0)

local number = dofile(root .. "number_translator.lua")
local number_tiger = environment({ ["recognizer/patterns/number"] = "^S[0-9]+" })
local number_ice = environment({ ["recognizer/patterns/number"] = "^R[0-9]+" })
local a = candidates(number, "S123.45", number_tiger)
local b = candidates(number, "R123.45", number_ice)
assert(#a == 4 and #b == 4)
for index, candidate in ipairs(a) do assert(candidate.text == b[index].text) end
assert(#candidates(number, "S", number_tiger) == 0)
assert(#candidates(number, "S1bad", number_tiger) == 0)
assert(#candidates(number, "R123", number_tiger) == 0)

local calc = dofile(root .. "calc_translator.lua")
local calc_tiger = environment({ ["calculator/prefix"] = "=" })
local calc_ice = environment({})
calc.init(calc_tiger)
calc.init(calc_ice)
assert(candidates(calc, "=1+2*3", calc_tiger, "calculator")[1].text == "7")
assert(candidates(calc, "cC1+2*3", calc_ice, "calculator")[1].text == "7")
assert(candidates(calc, "=1+", calc_tiger, "calculator")[1].comment == "解析失败")
assert(#candidates(calc, "=1+2", calc_tiger, "abc") == 0)

local catalog = require("schema_catalog")
local quick_input = require("quick_input")
local function session(emoji_default)
	local env = environment({ ["session_defaults/emoji"] = emoji_default })
	local options, properties = {}, {}
	env.engine.context = {
		select_notifier = notifier(),
		get_property = function(_, key) return properties[key] or "" end,
		set_property = function(_, key, value) properties[key] = value end,
		set_option = function(_, key, value) options[key] = value end,
	}
	return env, options
end
local switch_env, options = session(false)
quick_input.init(switch_env)
assert(switch_env.commands.s and not switch_env.commands.k and not switch_env.keystrokes)
assert(options.emoji == false and options.simp_hint and options.simp_record)
-- Every schema uses this initializer; switching keeps even explicitly disabled options.
options.emoji, options.simp_hint, options.simp_record = true, false, false
options.ascii_mode, options.traditionalization, options.chaifen = true, true, true
switch_env.engine.schema.config.get_bool = function() return true end
quick_input.init(switch_env)
assert(options.emoji and not options.simp_hint and not options.simp_record)
assert(options.ascii_mode and options.traditionalization and options.chaifen)
assert(switch_env.engine.context.select_notifier:count() == 2)
local new_session, new_options = session(true)
quick_input.init(new_session)
assert(new_options.emoji and new_options.simp_hint and new_options.simp_record)
assert(new_options.ascii_mode == nil) -- Does not override frontend language mode.
local menu = candidates(dofile(root .. "executable_schema_switch_translator.lua"), ";s", {})
assert(#catalog == #menu)
for index, schema in ipairs(catalog) do
	assert(menu[index].text == schema.name and menu[index].comment == schema.key)
	assert(switch_env.schemas[index - 1] == schema.id)
end
print("Rime tools: shared date commands, independent schemes, numeric prefixes, calculator and schema catalog passed")

-- Common letter; symbols and ;letter prefixes, without depending on key release.
rime_api = { get_time_ms = function() return 1000 end }
local function shortcut(input, code, flags, caret)
	flags = flags or {}
	local output, cleared, pushed
	local env = { engine = {
		schema = { schema_id = flags.schema or "rime_ice", config = { get_bool = function() return false end, get_map = function() return nil end } },
		context = {
			select_notifier = notifier(),
			input = input, caret_pos = caret or #input,
			composition = { back = function() return nil end },
			get_option = function() return flags.ascii or false end,
			get_property = function() return "" end,
			set_property = function() end,
			set_option = function() end,
			clear = function() cleared = true end,
			push_input = function(_, text) pushed = text end,
		},
		commit_text = function(_, text) output = text end,
	} }
	local key = { keycode = code }
	for _, name in ipairs({ "release", "ctrl", "alt", "super" }) do
		key[name] = function() return flags[name] or false end
	end
	quick_input.init(env)
	return quick_input.func(key, env), output, cleared, pushed
end
local symbols = require("quick_symbols")
for _, schema in ipairs({ "rime_ice", "rime_ice_full", "tiger", "tiger_full" }) do
	local tiger = schema:match("^tiger")
	for code, text in pairs(symbols) do
		local status, output = shortcut(code, string.byte(";"), { schema = schema })
		if tiger and code == "z" then
			assert(status == 2 and output == nil) -- Leave repeat-candidate selection to native Rime.
		else
			assert(status == 1 and output == text)
		end
	end
	local status, output, _, pushed = shortcut("", string.byte(";"), { schema = schema })
	assert(status == 1 and output == nil and pushed == ";")
	for codepoint = string.byte("a"), string.byte("z") do
		local result, text, cleared, pushed = shortcut(";", codepoint, { schema = schema })
		if codepoint == string.byte("s") then
			assert(result == 1 and text == nil and pushed == string.char(codepoint))
		elseif tiger and codepoint == string.byte("k") then
			assert(result == 1 and text == nil and cleared) -- Tiger's ;k dispatched by quick_input.
		else
			assert(result == 1 and text == ";" .. string.char(codepoint))
		end
	end
	for _, text in ipairs({ "jj", "tt" }) do
		local result, output = shortcut(text:sub(1, 1), text:byte(2), { schema = schema })
		assert((result == 1) == (schema == "rime_ice"))
		if schema == "rime_ice" then assert(output == text) end
	end
	assert(shortcut("/d", string.byte("e"), { schema = schema }) == 1)
	assert(shortcut("/t", string.byte("s"), { schema = schema }) == 1)
	assert(shortcut("/d", string.byte("t"), { schema = schema }) == 1)
	assert(shortcut("ab", string.byte(";"), { schema = schema }) == 2) -- Keep second-candidate selection.
end
for _, flag in ipairs({ "release", "ctrl", "alt", "super", "ascii" }) do
	assert(shortcut("j", string.byte("j"), { [flag] = true }) == 2)
	assert(shortcut("t", string.byte(";"), { [flag] = true }) == 2)
end
for _, code in ipairs({ 0xff51, 0xff08, 0xffe1 }) do assert(shortcut("j", code) == 2) end
assert(shortcut("j", string.byte("j"), {}, 0) == 2)
assert(shortcut("a", string.byte("j")) == 2)
assert(shortcut("", string.byte("j")) == 2)
print("Rime quick input: shared symbols, raw prefixes, Tiger exceptions and Xiaohe-only shortcuts passed")

Schema = function(id) return id end
local selected
switch_env.engine.apply_schema = function(_, id) selected = id end
switch_env.engine.context.get_option = function() return false end
switch_env.engine.context.clear = function() switch_env.engine.context.input = "" end
local current_candidate
switch_env.engine.context.get_selected_candidate = function() return current_candidate end
switch_env.engine.context.composition = { back = function() return {
	selected_index = 0, get_candidate_at = function(_, index) return menu[index + 1] end,
} end }
switch_env.engine.context.select = function(ctx, index)
	current_candidate = menu[index + 1]
	assert(selected == nil) -- Selecting is delegated to Rime before the action runs.
	ctx.select_notifier:emit(ctx)
	return true
end
local function selection_key(code, modifier)
	local key = { keycode = code }
	for _, flag in ipairs({ "release", "ctrl", "alt", "super" }) do
		key[flag] = function() return flag == modifier end
	end
	return key
end
for index, schema in ipairs(catalog) do
	selected = nil
	switch_env.engine.context.input, switch_env.engine.context.caret_pos = ";s", 2
	assert(quick_input.func(selection_key(string.byte(tostring(index))), switch_env) == 1)
	assert(selected == schema.id and switch_env.engine.context.input == "")
end
for _, flag in ipairs({ "release", "ctrl", "alt", "super" }) do
	selected = nil
	switch_env.engine.context.input, switch_env.engine.context.caret_pos = ";s", 2
	assert(quick_input.func(selection_key(string.byte("1"), flag), switch_env) == 2 and selected == nil)
end
quick_input.fini(switch_env)
assert(switch_env.engine.context.select_notifier:count() == 0)
print("Rime quick commands: selection delegation, callback cleanup and modifier guards passed")

-- Hierarchical paths keep their parent prefix, including partial child keys.
local symbol_menu = require("symbol_menu")
local greek = { code = "/lg", name = "希腊字母", values = { "α", "β" }, parent = "/l", keywords = "greek" }
local japanese = { code = "/lj", name = "日语", children = {}, parent = "/l" }
local two = { code = "/lvth", name = "th 变体", values = { "þ" } }
local three = { code = "/lvtz", name = "tz 变体", values = { "ꜩ" } }
local menu_env = { symbol_search = { greek, japanese }, symbol_nodes = {
 ["/l"] = { children = { greek, japanese } }, ["/lg"] = greek, ["/lvtz"] = three,
 ["/lv"] = { children = { two, three } },
} }
assert(candidates(symbol_menu, "/l", menu_env)[1].text == "希腊字母")
assert(candidates(symbol_menu, "/lg", menu_env)[1].text == "α")
assert(candidates(symbol_menu, "/lvt", menu_env)[1].text == "th 变体")
assert(candidates(symbol_menu, "/grk", menu_env)[1].text == "希腊字母")
print("Rime symbol menu: hierarchical paths, incremental hints and English fuzzy matching passed")
