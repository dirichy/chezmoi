local M = {}

local entries = {
	escape = {
		aliases = { "escape", "esc", "Escape", "KEY_ESC" },
		karabiner = "escape",
		keyd = "esc",
		hammerspoon = "escape",
		hyprland = "Escape",
	},
	return_or_enter = {
		aliases = { "return_or_enter", "return", "enter", "Return", "KEY_ENTER" },
		karabiner = "return_or_enter",
		keyd = "enter",
		hammerspoon = "return",
		hyprland = "Return",
	},
	delete_or_backspace = {
		aliases = { "delete_or_backspace", "backspace", "BackSpace", "KEY_BACKSPACE" },
		karabiner = "delete_or_backspace",
		keyd = "backspace",
		hammerspoon = "delete",
		hyprland = "BackSpace",
	},
	delete_forward = {
		aliases = { "delete_forward", "delete", "forwarddelete", "Delete", "KEY_DELETE" },
		karabiner = "delete_forward",
		keyd = "delete",
		hammerspoon = "forwarddelete",
		hyprland = "Delete",
	},
	tab = {
		aliases = { "tab", "Tab", "KEY_TAB" },
		karabiner = "tab",
		keyd = "tab",
		hammerspoon = "tab",
		hyprland = "Tab",
	},
	spacebar = {
		aliases = { "spacebar", "space", "Space", "KEY_SPACE" },
		karabiner = "spacebar",
		keyd = "space",
		hammerspoon = "space",
		hyprland = "space",
	},
	caps_lock = {
		aliases = { "caps_lock", "capslock", "Caps_Lock", "KEY_CAPSLOCK" },
		karabiner = "caps_lock",
		keyd = "capslock",
		hammerspoon = "capslock",
		hyprland = "Caps_Lock",
	},
	left_arrow = {
		aliases = { "left_arrow", "left", "Left", "KEY_LEFT" },
		karabiner = "left_arrow",
		keyd = "left",
		hammerspoon = "left",
		hyprland = "Left",
	},
	right_arrow = {
		aliases = { "right_arrow", "right", "Right", "KEY_RIGHT" },
		karabiner = "right_arrow",
		keyd = "right",
		hammerspoon = "right",
		hyprland = "Right",
	},
	up_arrow = {
		aliases = { "up_arrow", "up", "Up", "KEY_UP" },
		karabiner = "up_arrow",
		keyd = "up",
		hammerspoon = "up",
		hyprland = "Up",
	},
	down_arrow = {
		aliases = { "down_arrow", "down", "Down", "KEY_DOWN" },
		karabiner = "down_arrow",
		keyd = "down",
		hammerspoon = "down",
		hyprland = "Down",
	},
	page_up = {
		aliases = { "page_up", "pageup", "Page_Up", "Prior", "KEY_PAGEUP" },
		karabiner = "page_up",
		keyd = "pageup",
		hammerspoon = "pageup",
		hyprland = "Page_Up",
	},
	page_down = {
		aliases = { "page_down", "pagedown", "Page_Down", "Next", "KEY_PAGEDOWN" },
		karabiner = "page_down",
		keyd = "pagedown",
		hammerspoon = "pagedown",
		hyprland = "Page_Down",
	},
	home = {
		aliases = { "home", "Home", "KEY_HOME" },
		karabiner = "home",
		keyd = "home",
		hammerspoon = "home",
		hyprland = "Home",
	},
	end_key = {
		aliases = { "end", "End", "KEY_END" },
		karabiner = "end",
		keyd = "end",
		hammerspoon = "end",
		hyprland = "End",
	},
	grave_accent_and_tilde = {
		aliases = { "grave_accent_and_tilde", "grave", "`", "KEY_GRAVE" },
		karabiner = "grave_accent_and_tilde",
		keyd = "grave",
		hammerspoon = "`",
		hyprland = "grave",
	},
	hyphen = {
		aliases = { "hyphen", "minus", "-", "KEY_MINUS" },
		karabiner = "hyphen",
		keyd = "minus",
		hammerspoon = "-",
		hyprland = "minus",
	},
	equal_sign = {
		aliases = { "equal_sign", "equal", "=", "KEY_EQUAL" },
		karabiner = "equal_sign",
		keyd = "equal",
		hammerspoon = "=",
		hyprland = "equal",
	},
	open_bracket = {
		aliases = { "open_bracket", "leftbrace", "bracketleft", "[", "KEY_LEFTBRACE" },
		karabiner = "open_bracket",
		keyd = "leftbrace",
		hammerspoon = "[",
		hyprland = "bracketleft",
	},
	close_bracket = {
		aliases = { "close_bracket", "rightbrace", "bracketright", "]", "KEY_RIGHTBRACE" },
		karabiner = "close_bracket",
		keyd = "rightbrace",
		hammerspoon = "]",
		hyprland = "bracketright",
	},
	backslash = {
		aliases = { "backslash", "\\", "KEY_BACKSLASH" },
		karabiner = "backslash",
		keyd = "backslash",
		hammerspoon = "\\",
		hyprland = "backslash",
	},
	semicolon = {
		aliases = { "semicolon", ";", "KEY_SEMICOLON" },
		karabiner = "semicolon",
		keyd = "semicolon",
		hammerspoon = ";",
		hyprland = "semicolon",
	},
	quote = {
		aliases = { "quote", "apostrophe", "'", "KEY_APOSTROPHE" },
		karabiner = "quote",
		keyd = "apostrophe",
		hammerspoon = "'",
		hyprland = "apostrophe",
	},
	comma = {
		aliases = { "comma", ",", "KEY_COMMA" },
		karabiner = "comma",
		keyd = "comma",
		hammerspoon = ",",
		hyprland = "comma",
	},
	period = {
		aliases = { "period", "dot", ".", "KEY_DOT" },
		karabiner = "period",
		keyd = "dot",
		hammerspoon = ".",
		hyprland = "period",
	},
	slash = {
		aliases = { "slash", "/", "KEY_SLASH" },
		karabiner = "slash",
		keyd = "slash",
		hammerspoon = "/",
		hyprland = "slash",
	},
	left_control = {
		aliases = { "left_control", "leftcontrol", "ctrl", "Control_L", "KEY_LEFTCTRL" },
		karabiner = "left_control",
		keyd = "leftcontrol",
		hammerspoon = "ctrl",
		hyprland = "Control_L",
	},
	right_control = {
		aliases = { "right_control", "rightcontrol", "rightctrl", "Control_R", "KEY_RIGHTCTRL" },
		karabiner = "right_control",
		keyd = "rightcontrol",
		hammerspoon = "rightctrl",
		hyprland = "Control_R",
	},
	left_shift = {
		aliases = { "left_shift", "leftshift", "shift", "Shift_L", "KEY_LEFTSHIFT" },
		karabiner = "left_shift",
		keyd = "leftshift",
		hammerspoon = "shift",
		hyprland = "Shift_L",
	},
	right_shift = {
		aliases = { "right_shift", "rightshift", "Shift_R", "KEY_RIGHTSHIFT" },
		karabiner = "right_shift",
		keyd = "rightshift",
		hammerspoon = "rightshift",
		hyprland = "Shift_R",
	},
	left_option = {
		aliases = { "left_option", "leftalt", "alt", "option", "Alt_L", "KEY_LEFTALT" },
		karabiner = "left_option",
		keyd = "leftalt",
		hammerspoon = "alt",
		hyprland = "Alt_L",
	},
	right_option = {
		aliases = { "right_option", "rightalt", "rightoption", "Alt_R", "KEY_RIGHTALT" },
		karabiner = "right_option",
		keyd = "rightalt",
		hammerspoon = "rightalt",
		hyprland = "Alt_R",
	},
	left_command = {
		aliases = { "left_command", "leftmeta", "cmd", "command", "meta", "Super_L", "KEY_LEFTMETA" },
		karabiner = "left_command",
		keyd = "leftmeta",
		hammerspoon = "cmd",
		hyprland = "Super_L",
	},
	right_command = {
		aliases = { "right_command", "rightmeta", "rightcmd", "rightcommand", "Super_R", "KEY_RIGHTMETA" },
		karabiner = "right_command",
		keyd = "rightmeta",
		hammerspoon = "rightcmd",
		hyprland = "Super_R",
	},
	fn = {
		aliases = { "fn", "keyboard_fn" },
		karabiner = "fn",
		keyd = "fn",
		hammerspoon = "fn",
		hyprland = "XF86Fn",
	},
}

