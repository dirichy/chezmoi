#!/usr/bin/env lua
package.path = os.getenv("HOME") .. "/scripts/lua/?.lua;" .. package.path
local wm = require("wmux.wm")
local kmap = require("wmux.bind")
local apps = require("wmux.applauncher")
local SHELL = require("wmux.shell")
local SHIFT = kmap.modifier.SHIFT
local CTRL = kmap.modifier.CTRL
local ALT = kmap.modifier.ALT
local SUPER = kmap.modifier.SUPER
local FN = kmap.modifier.FN
local winmod = SUPER
local sysmod = SUPER + CTRL
local appmod = ALT
for _, dir in ipairs({ "h", "j", "k", "l" }) do
	kmap.bind(dir, winmod, wm.focus(dir))
	kmap.bind(dir, winmod + SHIFT, wm.swap_win(dir))
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
	kmap.bind(tostring(i), winmod, wm.move_to_space(i))
	kmap.bind(tostring(i), winmod + SHIFT, wm.move_win_to_space(i))
	if FN then
		kmap.bind(tostring(i), FN, wm.move_to_space(i))
	end
end
-- kmap.bind("backspace", winmod, wm.move_to_space(11))
-- kmap.bind("backspace", winmod + SHIFT, wm.move_win_to_space(11))

local app_keymap = {
	t = SHELL.new(apps.terminal),
	b = SHELL.new(apps.browser),
	-- e = SHELL.new(filemgr),
	q = SHELL.new(apps.qq),
	w = SHELL.new(apps.wechat),
	space = SHELL.new(apps.menu),
}
for key, cmd in pairs(app_keymap) do
	kmap.bind(key, appmod, cmd)
end
local sys_keymap = {
	-- s = SHELL.new("shutdown"),
	-- r = SHELL.new("reboot"),
	-- w = SHELL.new("sudo grub-reboot 2 && reboot"),
	-- d = function()
	-- 	hl.timer(function()
	-- 		hl.dispatch(hl.dsp.dpms("off"))
	-- 	end, { timeout = 1000, type = "oneshot" })
	-- end,
	-- c = hl.dsp.dpms("on"),
}
for key, cmd in pairs(sys_keymap) do
	kmap.bind(key, sysmod, cmd, nil, nil, { release = true })
end
if kmap.createmod then
	kmap.createmod("caps_lock", "control", "escape")
	local ESC = kmap.createmod("escape", "esc")
	kmap.bind("1", ESC, wm.capture_screen())
	kmap.bind("2", ESC, wm.capture_screen(true))
end
if kmap.print then
	kmap.print()
end
return {
	wm = wm,
	keybinder = kmap,
}
