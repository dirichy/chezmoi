-- **************************************************
-- 防止屏幕进入睡眠
-- **************************************************

hs.loadSpoon("Caffeine")

spoon.Caffeine:start()
hs.hotkey.bind({ "cmd", "alt" }, "w", function()
	spoon.Caffeine.setDisplay(hs.caffeinate.toggle("displayIdle"))
end)
