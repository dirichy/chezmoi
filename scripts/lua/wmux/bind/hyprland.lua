local M = {}
local SHELL = require("wmux.shell")
local log = require("wmux.log")
local function always()
	return true
end
local function warn(message)
	log.warn("hyprland", message)
end
M.modifier = {
	SHIFT = 1,
	CTRL = 2,
	ALT = 4,
	SUPER = 8,
}
M.feature = {
	createmod = true,
	fallbackmod = true,
}

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
		return function()
			local win = hl.get_active_window()
			return win and application_set[win.class] == true
		end
	end,
	application_unless = function(applications)
		if type(applications) == "string" then
			applications = { applications }
		end
		local application_set = {}
		for _, app in ipairs(applications) do
			application_set[app] = true
		end
		return function()
			local win = hl.get_active_window()
			return not (win and application_set[win.class] == true)
		end
	end,
}
M.bindlist = {}
local function mod2string(mods)
	local mod_int = M.mod2int(mods)
	if not mod_int then
		return nil
	end
	mods = M.int2mods(mod_int) or {}
	local ret = ""
	for _, m in ipairs(mods) do
		ret = ret .. m .. " + "
	end
	return ret:sub(1, -4)
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
	if type(mod) == "table" and mod.fallback then
		mod = mod.fallback
	end
	if type(mod) ~= "number" then
		return mod
	end
	local flag = nil
	local ret = {}
	for index, value in pairs(M.modifier) do
		if mod & value ~= 0 then
			flag = true
			ret[#ret + 1] = index
		end
	end
	return flag and ret
end

function M.send_key(key, mods)
	hl.dispatch(hl.dsp.send_key_state({ mods = mod2string(mods), key = key, state = "down" }))
	hl.dispatch(hl.dsp.send_key_state({ mods = mod2string(mods), key = key, state = "up" }))
end

local function normalize_action(fn)
	if getmetatable(fn) == SHELL then
		fn = fn:hyprland()
	end
	if type(fn) == "function" then
		return fn
	end
	if type(fn) == "string" then
		return function()
			return M.send_key(fn)
		end
	end
	if type(fn) == "table" and fn[1] then
		return function()
			return M.send_key(fn[1], fn[2])
		end
	end
	return function()
		return hl.dispatch(fn)
	end
end

local function normalize_condition(conditions)
	if not conditions then
		return always
	end
	if type(conditions) ~= "function" then
		return M.condition.application(conditions)
	end
	return conditions
end

local function opts_key(opts)
	if not opts then
		return ""
	end
	local keys = {}
	for key in pairs(opts) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	local parts = {}
	for _, key in ipairs(keys) do
		parts[#parts + 1] = key .. "=" .. tostring(opts[key])
	end
	return table.concat(parts, ";")
end

local function bind_key(key, mod, opts)
	local string_key = mod2string(mod)
	if not string_key then
		return nil
	end
	if string_key ~= "" then
		string_key = string_key .. " + "
	end
	string_key = string_key .. key
	local bucket_key = string_key .. "\0" .. opts_key(opts)
	if not M.bindlist[bucket_key] then
		M.bindlist[bucket_key] = {}
		hl.bind(string_key, function()
			for _, binding in ipairs(M.bindlist[bucket_key]) do
				if binding.condition() then
					return binding.action()
				end
			end
			return false
		end, opts)
	end
	return M.bindlist[bucket_key]
end

function M.bind(key, mod, fn, conditions, priority, opts)
	local bindlist = bind_key(key, mod, opts)
	if not bindlist then
		return
	end
	priority = priority or (conditions and 100 or 1)
	local binding = {
		action = normalize_action(fn),
		condition = normalize_condition(conditions),
		priority = priority,
	}
	local i = 1
	while bindlist[i] do
		if bindlist[i].priority <= priority then
			break
		end
		i = i + 1
	end
	table.insert(bindlist, i, binding)
end

function M.createmod(key, name, overload, conditions, fallback)
	if not fallback then
		warn("ignoring createmod without fallback: " .. name)
		return nil
	end
	return { fallback = fallback }
end

return M
