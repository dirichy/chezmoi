local shortcuts = {
	-- a = "Karabiner-Elements.app",
	b = "Google Chrome.app",
	d = "Eudic.app",
	-- e = "Karabiner-EventViewer.app",
	-- g = "Gnucash.app",
	t = "kitty.app",
	-- m = "MenubarX.app",
	-- n = "noteful.app",
	q = "QQ.app",
	s = "sioyek.app",
	-- t = "Telegram.app",
	w = "WeChat.app",
	-- v = "VLC.app",
	spacebar = "Alfred 5.app",
}
local JSON = require("cjson")
local applaucher = {
	title = "applaucher",
	rules = {
		{
			description = "Use command + key to open app",
			manipulators = {},
		},
	},
}
for key, value in pairs(shortcuts) do
	local mani = {
		from = { key_code = key },
		to = { shell_command = 'open -a "' .. value .. '"' },
		conditions = { { type = "variable_if", name = "multitouch_extension_palm_count_total", value = 1 } },
		type = "basic",
	}
	local mani2 = {
		from = { key_code = key },
		to = { shell_command = 'open -a "' .. value .. '"' },
		conditions = { { type = "variable_if", name = "multitouch_extension_finger_count_total", value = 2 } },
		type = "basic",
	}
	local mani3 = {
		from = {
			key_code = key,
			modifiers = {
				mandatory = { "left_command" },
			},
		},
		to = { shell_command = 'open -a "' .. value .. '"' },
		type = "basic",
	}
	-- applaucher.rules[1].manipulators[#applaucher.rules[1].manipulators + 1] = mani
	applaucher.rules[1].manipulators[#applaucher.rules[1].manipulators + 1] = mani3
end
applaucher.rules[1].manipulators[#applaucher.rules[1].manipulators + 1] = {
	from = {
		key_code = "q",
		modifiers = {
			mandatory = { "option" },
		},
	},
	to = {
		key_code = "w",
		modifiers = {
			"command",
		},
	},
	type = "basic",
}
local file = io.open(os.getenv("HOME") .. "/.config/karabiner/assets/complex_modifications/applaucher.json", "w")
file:write(JSON.encode(applaucher))
file:close()
