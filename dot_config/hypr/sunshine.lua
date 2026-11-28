local M = {}

local monitor = require("monitor")
local OUTPUT = "SUNSHINE"
local physical_output = monitor.config.output
local transition_timer
-- Avoid reusing an outstanding client's ID when the Lua config is reloaded.
local request_id = math.random(1, 2147483647)
local state_file = os.getenv("XDG_RUNTIME_DIR") .. "/hypr-sunshine-command"

local function get_output(name)
	for _, output in ipairs(hl.get_monitors({ all = true })) do
		if output.name == name then
			return output
		end
	end
end

local function independent(output)
	return output and output.enabled and not output.is_mirror
end

local function mirrors(target, source)
	if not target or not target.enabled or not source or not target.is_mirror then
		return false
	end
	for _, output in ipairs(source.mirrors) do
		if output.name == target.name then
			return true
		end
	end
	return false
end

local function physical_spec(mirror)
	local spec = {}
	for key, value in pairs(monitor.config) do
		spec[key] = value
	end
	spec.mirror = mirror or ""
	return spec
end

local function stream_spec(source, width, height, rate, only)
	local scale = monitor.get_scale(width, height)
	local x, y = 0, 0
	if not only then
		local logical_width = source.width / source.scale
		x = math.floor(source.x + (logical_width - width / scale) / 2 + 0.5)
		y = math.floor(source.y + source.height / source.scale + 0.5)
	end
	return {
		output = OUTPUT,
		disabled = false,
		mode = ("%dx%d@%s"):format(width, height, rate),
		position = ("%dx%d"):format(x, y),
		scale = scale,
		mirror = "",
	}
end

local function mirror_spec(source)
	return {
		output = OUTPUT,
		disabled = false,
		mode = ("%dx%d@%s"):format(source.width, source.height, source.refresh_rate),
		position = ("%dx%d"):format(source.x, source.y),
		scale = source.scale,
		mirror = physical_output,
	}
end

local function stream_ready(output, width, height, rate)
	return independent(output)
		and output.width == width
		and output.height == height
		and math.abs(output.refresh_rate - rate) < 0.1
end

-- Monitor rules apply asynchronously. Each phase waits for actual state before
-- submitting a dependent rule; a new request cancels the previous transition.
local function change_layout(mode, width, height, rate, on_done)
	if transition_timer then
		transition_timer:set_enabled(false)
		transition_timer = nil
	end
	local attempts = 0
	local phase = "physical"
	request_id = request_id + 1
	M.status = "pending"
	M.error = nil
	local staging_position
	local source = get_output(physical_output)
	local output = get_output(OUTPUT)
	if source and independent(output) and (not source.enabled or source.is_mirror) then
		-- Leave room for the real output before restoring it at its normal
		-- position. Otherwise "only" -> reset briefly overlaps two outputs.
		local spec = stream_spec(source, output.width, output.height, output.refresh_rate, false)
		staging_position = spec.position
		hl.monitor(spec)
		phase = "separate"
	else
		hl.monitor(physical_spec())
	end

	transition_timer = hl.timer(function()
		attempts = attempts + 1
		local source = get_output(physical_output)
		local output = get_output(OUTPUT)
		local done = false
		if phase == "separate" and independent(output)
			and ("%dx%d"):format(output.x, output.y) == staging_position then
			hl.monitor(physical_spec())
			phase = "physical"
		elseif phase == "physical" and independent(source) and output then
			if mode == "mirror" then
				hl.monitor(mirror_spec(source))
			else
				-- Keep both outputs apart until the real one is actually disabled.
				hl.monitor(stream_spec(source, width, height, rate, false))
			end
			phase = "virtual"
		elseif phase == "virtual" then
			if mode == "mirror" and independent(source) then
				done = mirrors(output, source)
					and output.width == source.width and output.height == source.height
					and output.scale == source.scale
				if not done then
					-- Re-submit if the compositor missed a mirror while reconnecting.
					hl.monitor(mirror_spec(source))
				end
			elseif stream_ready(output, width, height, rate) and independent(source) then
				if mode == "expand" then
					done = true
				elseif mode == "only" then
					hl.monitor({ output = physical_output, disabled = true })
					phase = "final"
				elseif mode == "reverse-mirror" then
					hl.monitor(physical_spec(OUTPUT))
					phase = "final"
				end
			end
		elseif phase == "final" and stream_ready(output, width, height, rate) then
			if mode == "only" then
				if source and not source.enabled then
					hl.monitor(stream_spec(source, width, height, rate, true))
					phase = "origin"
				end
			else
				done = mirrors(source, output)
				if not done then
					hl.monitor(physical_spec(OUTPUT))
				end
			end
		elseif phase == "origin" then
			done = source and not source.enabled and stream_ready(output, width, height, rate)
				and output.x == 0 and output.y == 0
		end

		if done or attempts >= 100 then
			transition_timer:set_enabled(false)
			transition_timer = nil
			M.status = done and "ready" or "error"
			if done then
				local ok, err = pcall(on_done)
				if not ok then
					M.status = "error"
					M.error = tostring(err)
				end
			else
				M.error = mode .. " transition timed out at " .. phase
			end
			if M.error then
				print("Sunshine: " .. M.error)
			end
		end
	end, { timeout = 100, type = "repeat" })
	return request_id
