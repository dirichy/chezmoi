local M = {}
local util = require("util")
local uv = hypr.uv
local json = hypr.json
local ddc = "/usr/bin/ddcutil"
local bus = 1
local current
local max
local target = nil
local function getBrightness()
	local stdout = uv.new_pipe(false)
	local handle
	handle = uv.spawn(
		ddc,
		{ args = { "--bus=" .. bus, "getvcp", "10" }, stdio = { nil, stdout, nil } },
		function(code, signal)
			uv.close(handle)
		end
	)
	local output = ""
	uv.read_start(stdout, function(err, data)
		if data then
			output = output .. data
		else
			current, max = string.match(
				output,
				"VCP%s*code%s*0x%d*%s*%(Brightness%s*%):%s*current%s*value%s*=%s*(%d*),%s*max%s*value%s*=%s*(%d*)"
			)
			current = tonumber(current)
			max = tonumber(max)
			stdout:close()
		end
	end)
end
getBrightness()
function M.getBrightness()
	return current, max
end
M.waybar = {}
local changespeed = 5
local changeTable = { [5] = 1, [1] = 10, [10] = 5 }
function M.waybar.json()
	return json.encode({
		percentage = target or current,
		tooltip = string.format("current step:%d,click to change", changespeed),
	})
end
function M.waybar.cyclechangespeed()
	changespeed = changeTable[changespeed]
end
function M.waybar.raiseBrightness()
	if target then
		target = target + changespeed
		if target < 0 then
			target = 0
		end
		if target > max then
			target = max
		end
	else
		M.setBrightness(current + changespeed)
	end
end
function M.waybar.downBrightness()
	if target then
		target = target - changespeed
		if target < 0 then
			target = 0
		end
		if target > max then
			target = max
		end
	else
		M.setBrightness(current - changespeed)
	end
	return target
end
uv.new_timer():start(0, 5000, function()
	if target then
		return
	end
	getBrightness()
end)

local changing = false
local handle
local function changeBrightness()
	if current == target then
		changing = false
		target = nil
		return
	end
	local nextstep
	if target > current then
		nextstep = current + math.min(math.ceil(0.4 * math.exp(current / 25)), 7)
		if nextstep > target then
			nextstep = target
		end
	else
		nextstep = current - math.min(math.ceil(0.4 * math.exp(current / 30)), 7)
		if nextstep < target then
			nextstep = target
		end
	end
	handle = uv.spawn(
		ddc,
		{ args = { "--bus=" .. bus, "setvcp", "10", tostring(nextstep) }, stdio = { nil, nil, nil } },
		function(code, signal)
			uv.close(handle)
			current = nextstep
			changeBrightness()
		end
	)
end
function M.setBrightness(value)
	if changing then
		target = value
		if target < 0 then
			target = 0
		end
		if target > max then
			target = max
		end
		return
	end
	changing = true
	target = value
	if target < 0 then
		target = 0
	end
	if target > max then
		target = max
	end
	changeBrightness()
	return true
end

function M.dmps(on)
	on = on and "on" or "off"
	return util.dispatch.dpms(on)
end

function M.setMonitor(...)
	return util.keyword.monitor(...)
end
return M
