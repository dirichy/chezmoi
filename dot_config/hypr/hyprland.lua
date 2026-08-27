local HOME = os.getenv("HOME")
package.path = HOME .. "/.config/hypr/?.lua;" .. HOME .. "/scripts/lua/?.lua;" .. package.path
local util = require("util")
print = function(str)
	hl.notification.create({ text = tostring(str), timeout = 5000 })
end
local im = require("fcitx")
local SHELL = require("wmux.shell")
-- local monitor = require("monitor")
require("monitor").setup()
-- hl.monitor({
-- 	output = "",
-- 	-- mode = "3840x2160@60",
-- 	mode = "prefered",
-- 	-- position = "0x0",
-- 	scale = 2.5,
-- })
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
	binds = {
		drag_threshold = 10,
	},
	ecosystem = { enforce_permissions = false },
	general = {
		gaps_in = 1,
		gaps_out = 1,
		border_size = 2,
		resize_on_border = false,
		allow_tearing = false,
		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},
		layout = "dwindle",
	},

	decoration = {
		rounding = 0,
		rounding_power = 0,
		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 0.95,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},
		-- https://wiki.hypr.land/Configuring/Variables/#blur
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},
	animations = {
		enabled = true,
	},
	dwindle = {
		-- pseudotile = true -- Master switch for pseudotiling.
		-- Enabling is bound to mainMod + P in the keybinds section below
		preserve_split = true, -- You probably want this
	},
	-- See https://wiki.hypr.land/Configuring/Master-Layout/ for more
	master = {
		new_status = "master",
	},
	-- https://wiki.hypr.land/Configuring/Variables/#misc
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background :(
		focus_on_activate = true,
		-- mouse_move_enables_dpms = true
		-- key_press_enables_dpms = true,
		-- new_window_takes_over_fullscreen = 2
	},
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
local terminal = "kitty"
local browser = "zen || zen-browser"
local env_table = {
	["QT_QPA_PLATFORMTHEME"] = "qt6ct",
	["XCURSOR_SIZE"] = "24",
	["HYPRCURSOR_SIZE"] = "24",
	["LIBVA_DRIVER_NAME"] = "nvidia",
	["__GLX_VENDOR_LIBRARY_NAME"] = "nvidia",
	["ELECTRON_OZONE_PLATFORM_HINT"] = "auto",
	["NVD_BACKEND"] = "direct",
	["WLR_DRM_NO_ATOMIC"] = "1",
	["GBM_BACKEND"] = "nvidia-drm",
	["GTK_USE_PORTAL"] = "1",
	["XMODIFIERS"] = "@im=fcitx",
	["QT_QPA_PLATFORM"] = "wayland;xcb",
	["QT_SCALE_FACTOR"] = "1",
	["GDK_SCALE"] = "1",
	["http_proxy"] = "http://127.0.0.1:7890",
	["https_proxy"] = "http://127.0.0.1:7890",
	["all_proxy"] = "socks5://127.0.0.1:7890",
}
for key, value in pairs(env_table) do
	hl.env(key, value)
end

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("fcitx5-remote")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("sleep 1;systemctl --user restart hyprpaper")
	hl.exec_cmd("sleep 1;systemctl --user restart app-dev.lizardbyte.app.Sunshine")
	hl.exec_cmd("sleep 1;systemctl --user restart udisken")
	hl.exec_cmd("sleep 1;systemctl --user restart waybar")
	hl.exec_cmd("sleep 1;systemctl --user restart hypridle")
	hl.exec_cmd("xrdb -merge ~/.Xresources")
	hl.exec_cmd("mkdir -p ~/Pictures/Screenshots")
	hl.exec_cmd(terminal)
	hl.exec_cmd(browser)
end)
hl.on("config.reloaded", function()
	hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')
	hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"')
end)
local windowrules = {
	{
		name = "tile sioyek",
		match = {
			class = "sioyek",
		},
		tile = true,
		focus_on_activate = true,
	},
	{
		name = "fullscreen mpv",
		match = {
			class = "mpv",
		},
		fullscreen = true,
	},
	{
		name = "fix some dragging issues with xwayland",
		no_initial_focus = true,
		match = {
			class = "^$",
			title = "^$",
			float = 1,
			fullscreen = 0,
			pin = 0,
		},
	},
	{
		name = "sb tencent",
		float = true,
		center = true,
		min_size = { 1, 1 },
		match = {
			class = "QQ|wechat",
		},
	},
	{
		name = "float some thing",
		float = true,
		match = {
			class = "ddcui|org.openrgb.OpenRGB|org.fcitx.fcitx5-config-qt|org.pulseaudio.pavucontrol",
		},
	},
	{
		name = "float and stay focused for yazi",
		float = true,
		match = {
			class = "termfilechooser|system_menu|yazi|xdg-desktop-portal-gtk",
		},
	},
}
for _, rule in ipairs(windowrules) do
	hl.window_rule(rule)
