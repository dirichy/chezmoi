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

local JSON = require("cjson")
local applaucher = { title = "shottr", rules = { {
	description = "Use esc+number to shottr",
	manipulators = {},
} } }
for key, value in pairs(shortcuts) do
	local mani = {
		from = { key_code = key },
		to = {
			shell_command = [=[echo 'tell application "System Events" to tell process "Shottr"
        click menu item "]=] .. value .. [=[" of menu 1 of menu bar 2
    end tell' | osascript
  ]=],
		},
		conditions = { { type = "variable_if", name = "esc_down", value = 1 } },
		type = "basic",
	}
	applaucher.rules[1].manipulators[#applaucher.rules[1].manipulators + 1] = mani
end
for key, value in pairs(complex_shortcuts) do
	local mani = {
		from = { key_code = key },
		to = {
			shell_command = [=[echo 'tell application "System Events" to tell process "Shottr"
        click menu item "]=] .. value .. [=[" of menu "more" of menu item "more" of menu 1 of menu bar 2
    end tell' | osascript
  ]=],
		},
		conditions = { { type = "variable_if", name = "esc_down", value = 1 } },
		type = "basic",
	}
	applaucher.rules[1].manipulators[#applaucher.rules[1].manipulators + 1] = mani
end
local file = io.open(os.getenv("HOME") .. "/.config/karabiner/assets/complex_modifications/shottr.json", "w")
file:write(JSON.encode(applaucher))
file:close()
