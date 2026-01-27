local JSON = require("JSON")
local M = {}
local function b(n)
	return { pointing_button = "button" .. tostring(n) }
end
local dpad_rotate = {
	u = "right",
	r = "down",
	d = "left",
	l = "up",
}
local function d(str)
	return { generic_desktop = "dpad_" .. dpad_rotate[str] }
end
M.joycon_map = {
	a = b(1),
	x = b(2),
	b = b(3),
	y = b(4),
	r = b(15),
	zr = b(16),
	add = b(10),
	home = b(13),
	sl = b(5),
	sr = b(6),
	R = b(12),
	stickup = d("u"),
	stickright = d("r"),
	stickleft = d("l"),
	stickdown = d("d"),
}

M.keymap = {
	title = "sioyek",
	rules = {
		{
			description = "Keybind for using joycon to control sioyek, see github.com/dirichy/dotfiles",
			manipulators = {},
		},
	},
}

function M.map(condition, lhs, rhs, opts)
	local map = { type = "basic" }
	map.conditions = condition or {}
	table.insert(map.conditions, { type = "device_if", identifiers = { { vendor_id = 1406 } } })
	if M.joycon_map[lhs] then
		lhs = M.joycon_map[lhs]
	end
	if type(lhs) == "string" then
		lhs = { lhs }
	end
	if lhs[1] then
		for i = 1, #lhs - 1 do
			table.insert(map.conditions, { type = "variable_if", name = M.make_modifier(lhs[i]), value = 1 })
		end
		map.from = lhs[#lhs]
	else
		map.from = lhs
	end
	if type(rhs) == "string" then
		rhs = { rhs }
	end
	local to
	if type(rhs[1]) == "string" then
		to = { { key_code = table.remove(rhs), modifiers = {} } }
		for i = 1, #rhs do
			table.insert(to[1].modifiers, rhs[i])
		end
	else
		to = rhs
	end
	map.to = to
	table.insert(M.keymap.rules[1].manipulators, map)
	return map
end

M.modifiers = {}
function M.make_modifier(str)
	if M.modifiers then
		return M.modifiers[str]
	end
	M.modifiers[str] = str .. "_down"
	return M.map({}, str, { set_variable = { name = str .. "_down", value = 1, key_up_value = 0 } })
end

local function map4sioyek(lhs, rhs, opts)
	M.map(
		{ {
			type = "frontmost_application_if",
			["bundle_identifiers"] = { "^info\\.sioyek\\.sioyek$" },
		} },
		lhs,
		rhs,
		opts
	)
end
local sioyek = {
	stickdown = "j",
	stickup = "k",
	stickright = "l",
	stickleft = "h",
	add = { "right_shift", "equal_sign" },
	home = "s",
	sl = { "right_control", "i" },
	sr = { "right_control", "o" },
	r = "m",
	zr = "quote",
	a = "a",
	b = "b",
	x = "x",
	y = "y",
}
for key, value in pairs(sioyek) do
	map4sioyek(key, value)
end

print(JSON:encode(M.keymap))

return M
