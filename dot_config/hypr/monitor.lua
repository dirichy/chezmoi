local M = {}
M.config = {
	output = "",
	mode = "prefered",
	-- position = "0x0",
	scale = nil,
}
local function valid_monitor(m)
	return m and m.id ~= -1
end
function M.get_active_monitor_safe(callback, max_try)
	max_try = max_try or 30
	local monitor = hl.get_active_monitor()
	if valid_monitor(monitor) then
		return callback(monitor)
	end
	local timer
	local try = 0
	timer = hl.timer(function()
		if try >= max_try then
			print("can't find monitor")
			timer:set_enabled(false)
			timer = nil
			return
		end
		local m = hl.get_active_monitor()
		if valid_monitor(m) then
			timer:set_enabled(false)
			timer = nil
			return callback(m)
		end
		try = try + 1
	end, { timeout = 500, type = "repeat" })
end
local scale_tbl = {
	[3840] = {
		[2160] = 2.4,
	},
	[2388] = {
		[1668] = 1.5,
	},
	[2560] = {
		[1440] = 2,
		[1600] = 2,
	},
}
function M.setup(opts)
	opts = opts or {}
	for key, value in pairs(opts) do
		M.config[key] = value
	end
	if not M.config.scale then
		M.get_active_monitor_safe(
			---@param monitor HL.Monitor
			function(monitor)
				local width = monitor.width
				local height = monitor.height
				if scale_tbl[width] then
					M.config.scale = scale_tbl[width][height]
				else
					M.config.scale = height / 1000
				end
				hl.monitor(M.config)
			end
		)
	else
		hl.monitor(M.config)
	end
end
return M
