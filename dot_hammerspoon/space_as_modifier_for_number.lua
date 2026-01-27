local JSON = require("cjson")
local thershold = 100
local space_as_modifier_for_number = {
	title = "space_as_modifier_for_number.lua",
	rules = {
		{
			description = "Keybind for hammerspoon space_as_modifier_for_number.lua, see github.com/dirichy/dotfiles",
			manipulators = {},
		},
	},
}
local shortcuts = {
	["1"] = "Capture Screen",
	["2"] = "Capture Area",
	["3"] = "Scrolling Capture",
	["9"] = "Recongize Text/QR",
}
local complex_shortcuts = {
	["4"] = "Scrolling (Up)",
	["5"] = "Capture Active Window",
	["6"] = "Capture Any Window",
	["7"] = "Delayed Screenshot (3S)",
	["8"] = "Repeat Area Capture",
}
for key, value in pairs(shortcuts) do
	local mani = {
		from = {
			simultaneous = { { key_code = "spacebar" }, { key_code = key } },
			simultaneous_options = { key_down_order = "strict" },
		},
		to = {
			shell_command = [=[echo 'tell application "System Events" to tell process "Shottr"
        click menu item "]=] .. value .. [=[" of menu 1 of menu bar 2
    end tell' | osascript
  ]=],
		},
		type = "basic",
	}
	table.insert(space_as_modifier_for_number.rules[1].manipulators, mani)
end
for key, value in pairs(complex_shortcuts) do
	local mani = {
		from = {
			simultaneous = { { key_code = "spacebar" }, { key_code = key } },
			simultaneous_options = { key_down_order = "strict" },
		},
		to = {
			shell_command = [=[echo 'tell application "System Events" to tell process "Shottr"
        click menu item "]=] .. value .. [=[" of menu "more" of menu item "more" of menu 1 of menu bar 2
    end tell' | osascript
  ]=],
		},
		type = "basic",
		parameters = {
			["basic.simultaneous_threshold_milliseconds"] = thershold,
		},
	}
	table.insert(space_as_modifier_for_number.rules[1].manipulators, mani)
end
local file = io.open(
	os.getenv("HOME") .. "/.config/karabiner/assets/complex_modifications/space_as_modifier_for_number.json",
	"w"
)
file:write(JSON.encode(space_as_modifier_for_number))
file:close()
