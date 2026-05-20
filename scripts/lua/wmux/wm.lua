---@alias Dir "h"|"j"|"k"|"l"
---@alias window hs.window
---@class WM
---@field space fun(space:integer):to
---@field focus_window fun(dir:Dir):to
---@field focus_space fun(dir:Dir):to
---@field focus fun(dir:Dir):to
---@field move_win_to_space fun(space:integer):to
---@field swap_win fun(dir:Dir):to
---@field toggle_float fun(float:boolean?):to
---@field toggle_fullscreen fun(fullscreen:boolean?):to
---@field close_window fun():to
---@field resize fun():to
---@field get_active_window fun():window
---@field capture_screen fun(area:boolean):to
if hl or arg[1] == "keyd" then
	return require("wmux.wm.hyprland")
elseif hs or arg[1] == "karabiner" then
	return require("wmux.wm.yabai")
end
