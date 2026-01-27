return function()
	hs.execute("/opt/homebrew/bin/brew services start redis")
	local app_with_useless_window = {
		"mac mouse fix",
		"karabiner",
		"shottr",
	}
	local useless_app = {
		"microsoft autoupdate",
	}
	hs.g.boot_timer = hs.timer.doAfter(10, function()
		for _, appname in ipairs(app_with_useless_window) do
			local app = hs.application.find(appname)
			if app then
				for _, window in ipairs(app:allWindows()) do
					window:close()
				end
			else
			end
		end
		for _, appname in ipairs(useless_app) do
			local app = hs.application.find(appname)
			if app then
				app:kill()
			else
			end
		end
		hs.rime.reload()
	end)
end
