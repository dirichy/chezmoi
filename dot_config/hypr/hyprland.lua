print = function(str)
	hl.notification.create({ text = tostring(str), duration = 5000 })
end
local im = require("fcitx")
local SHELL = require("kmap.shell")
local monitor = hl.get_active_monitor()
hl.monitor({
	output = "",
	-- mode = "3840x2160@60",
	mode = "prefered",
	-- position = "0x0",
	scale = monitor.height == 2160 and 2.5 or 1.5,
})
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
		layout = "scrolling",
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
		key_press_enables_dpms = true,
		-- new_window_takes_over_fullscreen = 2
	},
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
local terminal = "kitty"
local filemgr = "kitty yazi"
local menu = "wofi --show drun -i"
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
	hl.exec_cmd("sleep 1;systemctl --user restart sunshine")
	hl.exec_cmd("sleep 1;systemctl --user restart udisken")
	hl.exec_cmd("sleep 1;systemctl --user restart waybar")
	hl.exec_cmd("xrdb -merge ~/.Xresources")
	hl.exec_cmd("mkdir -p ~/Pictures/Screenshots")
	hl.exec_cmd(terminal)
	hl.exec_cmd(browser)
end)
hl.on("config.reloaded", function()
	hl.exec_cmd("systemctl --user restart hyprlua")
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

---@type keybinder
local kmap = require("kmap.bind")
local wm = require("kmap.wm")
local SHIFT = kmap.modifier.SHIFT
local CTRL = kmap.modifier.CTRL
local ALT = kmap.modifier.ALT
local SUPER = kmap.modifier.SUPER

local winmod = SUPER
local sysmod = SUPER + CTRL
local appmod = ALT
for _, dir in ipairs({ "h", "j", "k", "l" }) do
	kmap.bind(dir, winmod, wm.focus(dir))
end
local wm_keymap = {
	q = wm.close_window(),
	f = wm.toggle_fullscreen(),
	v = wm.toggle_float(),
}
for key, fn in pairs(wm_keymap) do
	kmap.bind(key, winmod, fn)
end
for i = 1, 9 do
	kmap.bind(tostring(i), winmod, wm.space(i))
	kmap.bind(tostring(i), winmod + SHIFT, wm.move_win_to_space(i))
end
kmap.bind("backspace", winmod, wm.space(11))
kmap.bind("backspace", winmod + SHIFT, wm.move_win_to_space(11))
kmap.bind("mouse:272", winmod, hl.dsp.window.drag(), nil, nil, { mouse = true })
kmap.bind("mouse:273", winmod, hl.dsp.window.resize(), nil, nil, { mouse = true })
kmap.bind("mouse:272", winmod, hl.dsp.window.fullscreen())
kmap.bind("mouse:273", winmod, hl.dsp.window.float())

local app_keymap = {
	t = SHELL.new(terminal),
	b = SHELL.new(browser),
	e = SHELL.new(filemgr),
	q = SHELL.new("/home/dirichy/.local/bin/qq"),
	w = SHELL.new("wechat-universal"),
	space = SHELL.new(menu),
}
for key, cmd in pairs(app_keymap) do
	kmap.bind(key, appmod, cmd)
end
local sys_keymap = {
	s = SHELL.new("shutdown"),
	r = SHELL.new("reboot"),
	w = SHELL.new("sudo grub-reboot 2 && reboot"),
	d = function()
		hl.timer(function()
			hl.dispatch(hl.dsp.dpms("off"))
		end, { timeout = 1000, type = "oneshot" })
	end,
	c = hl.dsp.dpms("on"),
}
for key, cmd in pairs(sys_keymap) do
	kmap.bind(key, sysmod, cmd, nil, nil, { release = true })
end
local ydotool_code = {
	a = 30,
	c = 46,
	v = 47,
}
for key, code in pairs(ydotool_code) do
	kmap.bind(key, ALT, function()
		local win = wm.get_active_window()
		if win and win.class == "kitty" then
			hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL + SHIFT ", key = key, state = "down" }))
			hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL + SHIFT ", key = key, state = "up" }))
		else
			hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = key, state = "down" }))
			hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = key, state = "up" }))
		end
	end)
end
local im_state = {
	kitty = false,
	wofi = false,
	QQ = true,
}
local current_class = ""
hl.on("window.active", function(win)
	local class = win.class or ""
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
end)
hl.on("workspace.active", function(space)
	local id = space.id
	hl.exec_cmd("hyprctl hyprpaper wallpaper ,~/wallpaper/wallpaper" .. tostring(id) .. ".JPG")
end)
hl.timer(require("luv").run, { type = "repeat", timeout = 10 })
