local util = require("util")
local json = hypr.json
local uv = hypr.uv
local M = {}
M.get_dbus_item = function()
	local dbus_item = util.cmd
		.gdbus(
			"call",
			"--session",
			"--dest",
			"org.kde.StatusNotifierWatcher",
			"--object-path",
			"/StatusNotifierWatcher",
			"--method",
			"org.freedesktop.DBus.Properties.Get",
			"org.kde.StatusNotifierWatcher",
			"RegisteredStatusNotifierItems"
		)
		:match("%[.*%]")
		:gsub("'", '"')
	dbus_item = json.decode(dbus_item)
	return dbus_item
end
M.qq = {}
M.qq.start = function()
	local dbus_item_before = M.get_dbus_item()
	local len = #dbus_item_before
	for index, value in ipairs(dbus_item_before) do
		dbus_item_before[value] = true
	end
	local handle = uv.new_timer()
	hypr.cmd(
		"env",
		"GDK_SCALE=1",
		os.getenv("HOME") .. "/.local/bin/_tencentqq",
		"--enable-features=UseOzonePlatform",
		"--ozone-platform=x11",
		"--enable-wayland-ime",
		{
			async = true,
			callback = function()
				M.qq.dbus_item = false
			end,
		}
	)
	handle:start(1000, 1000, function()
		local dbus_item_after = M.get_dbus_item()
		if #dbus_item_after == len then
			return
		end
		for index, value in ipairs(dbus_item_after) do
			if not dbus_item_before[value] then
				handle:stop()
				handle:close()
				M.qq.dbus_item = value:match("^[^/]*")
			end
		end
	end)
end

M.qq.active = function()
	if M.qq.dbus_item then
		hypr.cmd(
			"dbus-send",
			"--session",
			"--dest=" .. M.qq.dbus_item,
			"--type=method_call",
			"--print-reply",
			"/StatusNotifierItem",
			"org.kde.StatusNotifierItem.Activate",
			"int32:0",
			"int32:0"
		)
	else
		M.qq.start()
	end
end

M.wechat = {}
M.wechat.start = function()
	local dbus_item_before = M.get_dbus_item()
	local len = #dbus_item_before
	for index, value in ipairs(dbus_item_before) do
		dbus_item_before[value] = true
	end
	local handle = uv.new_timer()
	-- env QT_IM_MODULE="fcitx" QT_SCALE_FACTOR=2.5 _wechat --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime
	hypr.cmd(
		"zsh",
		"-c",
		'env QT_IM_MODULE="fcitx" _wechat --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime',
		{
			async = true,
			callback = function()
				M.wechat.dbus_item = false
			end,
		}
	)

	-- hypr.cmd(
	-- 	"env",
	-- 	'QT_IM_MODULE="fcitx"',
	-- 	"XMODIFIERS='@im=fcitx'",
	-- 	"QT_SCALE_FACTOR=2.5",
	-- 	os.getenv("HOME") .. "/.local/bin/_wechat",
	-- 	"--enable-features=UseOzonePlatform",
	-- 	"--ozone-platform=wayland",
	-- 	"--enable-wayland-ime",
	-- 	{
	-- 		async = true,
	-- 		callback = function()
	-- 			M.wechat.dbus_item = false
	-- 		end,
	-- 	}
	-- )
	handle:start(1000, 1000, function()
		local dbus_item_after = M.get_dbus_item()
		if #dbus_item_after == len then
			return
		end
		for index, value in ipairs(dbus_item_after) do
			if not dbus_item_before[value] then
				handle:stop()
				handle:close()
				M.wechat.dbus_item = value:match("^[^/]*")
			end
		end
	end)
end

M.wechat.active = function()
	if M.wechat.dbus_item then
		hypr.cmd(
			"dbus-send",
			"--session",
			"--dest=" .. M.wechat.dbus_item,
			"--type=method_call",
			"--print-reply",
			"/StatusNotifierItem",
			"org.kde.StatusNotifierItem.Activate",
			"int32:0",
			"int32:0"
		)
	else
		M.wechat.start()
	end
end
return M
