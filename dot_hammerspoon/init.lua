hs.ipc = require("hs.ipc")
local util = require("utils")

hs.g = {}
hs.loadSpoon("EmmyLua")
spoon.EmmyLua:init()
require("wifi_mute")
require("scripts.caffeine")

hs.hotkey.bind({ "cmd" }, "space", function()
	hs.osascript.applescript('tell application "Alfred 5" to search')
end)
local afterboot = require("afterboot")
afterboot()
require("lazy")