end
hl.layer_rule({
	name = "blur waybar",
	match = {
		namespace = "waybar",
	},
	blur = true,
	ignore_alpha = 0.2,
})

---@type keybinder
local wmux = require("wmux")
local kmap = wmux.keybinder
local wm = wmux.wm
hl.wmux_focus = function(direction)
	return wm.focus(direction)()
end
local SHIFT = kmap.modifier.SHIFT
local CTRL = kmap.modifier.CTRL
local ALT = kmap.modifier.ALT
local SUPER = kmap.modifier.SUPER

local winmod = SUPER
local sysmod = SUPER + CTRL
kmap.bind("backspace", winmod, wm.move_to_space(11))
kmap.bind("backspace", winmod + SHIFT, wm.move_win_to_space(11))
kmap.bind("mouse:272", winmod, hl.dsp.window.drag(), nil, nil, { mouse = true })
kmap.bind("mouse:273", winmod, hl.dsp.window.resize(), nil, nil, { mouse = true })
kmap.bind("mouse:272", winmod, hl.dsp.window.fullscreen(), nil, nil, { mouse = true, click = true })
kmap.bind("mouse:273", winmod, hl.dsp.window.float(), nil, nil, { mouse = true, click = true })
local sys_keymap = {
	s = SHELL.new("shutdown"),
	r = SHELL.new("reboot"),
	w = SHELL.new("sudo grub-reboot 2 && reboot"),
	d = function()
		hl.timer(function()
			hl.exec_cmd("ddcutil setvcp 62 80")
			hl.dispatch(hl.dsp.dpms({ action = "off" }))
		end, { timeout = 1000, type = "oneshot" })
	end,
	c = function()
		hl.dispatch(hl.dsp.dpms({ action = "on" }))
		hl.exec_cmd("ddcutil setvcp 62 100")
	end,
	-- c = hl.util.dpms_on,
}
for key, cmd in pairs(sys_keymap) do
	kmap.bind(key, sysmod, cmd, nil, nil, { release = true })
end
local shortcuts = require("shortcuts")
shortcuts.bind_navigation(kmap, wm)
for _, key in ipairs({ "a", "c", "v", "x" }) do
	shortcuts.bind_primary(kmap, key, ALT)
end
shortcuts.bind_terminal_primary(kmap, "n", ALT)
local im_state = {
	kitty = false,
	wofi = false,
	QQ = true,
}
local current_class = ""
local function update_im_context(class)
	if current_class == class then
		return
	end
	coroutine.wrap(function()
		local active = im.is_active()
		im_state[current_class] = active
		current_class = class
		if im_state[class] then
			im.active()
		else
			im.disable()
		end
	end)()
end
hl.on("window.active", function(win)
	update_im_context(win.class or "")
end)
local function is_notification_layer(namespace)
	return type(namespace) == "string" and namespace:lower():match("notif") ~= nil
end
hl.on("layer.opened", function(layer)
	local namespace = layer and (layer.namespace or layer.namespace_name) or ""
	if namespace ~= "" and not is_notification_layer(namespace) then
		update_im_context(namespace)
	end
end)
hl.on("layer.closed", function()
	local win = hl.get_active_window()
	if win then
		update_im_context(win.class or "")
	end
end)
hl.on(
	"workspace.active",
	util.debounce(function(space)
		local id = space.id
		hl.exec_cmd("hyprctl hyprpaper wallpaper ,~/wallpaper/wallpaper" .. tostring(id) .. ".JPG")
	end, 200, true)
)
hl.sunshine = require("sunshine")
hl.timer(require("luv").run, { type = "repeat", timeout = 10 })
require("window_focus_guard")
-- example: foot --app-id=window-bg -o colors.alpha=0.0 [path-to-script]
-- example: kitty --class=window-bg -o background_opacity=0.0 [path-to-script]
-- example: xterm -class window-bg [path-to-script]
-- any program will work, use `hyprctl clients` to discover your window's class/title

-- class is an EXACT match and NOT a regex! Use `hyprctl clients` to find it.
-- You may match on `class` and/or `title`. pos_*/size_* are percentages.
if hl.plugin.hyprwinwrap ~= nil then
	hl.plugin.hyprwinwrap.window({
		class = "window-bg",
		title = "window-bg",
		layer = 0,
		pos_x = 0,
		pos_y = 0,
		size_x = 100,
		size_y = 97,
	})
	-- Second bg window sitting in the centre on top of the first,
	-- useful for showing a visualizer only on a portion of the screen.
	hl.plugin.hyprwinwrap.window({
		class = "window-bg2",
		title = "window-bg2",
		layer = 1,
		pos_x = 25,
		pos_y = 25,
		size_x = 50,
		size_y = 50,
	})
end
hl.bind("SUPER + B", function()
	hl.plugin.hyprwinwrap.focus("window-bg")
end)
