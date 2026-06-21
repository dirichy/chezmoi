local util = require("util")
-- ~/.config/hypr/modules/xwayland_focus_guard.lua
--
-- Workaround for XWayland/xcb keyboard-focus glitches on Hyprland.
--
-- Logic:
--   XWayland window A
--   -> XWayland window B
--   -> briefly open a tiny Wayland-native wofi layer
--   -> wofi is automatically killed by timeout
--   -> refocus back to XWayland window B
--
-- Requirements:
--   wofi
--   coreutils timeout

-- local last_window = nil

-- 调参区
local cooldown_ms = 500

-- wofi 存活时间。
-- GNU timeout 支持小数秒，例如 0.12s。
local wofi_timeout = "0.12s"

-- 先只处理你已经发现有问题的程序。
-- 稳定后如果想全局处理所有 XWayland，可以改 is_target_xwayland。
local target_classes = {
	QQ = true,
	qq = true,
	WeChat = true,
	wechat = true,
	["微信"] = true,
	sioyek = true,
}

-- local function is_xwayland(w)
-- 	return w ~= nil and (w.xwayland == true or w.class == "QQ")
-- end
--
local function is_target_window(w)
	-- if not is_xwayland(w) then
	-- 	return false
	-- end

	-- 保守模式：只处理指定 class
	return w and target_classes[w.class or ""] == true

	-- 全局模式：处理所有 XWayland
	-- return true
end

local function open_bounce_wofi()
	-- 关键点：
	-- 1. 用 wofi 作为 Wayland layer，短暂拿 keyboard focus。
	-- 2. 用 timeout 自动杀 wofi，避免 pkill 误杀普通 wofi。
	-- 3. wofi 放左上角，1x1，隐藏搜索框。
	--
	-- 注意：这里用 sh -c 是为了管道 printf -> wofi。
	local cmd = table.concat({
		"timeout",
		wofi_timeout,
		"wofi",
		"--width 1",
		"--height 1",
		"--hide-search",
		"--location top_right",
		"-d",
	}, " ")

	hl.dispatch(hl.dsp.exec_cmd(cmd))
end

local function start_bounce(w)
	if w == nil then
		return
	end
	open_bounce_wofi()
end

-- cooldown_timer = hl.timer(function()
-- 	cooldown_timer:set_enabled(false)
-- end, {
-- 	timeout = cooldown_ms,
-- 	type = "repeat",
-- })
-- cooldown_timer:set_enabled(false)
--
local update = util.debounce(function(w)
	if --[[ is_xwayland(prev) and  ]]
		is_target_window(w)
	then
		start_bounce(w)
	end
end, cooldown_ms)
hl.on("window.active", function(w)
	update(w)
end)
