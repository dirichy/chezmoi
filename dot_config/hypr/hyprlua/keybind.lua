local window = require("window")
local bit = require("bit")
local util = require("util")
local M = {}
-- SHIFT CAPS CTRL/CONTROL ALT MOD2 MOD3 SUPER/WIN/LOGO/MOD4 MOD5
---@alias hypr.keybind.mod "SHIFT"|"CTRL"|"ALT"|"SUPER"
---@class hypr.keybind.processor
---@field fn function
---@field condition fun():boolean
---@field priority number
---@class hypr.keybind.table
---@field [string] hypr.keybind.processor[]

---@type table<integer,hypr.keybind.table>
M.bindlist = {}
M.modifier = {
	SHIFT = 1,
	CTRL = 2,
	ALT = 4,
	SUPER = 8,
}
for i = 0, 15 do
	M.bindlist[i] = {}
end

local function mod2int(mods)
	if not mods then
		return 0
	end
	if type(mods) == "number" then
		return mods
	end
	local ret = 0
	if type(mods) == "string" then
		mods = { mods }
	end
	for index, value in ipairs(mods) do
		local mod = M.modifier[value]
		if not mod then
			error("unknown modifier: " .. value)
			break
		end
		ret = ret + mod
	end
	return ret
end

local function mod2string(mods)
	if not mods then
		return ""
	end
	mods = mod2int(mods)
	local ret = ""
	for index, value in pairs(M.modifier) do
		if bit.band(mods, value) ~= 0 then
			ret = ret .. index .. " "
		end
	end
	ret = ret:sub(1, -2)
	return ret
end

M.condition = {
	always = function()
		return true
	end,
	application = function(applications)
		if type(applications) == "string" then
			applications = { applications }
		end
		for index, value in ipairs(applications) do
			applications[value] = true
		end
		return function()
			return applications[window.focusedWindow():application()]
		end
	end,
	never = function()
		return false
	end,
}

---@param key string|integer
---@param mod hypr.keybind.mod[]|integer
---@param fn function|string|table
---@param priority integer?
---@param condition ( fun():boolean )|string|string[]|nil
M.bind = function(key, mod, fn, condition, priority)
	if type(fn) ~= "function" then
		local k, m
		if type(fn) == "string" then
			k = fn
		else
			k = fn[1]
			m = fn[2]
		end
		fn = function()
			M.sendkey(k, m)
		end
	end
	mod = mod2int(mod)
	priority = priority or 100
	if not condition then
		priority = 1
		condition = M.condition.always
	end
	if type(condition) ~= "function" then
		condition = M.condition.application(condition)
	end
	if not M.bindlist[mod][key] then
		M.bindlist[mod][key] = {}
		util.keyword.unbind(mod2string(mod), key)
		util.keyword.bind(
			mod2string(mod),
			key,
			"exec",
			"~/.local/bin/hyprlua 'hypr.keybind.call(\"" .. key .. '",' .. tostring(mod) .. ")'"
		)
	end
	local i = 1
	while M.bindlist[mod][key][i] do
		if M.bindlist[mod][key][i].priority <= priority then
			break
		end
		i = i + 1
	end
	table.insert(M.bindlist[mod][key], i, { fn = fn, condition = condition, priority = priority })
end

function M.sendkey(key, mod, win)
	win = win or "activewindow"
	return util.dispatch.sendshortcut(mod2string(mod), key, win)
end

function M.call(key, mod)
	for index, value in ipairs(M.bindlist[mod][key]) do
		if value.condition() then
			return value.fn()
		end
	end
	return M.sendkey(key, mod)
end

setmetatable(M, {
	__call = function(t, ...)
		M.bind(...)
	end,
})
return M
