local wm = require("wmux.wm")
local kmap = require("wmux.bind")
local apps = require("wmux.applauncher")
local SHELL = require("wmux.shell")
local SHIFT = kmap.modifier.SHIFT
local CTRL = kmap.modifier.CTRL
local ALT = kmap.modifier.ALT
local SUPER = kmap.modifier.SUPER
local FN = kmap.modifier.FN
kmap.bind("return_or_enter", CTRL, { "return_or_enter", ALT }, "com.tencent.qq")
kmap.bind("return_or_enter", CTRL, { "return_or_enter", ALT }, "com.tencent.xinWeChat")
