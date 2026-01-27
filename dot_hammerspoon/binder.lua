local M = {}
M.opts = {
	description = "hammerspoon auto generated",
	ipcpath = "/opt/homebrew/bin",
}
local json = require("JSON")
M.functions = {}
M.map = {}
local modsTable =
	{ "command", "option", "control", "shift", "fn", command = 1, option = 2, control = 4, shift = 8, fn = 16 }
local function mods2number(mods)
	local result = 0
	for _, mod in ipairs(mods) do
		result = result + modsTable[mod]
	end
	return result
end

local function cache_function(func)
	if M.functions[func] then
		return M.functions[func]
	else
		M.functions[func] = #M.functions + 1
		M.functions[#M.functions + 1] = func
		return M.functions[func]
	end
end
local function format_to(to)
	if not to then
		return
	end
	if type(to) == "string" then
		return { key_code = to }
	elseif type(to) == "function" then
		return {
			shell_command = M.opts.ipcpath .. "/bin/hs -c 'hs.karabiner.functions[" .. cache_function(to) .. "]()'",
		}
	elseif type(to) == "table" then
		return to
	end
end

function M._bind(mods, key, event, to)
	if not M.map[key] then
		M.map[key] = {}
	end
	local nmods = mods2number(mods)
	M.map[key][nmods] = M.map[key][nmods] or {}
	if M.map[key][nmods].to then
		error("already binded: " .. key .. "+" .. json:encode(mods))
	end
	M.map[key][nmods][event] = format_to(to)
end

-- function M.bind_keydown(mods, key, to)
-- 	if not M.map[key] then
-- 		M.map[key] = {}
-- 	end
-- 	local nmods = mods2number(mods)
-- 	M.map[key][nmods] = M.map[key][nmods] or {}
-- 	if M.map[key][nmods].to then
-- 		error("already bind keydown: " .. key .. "+" .. json:encode(mods))
-- 	end
-- 	M.map[key][nmods].to = format_to(to)
-- end
--
-- function M.bind_keyup(mods, key, to)
-- 	if not M.map[key] then
-- 		M.map[key] = {}
-- 	end
-- 	local nmods = mods2number(mods)
-- 	M.map[key][nmods] = M.map[key][nmods] or {}
-- 	if M.map[key][nmods].to then
-- 		error("already bind keyup: " .. key .. "+" .. json:encode(mods))
-- 	end
-- 	M.map[key][nmods].to_after_key_up = format_to(to)
-- end

function M.add_modifier(key, name)
	if modsTable[name] then
		error("already exists modifier: " .. name)
	end
	local numberOfmods = #modsTable
	modsTable[name] = 2 ^ numberOfmods
	numberOfmods = numberOfmods + 1
	modsTable[#modsTable + 1] = name
	M._bind({}, key, "to_after_key_up", { set_variable = { name = name, value = 0 } })
end

local function number2mods(number)
	local man = {}
	for i, mod in ipairs(modsTable) do
		if i >= 6 then
			break
		end
		if number % 2 == 1 then
			man[#man + 1] = mod
		end
		number = number / 2
	end
	return { mandatory = man }
end

local function number2conditions(number)
	local conditions = {}
	for i, mod in ipairs(modsTable) do
		if i >= 6 then
			break
		end
		if number % 2 == 1 then
			conditions[#conditions + 1] = mod
		end
		number = number / 2
	end
	return { conditionsdatory = conditions }
end

local function generate_mani()
	local manipulators = {}
	for key, maps in pairs(M.map) do
		for mods, map in pairs(maps) do
			manipulators[#manipulators + 1] = { from = { key_code = key, midifiers = number2mods(mods) } }
			for event, to in pairs(map) do
				manipulators[#manipulators][event] = to
			end
		end
	end
	return manipulators
end

function M.write(opts)
	M.opts = opts or M.opts
	local file = io.open("/Users/dirichy/.config/karabiner/karabiner.json", "r")
	local keymap
	if file then
		keymap = file:read("*a")
		file:close()
	else
		error("base.json not found!")
	end
	keymap = json:decode(keymap)
	local rules = keymap.profiles[1].complex_modifications.rules
	for index, rule in ipairs(rules) do
		if rule.description == M.opts.description then
			table.remove(rules, index)
		end
	end
	if not hs.ipc.cliStatus(M.opts.ipcpath) then
		hs.ipc.cliInstall(M.opts.ipcpath)
	end
	local manipulators = generate_mani()
end
return M
