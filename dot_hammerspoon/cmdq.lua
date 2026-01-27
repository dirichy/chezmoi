local util = require("utils")
local function quitApp()
	local app = hs.application.frontmostApplication()
	if app:bundleID() == "com.valvesoftware.steam.helper" then
		hs.eventtap.keyStroke({ "cmd" }, "q", nil, app)
	else
		app:kill()
	end
end
local cmdQDelay = 0.3

util.bindHold(
	{ "cmd" },
	"q",
	quitApp,
	{ delay = cmdQDelay, alert = {
		start = "hold ⌘Q to quit",
		abort = "quit aborted",
		done = "quited",
	} }
)
hs.hotkey.bind({ "cmd", "alt" }, "q", quitApp)