local alias_to_canonical = {}
local conflicts = {}
local produced_aliases = {
	A = "a",
	B = "b",
	C = "c",
	D = "d",
	E = "e",
	F = "f",
	G = "g",
	H = "h",
	I = "i",
	J = "j",
	K = "k",
	L = "l",
	M = "m",
	N = "n",
	O = "o",
	P = "p",
	Q = "q",
	R = "r",
	S = "s",
	T = "t",
	U = "u",
	V = "v",
	W = "w",
	X = "x",
	Y = "y",
	Z = "z",
}

local function add_alias(alias, canonical)
	local current = alias_to_canonical[alias]
	if current and current ~= canonical then
		conflicts[alias] = conflicts[alias] or { current }
		conflicts[alias][#conflicts[alias] + 1] = canonical
		return
	end
	alias_to_canonical[alias] = canonical
end

for canonical, entry in pairs(entries) do
	add_alias(canonical, canonical)
	for _, alias in ipairs(entry.aliases or {}) do
		add_alias(alias, canonical)
	end
end

local function auto_key(key, backend)
	if key:match("^[a-z]$") or key:match("^[0-9]$") then
		return key
	end
	local f = key:match("^[fF](%d%d?)$")
	if f then
		return "f" .. tostring(tonumber(f))
	end
	if backend == "hyprland" and key:match("^XF86[%w_]+$") then
		return key
	end
	return nil
end

function M.normalize(key)
	if type(key) ~= "string" then
		return key
	end
	return alias_to_canonical[key] or produced_aliases[key] or auto_key(key) or key
end

function M.to(backend, key)
	if type(key) ~= "string" then
		return key
	end
	if key:match("^mouse:") then
		return key
	end
	local canonical = M.normalize(key)
	local entry = entries[canonical]
	if entry then
		return entry[backend] or entry.karabiner or canonical
	end
	return auto_key(canonical, backend) or key
end

function M.conflicts()
	return conflicts
end

return M
