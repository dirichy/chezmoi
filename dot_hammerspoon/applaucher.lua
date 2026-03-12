local shortcuts = {
	-- a = "open -a Karabiner-Elements.app",
	b = "open -a zen.app",
	d = "open -a Eudic.app",
	-- e = "open -a Karabiner-EventViewer.app",
	-- g = "open -a Gnucash.app",
	t = "/Applications/kitty.app/Contents/MacOS/kitty --detach -1 -d " .. os.getenv("HOME"),
	-- m = "open -a MenubarX.app",
	-- n = "open -a noteful.app",
	q = "open -a QQ.app",
	s = "open -a sioyek.app",
	-- t = "open -a Telegram.app",
	w = "open -a WeChat.app",
	-- v = "open -a VLC.app",
	spacebar = "open -a 'Alfred 5.app'",
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
	local mani3 = {
		from = {
			key_code = key,
			modifiers = {
				mandatory = { "left_command" },
			},
		},
		to = { shell_command = value },
		conditions = {
			{
				bundle_identifiers = { "^com\\.moonlight-stream\\.Moonlight$" },
				type = "frontmost_application_unless",
			},
		},
		type = "basic",
	}
	-- applaucher.rules[1].manipulators[#applaucher.rules[1].manipulators + 1] = mani
	applaucher.rules[1].manipulators[#applaucher.rules[1].manipulators + 1] = mani3
end
applaucher.rules[1].manipulators[#applaucher.rules[1].manipulators + 1] = {
	from = {
		key_code = "q",
		modifiers = {
			mandatory = { "right_command" },
		},
	},
	to = {
		key_code = "q",
		modifiers = {
			"command",
		},
	},
	type = "basic",
}
local file = io.open(os.getenv("HOME") .. "/.config/karabiner/assets/complex_modifications/applaucher.json", "w")
file:write(JSON.encode(applaucher))
file:close()
