local M = {}
local SHELL = require("kmap.shell")
local function always()
	return true
end
M.modifier = {
	SHIFT = 1,
	CTRL = 2,
	ALT = 4,
	SUPER = 8,
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
		for _, app in ipairs(applications) do
			applications[app] = true
		end
		return function()
			local win = hl.get_active_window()
			return win and applications[win]
		end
	end,
	application_unless = function(applications)
		if type(applications) == "string" then
			applications = { applications }
		end
		for _, app in ipairs(applications) do
			applications[app] = true
		end
		return function()
			local win = hl.get_active_window()
			return not (win and applications[win])
		end
	end,
}
M.bindlist = {}
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
	for _, value in ipairs(mods) do
		local mod = M.modifier[value]
		if not mod then
			error("unknown modifier: " .. value)
			break
		end
		ret = ret + mod
	end
	return ret
end
function M.int2mods(mod)
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

function M.bind(key, mod, fn, conditions, priority, opts)
	mod = M.int2mods(mod) or {}
	local string_key = ""
	for _, m in ipairs(mod) do
		string_key = string_key .. m .. " + "
	end
	string_key = string_key .. key
	if getmetatable(fn) == SHELL then
		fn = fn:hyprland()
	end
	hl.bind(string_key, fn, opts)
end

return M
