local M = {}
local SHELL = require("wmux.shell")
local log = require("wmux.log")

local always = function()
	return true
end

local function warn(message)
	log.warn("keyd", message)
end

M.modifier = {
	SHIFT = 1,
	CTRL = 2,
	ALT = 4,
	SUPER = 8,
}
M.feature = {
	createmod = true,
	physicalmod = true,
	fallbackmod = true,
	virtualmod = true,
}

local keyd_mod = {
	[M.modifier.SHIFT] = "S",
	[M.modifier.CTRL] = "C",
	[M.modifier.ALT] = "A",
	[M.modifier.SUPER] = "M",
}

local keyd_layer = {
	[M.modifier.SHIFT] = "vitualS",
	[M.modifier.CTRL] = "vitualC",
	[M.modifier.ALT] = "vitualA",
	[M.modifier.SUPER] = "vitualM",
}

local modifier_alias = {
	shift = M.modifier.SHIFT,
	control = M.modifier.CTRL,
	ctrl = M.modifier.CTRL,
	alt = M.modifier.ALT,
	option = M.modifier.ALT,
	super = M.modifier.SUPER,
	meta = M.modifier.SUPER,
	command = M.modifier.SUPER,
}

local key_alias = {
	caps_lock = "capslock",
	escape = "esc",
	return_or_enter = "enter",
	left_arrow = "left",
	right_arrow = "right",
	up_arrow = "up",
	down_arrow = "down",
	grave_accent_and_tilde = "`",
	hyphen = "-",
	equal_sign = "=",
	open_bracket = "[",
	close_bracket = "]",
	backslash = "\\",
	semicolon = ";",
	quote = "'",
	comma = ",",
	period = ".",
	slash = "/",
}

local function normalize_key(key)
	key = tostring(key)
	if key:match("^mouse:") then
		warn("ignoring unsupported mouse key: " .. key)
		return nil
	end
	return key_alias[key] or key
end

function M.mod2int(mods)
	if not mods then
		return 0
	end
	if type(mods) == "table" and mods.fallback then
		return mods.fallback
	end
	if type(mods) == "number" then
		return mods
	end
	local ret = 0
	if type(mods) == "string" then
		mods = { mods }
	end
	for _, value in ipairs(mods) do
		local mod = M.modifier[value]
		if not mod then
			warn("ignoring unknown modifier: " .. value)
			return nil
		end
		ret = ret + mod
	end
	return ret
end

function M.int2mods(mod)
	if type(mod) ~= "number" then
		return mod
	end
	local ret = {}
	for _, value in ipairs({ M.modifier.CTRL, M.modifier.SHIFT, M.modifier.ALT, M.modifier.SUPER }) do
		if mod & value ~= 0 then
			ret[#ret + 1] = keyd_mod[value]
		end
	end
	return #ret > 0 and ret or nil
end

local function mod2keyd(mod)
	local mods = M.int2mods(mod)
	return mods and table.concat(mods, "-") or nil
end

local function mod2layer(mod)
	if type(mod) == "table" and mod.layer then
		return mod.layer
	end
	mod = M.mod2int(mod)
	if not mod then
		return nil
	end
	if mod == 0 then
		return "main"
	end
	local layers = {}
	for _, value in ipairs({ M.modifier.CTRL, M.modifier.SHIFT, M.modifier.ALT, M.modifier.SUPER }) do
		if mod & value ~= 0 then
			layers[#layers + 1] = keyd_layer[value]
		end
	end
	return table.concat(layers, "+")
end

M.condition = {
	always = function()
		return always
	end,
	not_moonlight = function()
		return M.condition.application_unless("moonlight")
	end,
	application = function(applications)
		if type(applications) == "string" then
			applications = { applications }
		end
		local application_set = {}
		for _, app in ipairs(applications) do
			application_set[app] = true
		end
		return function(win)
			win = win or hl and hl.get_active_window()
			return win and application_set[win.class] == true
		end
	end,
	application_unless = function(applications)
		if type(applications) == "string" then
			applications = { applications }
		end
		local application = M.condition.application(applications)
		return function(win)
			return not application(win)
		end
	end,
}

local function normalize_condition(conditions)
	if not conditions then
		return always
	end
	if type(conditions) ~= "function" then
		return M.condition.application(conditions)
	end
	return conditions
end

local function convert_to(to)
	if not to then
		return nil
	end
	if getmetatable(to) == SHELL then
		return nil
	end
	if type(to) == "function" then
		return nil
	end
	if type(to) == "string" then
		return normalize_key(to)
	end
	if type(to) == "table" and to[1] then
		local mods = mod2keyd(to[2])
		local key = normalize_key(to[1])
		return mods and (mods .. "-" .. key) or key
	end
	warn("ignoring unsupported action")
	return nil
end

M.bindlist = {}

local function insert_binding(key, mod, to, condition, priority)
	key = normalize_key(key)
	local layer = mod2layer(mod)
	if not key or not layer or not to then
		return
	end
	M.bindlist[#M.bindlist + 1] = {
		key = key,
		layer = layer,
		to = to,
		condition = condition,
		priority = priority,
	}
end

function M.bind(key, mod, fn, conditions, priority, opts)
	local to
	if type(mod) == "table" and mod.fallback then
		to = convert_to({ key, mod.fallback })
	else
		to = convert_to(fn)
	end
	insert_binding(key, mod, to, normalize_condition(conditions), priority or (conditions and 100 or 1))
end

function M.createmod(key, name, overload, conditions, fallback)
	local mod = modifier_alias[name] or M.modifier[name:upper()]
	if not mod and not fallback then
		warn("ignoring virtual modifier without fallback: " .. name)
		return nil
	end
	local layer = mod and keyd_layer[mod] or "vitual" .. name:sub(1, 1):upper() .. name:sub(2)
	local to = "layer(" .. layer .. ")"
	if overload then
		to = "overload(" .. layer .. "," .. convert_to(overload) .. ")"
	end
	insert_binding(key, 0, to, normalize_condition(conditions), conditions and 100 or 1)
	return mod or { layer = layer, fallback = fallback, virtual = true }
end

function M.collect(win)
	local by_key = {}
	for _, binding in ipairs(M.bindlist) do
		if binding.condition(win) then
			local key = binding.layer .. "." .. binding.key
			local current = by_key[key]
			if not current or current.priority <= binding.priority then
				by_key[key] = binding
			end
		end
	end
	local keys = {}
	for key in pairs(by_key) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	local ret = {}
	for _, key in ipairs(keys) do
		local binding = by_key[key]
		ret[#ret + 1] = binding.layer .. "." .. binding.key .. " = " .. binding.to
	end
	return ret
end

local function shell_quote(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

function M.apply(win)
	local keyd_bin = os.getenv("KEYD_BIN") or "keyd"
	local cmd = keyd_bin .. " bind reset"
	for _, binding in ipairs(M.collect(win)) do
		cmd = cmd .. " " .. shell_quote(binding)
	end
	hl.exec_cmd(cmd)
end

function M.print(win)
	for _, binding in ipairs(M.collect(win)) do
		print(binding)
	end
end

return M
