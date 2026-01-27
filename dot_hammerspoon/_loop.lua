local keyboardShortcuts = {
	[{ "left_arrow", "up_arrow" }] = { 2, 2 },
	[{ "up_arrow", "right_arrow" }] = { 2, 4 },
	[{ "right_arrow", "down_arrow" }] = { 2, 6 },
	[{ "down_arrow", "left_arrow" }] = { 2, 8 },
	[{ "left_arrow", "right_arrow" }] = { 1, 3 },
	[{ "up_arrow", "down_arrow" }] = { 1, 4 },
	h = { 2, 1 },
	k = { 2, 3 },
	l = { 2, 5 },
	j = { 2, 7 },
	c = { 1, 3 },
	f = { 1, 2 },
	spacebar = { 1, 1 },
}
local cyclyShortcuts = {
	left_arrow = { { 2, 1 }, { 3, 1 }, { 3, 2 } },
	up_arrow = { { 2, 3 }, { 3, 3 }, { 3, 4 } },
	right_arrow = { { 2, 5 }, { 3, 5 }, { 3, 6 } },
	down_arrow = { { 2, 7 }, { 3, 7 }, { 3, 8 } },
}
local abortKeys = { q = true, tab = false }
local JSON = require("JSON")
local loop = {
	title = "loop.lua",
	rules = {
		{
			description = "Keybind for hammerspoon loop.lua, see github.com/dirichy/dotfiles",
			manipulators = {},
		},
	},
}

loop.rules[1].manipulators[#loop.rules[1].manipulators + 1] = {
	from = { key_code = "left_option" },
	to = {
		{ shell_command = '/opt/homebrew/bin/hs -c "hs.loop.start()"' },
		{ set_variable = { name = "left_option_down", value = 1 } },
		{ key_code = "left_option" },
	},
	to_after_key_up = {
		{ shell_command = '/opt/homebrew/bin/hs -c "hs.loop.stop()"' },
		{ set_variable = { name = "left_option_down", value = 0 } },
	},
	type = "basic",
}

for key, value in pairs(keyboardShortcuts) do
	if type(key) == "string" then
		local mani = {
			from = { key_code = key, modifiers = { mandatory = "left_option" } },
			to = {
				shell_command = "/opt/homebrew/bin/hs -c 'hs.loop.forceChoose("
					.. tostring(value[1])
					.. ","
					.. tostring(value[2])
					.. ")'",
			},
			type = "basic",
		}
		table.insert(loop.rules[1].manipulators, mani)
	else
		local mani = {
			from = { simultaneous = {}, modifiers = { mandatory = "left_option" } },
			to = {
				shell_command = "/opt/homebrew/bin/hs -c 'hs.loop.forceChoose("
					.. tostring(value[1])
					.. ","
					.. tostring(value[2])
					.. ")'",
			},
			type = "basic",
		}
		for _, k in ipairs(key) do
			mani.from.simultaneous[#mani.from.simultaneous + 1] = { key_code = k }
		end
		table.insert(loop.rules[1].manipulators, 1, mani)
	end
end
for key, value in pairs(abortKeys) do
	local mani = {
		from = { key_code = key, modifiers = { optional = "left_option" } },
		to = {
			shell_command = "/opt/homebrew/bin/hs -c 'hs.loop.stop(true)'",
		},
		conditions = { { type = "variable_if", name = "left_option_down", value = 1 } },
		type = "basic",
	}
	if not value then
		mani.to = { mani.to }
		mani.to[2] = { key_code = key }
	end
	table.insert(loop.rules[1].manipulators, mani)
end
for key, value in pairs(cyclyShortcuts) do
	local mani = {
		from = { key_code = key, modifiers = { mandatory = "left_option" } },
		to = {
			shell_command = "/opt/homebrew/bin/hs -c 'hs.loop.cycly(" .. '"' .. key .. '"' .. ")'",
		},
		type = "basic",
	}
	table.insert(loop.rules[1].manipulators, mani)
end
local file = io.open(os.getenv("HOME") .. "/.config/karabiner/assets/complex_modifications/loop.json", "w")
file:write(JSON:encode(loop))
file:close()
-- print(JSON:encode(loop))
