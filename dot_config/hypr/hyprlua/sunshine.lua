local M = {}
local util = require("util")
local default = util.get_data_from_hyprctl("monitors")[1]
local monitors = {
	ipad = { width = 2338, height = 1668, rate = 60, scale = 2 },
	macbook = { width = 2560, height = 1600, rate = 60, scale = 1.5 },
}
function M.create_headless(width, height, rate, scale, direct)
	direct = direct or "down"
	scale = scale or height / 1000
	rate = rate or 60
	hypr.cmd.hyprctl("output", "create", "headless", "SUNSHINE")
	hypr.keyword.monitor("SUNSHINE", width .. "x" .. height .. "@" .. rate, "auto-" .. direct, scale)
end
function M.disable_default()
	hypr.keyword.monitor(default.name, "disabled")
end
function M.expand(a, ...)
	if type(a == "string") then
		local b = monitors[a]
		M.create_headless(b.width, b.height, b.rate, b.scale)
	else
		M.create_headless(a, ...)
	end
end
function M.only(...)
	M.expand(...)
	M.disable_default()
end
function M.reset()
	hypr.keyword.monitor(
		default.name,
		default.width .. "x" .. default.height .. "@" .. default.refreshRate,
		"0x0",
		default.scale
	)
	hypr.cmd.hyprctl("output", "remove", "SUNSHINE")
end
return M