end

-- IPC entry point. Keep validation, persistence and completion in the same
-- process as the display state machine, rather than duplicating them in a CLI.
function M.request(mode, width, height, rate)
	if mode == "reset" then
		mode = "mirror"
	end
	if mode == "restore" then
		return M.restore()
	end
	assert(mode == "expand" or mode == "mirror" or mode == "reverse-mirror" or mode == "only", "invalid Sunshine layout")
	local args = ""
	if mode ~= "mirror" then
		width, height, rate = tonumber(width), tonumber(height), tonumber(rate)
		assert(width and math.tointeger(width) and width > 0, "invalid Sunshine width")
		assert(height and math.tointeger(height) and height > 0, "invalid Sunshine height")
		assert(rate and rate > 0 and rate < math.huge, "invalid Sunshine frame rate")
		args = ("%d,%d,%s"):format(width, height, rate)
	end
	local command = ("hl.sunshine.%s(%s)\n"):format(mode:gsub("-", "_"), args)
	return change_layout(mode, width, height, rate, function()
		local file = assert(io.open(state_file .. ".tmp", "w"))
		local written, write_error = file:write(command)
		local closed, close_error = file:close()
		assert(written, write_error)
		assert(closed, close_error)
		assert(os.rename(state_file .. ".tmp", state_file))
	end)
end

function M.poll(id)
	if id ~= request_id then
		return "error: Sunshine request superseded or configuration reloaded"
	end
	if M.error then
		return "error: " .. M.error
	end
	return M.status
end

function M.restore()
	local file = io.open(state_file, "r")
	local command = file and file:read("*l") or ""
	if file then
		file:close()
	end
	-- Read the old command format as data; never execute persisted Lua code.
	local mode, args = command:match("^hl%.sunshine%.([%a_]+)%(([%d%.,%s]*)%)%s*$")
	if mode == "expand" or mode == "only" or mode == "reverse_mirror" then
		local width, height, rate = args:match("^(%d+),(%d+),([%d%.]+)$")
		if width and height and rate then
			return M.request(mode:gsub("_", "-"), width, height, rate)
		end
	end
	return M.request("mirror")
end

function M.expand(width, height, rate)
	return M.request("expand", width, height, rate)
end

function M.only(width, height, rate)
	return M.request("only", width, height, rate)
end

function M.reverse_mirror(width, height, rate)
	return M.request("reverse-mirror", width, height, rate)
end

function M.mirror()
	return M.request("mirror")
end

M.reset = M.mirror

function M.setup()
	if hl.g.is_start then
		-- Register the idle mirror before creating the output to avoid an
		-- unnecessary independent workspace during startup.
		local source = get_output(physical_output)
		if source then
			hl.monitor(mirror_spec(source))
		end
		hl.exec_cmd("hyprctl output create headless " .. OUTPUT)
		M.reset()
		hl.exec_cmd("systemctl --user start app-dev.lizardbyte.app.Sunshine")
	else
		M.restore()
	end
end

return M
