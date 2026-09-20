local M = {}

local monitor = require("monitor")
local OUTPUT = "SUNSHINE"
local CACHE_PATH = os.getenv("XDG_RUNTIME_DIR") .. "/hypr-sunshine-state.lua"

local function load_cache()
	local chunk = loadfile(CACHE_PATH)
	if not chunk then
		return
	end
	local ok, saved = pcall(chunk)
	return ok and saved or nil
end

local cache = load_cache()

local function write_cache()
	local temporary_path = CACHE_PATH .. ".tmp"
	local file = io.open(temporary_path, "w")
	if not file then
		return
	end
	local contents = ("return { spec = { output = %q, disabled = %s, mode = %q, position = %q, scale = %.17g, mirror = %q }, only = %s, physical = { output = %q, mode = %q, position = %q, disabled = %s, scale = %.17g } }\n"):format(
		cache.spec.output,
		tostring(cache.spec.disabled),
		cache.spec.mode or "",
		cache.spec.position or "",
		cache.spec.scale or 1,
		cache.spec.mirror or "",
		tostring(cache.only),
		cache.physical.output,
		cache.physical.mode,
		cache.physical.position,
		tostring(cache.physical.disabled),
		cache.physical.scale
	)
	file:write(contents)
	file:close()
	os.rename(temporary_path, CACHE_PATH)
end

local function cache_state(spec, only)
	cache = {
		spec = spec,
		only = only or false,
		physical = {
			output = monitor.default_monitor.name,
			mode = "preferred",
			position = ("%dx%d"):format(monitor.default_monitor.x, monitor.default_monitor.y),
			disabled = false,
			scale = monitor.config.scale,
		},
	}
	write_cache()
end

local function enable_default()
	hl.monitor(monitor.config)
end

local function enable_sunshine(width, height, rate, mirror)
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
	cache_state(spec)
end
local function disable_sunshine()
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
	cache_state(spec)
end

function M.expand(width, height, rate)
	enable_sunshine(width, height, rate)
	enable_default()
end

function M.mirror(width, height, rate)
	enable_default()
	enable_sunshine(width, height, rate, true)
end

function M.only(width, height, rate)
	enable_sunshine(width, height, rate)
	hl.monitor({ output = monitor.default_monitor.name, disabled = true })
	cache.only = true
	write_cache()
end

function M.reset()
	enable_default()
	disable_sunshine()
end

local function restore_cache()
	if not cache then
		return
	end

	hl.monitor(cache.spec)
	for key, value in pairs(cache.physical) do
		monitor.config[key] = value
	end
	monitor.default_monitor = hl.get_monitor(cache.physical.output)
	if cache.only then
		hl.monitor({ output = cache.physical.output, disabled = true })
	end
end

hl.on("hyprland.start", function()
	hl.exec_cmd("hyprctl output create headless " .. OUTPUT)
	disable_sunshine()
end)

restore_cache()

return M
