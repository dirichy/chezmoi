-- **************************************************
-- 连接到公司 Wi-Fi 后自动静音
-- **************************************************

-- --------------------------------------------------
-- 定义公司的 wifi 名称
local WORK_SSID = { ["BNU-Mobile"] = true }
-- --------------------------------------------------
local function mute()
	hs.audiodevice.defaultOutputDevice():setOutputMuted(true)
end

local function unmute()
	hs.audiodevice.defaultOutputDevice():setOutputMuted(false)
end

local handleWifiChanged = function()
	local currentSSID = hs.wifi.currentNetwork()
	if WORK_SSID[currentSSID] then
		mute()
	else
		-- unmute()
	end
end

hs.g.wm_wifiWatcher = hs.wifi.watcher.new(handleWifiChanged)
hs.g.wm_wifiWatcher:start()
