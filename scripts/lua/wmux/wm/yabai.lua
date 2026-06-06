local SHELL = require("wmux.shell")
local JSON = require("cjson")
local function yabai_m(cmd)
	return SHELL.new("/opt/homebrew/bin/yabai -m " .. cmd)
end
local direction = {
	h = "west",
	l = "east",
	j = "south",
	k = "north",
	tab = "recent",
}
---@type WM
local M = {}
function M.focus_window(dir)
	return yabai_m("window --focus " .. direction[dir] or dir)
end
local moveWorkSpace = {
	h = "(.index + 7) % 9 + 1",
	l = ".index % 9 + 1",
	j = "(.index + 2) % 9 + 1",
	k = "(.index + 5) % 9 + 1",
}
function M.focus_space(dir)
	return SHELL.new(
		[[ i=$(/opt/homebrew/bin/yabai -m query --spaces --space | jq ']]
			.. moveWorkSpace[dir]
			.. [['); /opt/homebrew/bin/yabai -m space --focus "fullscreen$i" || /opt/homebrew/bin/yabai -m space --focus "$i"]]
	)
end
function M.focus(dir)
	return SHELL.new(
		[[ i=$(/opt/homebrew/bin/yabai -m query --spaces --space | jq ']]
			.. moveWorkSpace[dir]
			.. [[');/opt/homebrew/bin/yabai -m window --focus ]]
			.. direction[dir]
			.. [[ || /opt/homebrew/bin/yabai -m space --focus "fullscreen$i" || /opt/homebrew/bin/yabai -m space --focus "$i"]]
	)
end
function M.swap_win(dir)
	return yabai_m("window --swap " .. direction[dir])
end
function M.move_to_space(i)
	return yabai_m("space --focus fullscreen" .. tostring(i)) | yabai_m("space --focus " .. tostring(i))
end
function M.move_win_to_space(i)
	return yabai_m("window --space " .. tostring(i) .. " --focus")
end
function M.toggle_float(float)
	return yabai_m("window --toggle float")
end
function M.toggle_fullscreen(fullscreen)
	return SHELL.new(
		"YABAI_CURRENT_SPACE=$(/opt/homebrew/bin/yabai -m query --spaces --space | jq '.index');YABAI_NEW_SPACE_INDEX=$(/opt/homebrew/bin/yabai -m query --spaces | jq 'length+1');  /opt/homebrew/bin/yabai -m window --toggle native-fullscreen; /opt/homebrew/bin/yabai -m space $YABAI_NEW_SPACE_INDEX --label fullscreen$YABAI_CURRENT_SPACE;"
	)
end
function M.close_window()
	return yabai_m("window --close")
end
function M.get_active_window()
	if hs then
		return hs.window.frontmostWindow()
	end
	local pipe, err = io.popen("/opt/homebrew/bin/yabai -m query --windows --window", "r")
	if not pipe then
		error(err)
	end
	return JSON.decode(pipe:read("*a"))
end
function M.capture_screen(area)
	return area
			and SHELL.new([=[osascript -e 'tell application "System Events" to tell process "Shottr"
        click menu item "Capture Area" of menu 1 of menu bar 2
    end tell'
    ]=])
		or SHELL.new([=[osascript -e 'tell application "System Events" to tell process "Shottr"
        click menu item "Capture Screen" of menu 1 of menu bar 2
    end tell'
    ]=])
end
return M
