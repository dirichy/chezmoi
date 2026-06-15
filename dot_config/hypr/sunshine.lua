local M = {}
M.default_monitor = nil
local function valid_monitor(m)
	return m and m.id ~= -1
end
local function get_default_monitor()
	M.default_monitor = hl.get_active_monitor()
	if not valid_monitor(M.default_monitor) then
		M.default_monitor = nil
		hl.timer(get_default_monitor, { type = "oneshot", timeout = 1000 })
	end
end
get_default_monitor()
local function get_scale(width, height)
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
	local a = scale_tbl[width]
	if not a then
		return
	end
	return a[height]
end
-- local monitors = {
-- 	ipad = { width = 2338, height = 1668, rate = 60, scale = 2 },
-- 	macbook = { width = 2560, height = 1600, rate = 60, scale = 1.5 },
-- }
function M.create_headless(width, height, rate, scale, direct)
	-- default = hl.get_active_monitor()
	direct = direct or "down"
	scale = scale or get_scale(width, height) or 1
	rate = rate or 60
	hl.exec_cmd(table.concat({ "hyprctl", "output", "create", "headless", "SUNSHINE" }, " "))
	hl.monitor({
		scale = scale,
		mode = width .. "x" .. height .. "@" .. rate,
		output = "SUNSHINE",
		position = "auto",
	})
end
function M.disable_default()
	if M.default_monitor then
		hl.monitor({
			output = M.default_monitor.name,
			disabled = true,
		})
	end
	-- hl.dispatch(hl.dsp.dpms({ action = "off", monitor = default or "DP-3" }))
end
function M.expand(a, ...)
	-- if type(a) == "string" then
	-- 	local b = monitors[a]
	-- 	M.create_headless(b.width, b.height, b.rate, b.scale)
	-- else
	hl.dispatch(hl.dsp.dpms({ action = "on" }))
	M.create_headless(a, ...)
	-- end
end
function M.only(...)
	M.expand(...)
	M.disable_default()
end
function M.enable_default()
	hl.monitor({ output = M.default_monitor and M.default_monitor.name or "", disabled = false })
	hl.monitor({
		output = M.default_monitor and M.default_monitor.name or "",
		-- mode = "3840x2160@60",
		mode = "prefered",
		position = "auto-up",
		scale = M.default_monitor and M.default_monitor.height == 2160 and 2.5 or 2,
	})
	hl.dsp.dpms({ action = "on" })
end
function M.only_then_expand(...)
	M.only(...)
	hl.timer(M.enable_default, { type = "oneshot", timeout = 1000 })
end
function M.reset()
	-- hl.monitor({ output = M.default_monitor and M.default_monitor.name or "", disabled = false })
	-- hl.monitor({
	-- 	output = M.default_monitor and M.default_monitor.name or "",
	-- 	-- mode = "3840x2160@60",
	-- 	mode = "prefered",
	-- 	-- position = "0x0",
	-- 	scale = M.default_monitor and M.default_monitor.height == 2160 and 2.5 or 2,
	-- })
	hl.exec_cmd(table.concat({ "hyprctl", "output", "remove", "SUNSHINE" }, " "))
	hl.exec_cmd("systemctl --user restart app-dev.lizardbyte.app.Sunshine; hyprctl reload")
	-- hl.dsp.dpms({ action = "on" })
	-- hl.timer(get_default_monitor, { type = "oneshot", timeout = 1000 })
end
return M
