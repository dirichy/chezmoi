local M = {}
M.functions = {}

M.opts = {
	description = "hammerspoon auto generated",
	ipcpath = "/usr/local/",
}

local json = require("cjson")
local keymap
local manipulators = {}
function M.setup(opts)
	M.opts = opts or M.opts
	local file = io.open("/Users/dirichy/.config/karabiner/base.json", "r")
	if file then
		keymap = file:read("*a")
		file:close()
	else
		error("base.json not found!")
	end
	keymap = json.decode(keymap)
	local rules = keymap.profiles[1].complex_modifications.rules
	for index, rule in ipairs(rules) do
		if rule.description == M.opts.description then
			table.remove(rules, index)
		end
	end
	if not hs.ipc.cliStatus(M.opts.ipcpath) then
		hs.ipc.cliInstall(M.opts.ipcpath)
	end
end

function M.write()
	if #manipulators == 0 then
		return
	end
	keymap.profiles[1].complex_modifications.rules[#keymap.profiles[1].complex_modifications.rules + 1] =
		{ description = M.opts.description, manipulators = manipulators }
	local file = io.open("/Users/dirichy/.config/karabiner/karabiner.json", "w")
	file:write(json.encode(keymap))
	file:close()
end

--- map a key
---@param mods string[]|table|nil
---@param key string
---@param pressedfn function?
---@param releasedfn function?
function M.press(mods, key, pressedfn, releasedfn)
	local from = { key_code = key }
	if mods and not mods.mandatory then
		if #mods > 0 then
			mods = { mandatory = mods }
		else
			mods = nil
		end
	end
	from.modifiers = mods
	local map = { from = from, type = "basic" }
	if type(pressedfn) == "function" then
		M.functions[pressedfn] = #M.functions + 1
		M.functions[#M.functions + 1] = pressedfn
		map.to = {
			shell_command = M.opts.ipcpath .. "/bin/hs -c 'hs.karabiner.functions[" .. M.functions[pressedfn] .. "]()'",
		}
	end
	if type(releasedfn) == "function" then
		M.functions[releasedfn] = #M.functions + 1
		M.functions[#M.functions + 1] = releasedfn
		map.to_after_key_up = {
			shell_command = M.opts.ipcpath
				.. "/bin/hs -c 'hs.karabiner.functions["
				.. M.functions[releasedfn]
				.. "]()'",
		}
	end
	manipulators[#manipulators + 1] = map
end

function M._bind(from, to, conditions)
	manipulators[#manipulators + 1] = { from = from, to = to, conditions = conditions }
end

function M.add_modifier(key, name) end

hs.karabiner = M
