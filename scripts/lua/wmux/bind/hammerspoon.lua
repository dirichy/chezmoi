local SHELL = require("wmux.shell")
---@type keybinder
local M = {}

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
			error("unknown modifier: " .. value)
			break
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
	local flag = nil
	local ret = {}
	for index, value in pairs(M._modifier) do
		if mod & value ~= 0 then
			flag = true
			ret[#ret + 1] = index
		end
	end
	return flag and ret
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
		return { {
			bundle_identifiers = applications,
			type = "frontmost_application_if",
		} }
	end,
	application_unless = function(applications)
		if type(applications) == "string" then
			applications = { applications }
		end
		return { {
			bundle_identifiers = applications,
			type = "frontmost_application_unless",
		} }
	end,
}
function M.bind(key, mod, fn, conditions, priority, opts)
	local to = fn
	if getmetatable(fn) == SHELL then
		to = function()
			hs.execute(fn.cmd)
		end
	end
	hs.hotkey.bind(M.int2mods(mod), key, nil, to, nil, nil)
end

function M.createmod(mod, name, overload) end
return M
