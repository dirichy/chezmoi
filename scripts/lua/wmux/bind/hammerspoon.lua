local SHELL = require("wmux.shell")
local log = require("wmux.log")
---@type keybinder
local M = {}
local INVALID = {}

local function warn(message)
	log.warn("hammerspoon", message)
end

function M.mod2int(mods)
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
		local mod = M._modifier[value]
		if not mod then
			warn("ignoring unknown modifier: " .. value)
			return nil
		end
		ret = ret + mod
	end
	return ret
end
M._modifier = {
	shift = 1,
	control = 2,
	command = 4,
	option = 8,
	-- fn = 16,
}

M.modifier = {
	SHIFT = 1,
	CTRL = 2,
	ALT = 4,
	SUPER = 8,
	-- fn = 16,
}
function M.int2mods(mod)
	if type(mod) ~= "number" then
		return mod
	end
	local ret = {}
	for index, value in pairs(M._modifier) do
		if mod & value ~= 0 then
			ret[#ret + 1] = index
			mod = mod - value
		end
	end
	return mod == 0 and ret
end

local always = function()
	return true
end
M.condition = {
	always = function()
		return always
	end,
	not_moonlight = function()
		return M.condition.application_unless("^com\\.moonlight-stream\\.Moonlight$")
	end,
	application = function(applications)
		if type(applications) == "string" then
			applications = { applications }
		end
		return function()
			local app = hs.application.frontmostApplication()
			local bundle_id = app and app:bundleID() or ""
			for _, pattern in ipairs(applications) do
				if bundle_id:match(pattern) then
					return true
				end
			end
			return false
		end
	end,
	application_unless = function(applications)
		if type(applications) == "string" then
			applications = { applications }
		end
		local application = M.condition.application(applications)
		return function()
			return not application()
		end
	end,
}

M.bindlist = {}
local function normalize_action(fn)
	local action = fn
	if getmetatable(action) == SHELL then
		local cmd = action.cmd
		action = function()
			hs.execute(cmd)
		end
	elseif type(action) == "string" then
		local action_key = action
		action = function()
			hs.eventtap.keyStroke({}, action_key)
		end
	elseif type(action) == "table" then
		local action_key = action[1]
		local action_mod = M.int2mods(action[2]) or {}
		action = function()
			hs.eventtap.keyStroke(action_mod, action_key)
		end
	elseif type(action) ~= "function" then
		warn("ignoring unsupported action")
		return nil
	end
	return action
end

local function normalize_condition(conditions)
	if not conditions then
		return always
	end
	if conditions then
		if type(conditions) ~= "function" then
			if type(conditions) == "string" or type(conditions) == "table" and type(conditions[1]) == "string" then
				conditions = M.condition.application(conditions)
			else
				warn("ignoring binding with unsupported condition")
				return INVALID
			end
		end
	end
	return conditions
end

local function bind_key(key, mod)
	mod = M.int2mods(mod)
	if mod then
		local bind_key = table.concat(mod, "+") .. "\0" .. key
		if not M.bindlist[bind_key] then
			M.bindlist[bind_key] = {}
			hs.hotkey.bind(mod, key, nil, function()
				for _, binding in ipairs(M.bindlist[bind_key]) do
					if binding.condition() then
						return binding.action()
					end
				end
			end, nil, nil)
		end
		return M.bindlist[bind_key]
	end
end

function M.bind(key, mod, fn, conditions, priority, opts)
	local bindlist = bind_key(key, mod)
	if not bindlist then
		return
	end
	local action = normalize_action(fn)
	local condition = normalize_condition(conditions)
	if not action or condition == INVALID then
		return
	end
	priority = priority or (conditions and 100 or 1)
	local binding = {
		action = action,
		condition = condition,
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

return M
