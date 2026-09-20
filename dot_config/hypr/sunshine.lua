local M = {}

local monitor = require("monitor")
local OUTPUT = "SUNSHINE"
local physical_output = monitor.config.output
local mirror_timer

local function enable_default()
	if mirror_timer then
		mirror_timer:set_enabled(false)
		mirror_timer = nil
	end
	monitor.config.mirror = ""
	hl.monitor(monitor.config)
end

local function mirror_physical()
	if mirror_timer then
		mirror_timer:set_enabled(false)
	end
	mirror_timer = hl.timer(function()
		hl.monitor({ output = physical_output, mirror = "SUNSHINE" })
		mirror_timer = nil
	end, { timeout = 500, type = "oneshot" })
end

local function enable_sunshine(width, height, rate, mode)
	local only = mode == "only"
	if only then
		local scale = monitor.get_scale(width, height)
		local spec = {
			output = OUTPUT,
			disabled = false,
			mode = ("%dx%d@%s"):format(width, height, rate),
			position = ("%dx%d"):format(0, 0),
			scale = scale,
		}
		hl.monitor(spec)
		return
	end
	local mirror = mode == "mirror"
	if mirror then
		local spec = {
			output = OUTPUT,
			disabled = false,
			mirror = physical_output,
		}
		hl.monitor(spec)
		return
	end
	local scale = monitor.get_scale(width, height)
	local physical_width = monitor.default_monitor.width / monitor.config.scale
	local physical_height = monitor.default_monitor.height / monitor.config.scale
	local logical_width = width / scale
	local x = math.floor(monitor.default_monitor.x + (physical_width - logical_width) / 2 + 0.5)
	local y = math.floor(monitor.default_monitor.y + physical_height + 0.5)
	local spec = {
		output = OUTPUT,
		disabled = false,
		mode = ("%dx%d@%s"):format(width, height, rate),
		position = ("%dx%d"):format(x, y),
		-- position = "auto-down",
		scale = scale,
		mirror = mirror and monitor.default_monitor.name or "",
	}
	hl.monitor(spec)
end
local function mirror_sunshine_to_default()
	local spec = {
		output = OUTPUT,
		disabled = false,
		mode = ("%dx%d@%s"):format(
			monitor.default_monitor.width,
			monitor.default_monitor.height,
			monitor.default_monitor.refresh_rate
		),
		position = ("%dx%d"):format(monitor.default_monitor.x, monitor.default_monitor.y),
		scale = monitor.config.scale,
		mirror = monitor.default_monitor.name,
	}
	hl.monitor(spec)
end

function M.expand(width, height, rate)
	enable_sunshine(width, height, rate)
	enable_default()
end

function M.mirror(width, height, rate)
	enable_default()
	enable_sunshine(width, height, rate, "mirror")
end

function M.reverse_mirror(width, height, rate)
	enable_sunshine(width, height, rate)
	mirror_physical()
end

function M.only(width, height, rate)
	enable_sunshine(width, height, rate, "only")
	hl.monitor({ output = monitor.default_monitor.name, disabled = true })
end

function M.reset()
	enable_default()
	mirror_sunshine_to_default()
end

if hl.g.is_start then
	hl.exec_cmd("systemctl --user start app-dev.lizardbyte.app.Sunshine")
	hl.exec_cmd("hyprctl output create headless " .. OUTPUT)
	hl.timer(function()
		mirror_sunshine_to_default()
	end, { timeout = 10000, type = "oneshot" })
else
	hl.exec_cmd("~/.local/bin/sunshine_pre restore")
end

return M
