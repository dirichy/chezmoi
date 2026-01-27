local hs = hs
local finish = true
local function getlink(url)
	-- hs.timer.doAfter(1, function()
	hs.execute("open '" .. url .. "'")
	hs.timer.usleep(5000000)
	local app = hs.application.frontmostApplication()
	hs.eventtap.keyStroke({ "cmd" }, "d", nil, app)
	hs.timer.usleep(1000000)
	hs.eventtap.keyStroke({}, "tab", nil, app)
	hs.timer.usleep(1000000)
	hs.eventtap.keyStroke({}, "tab", nil, app)
	hs.timer.usleep(1000000)
	hs.eventtap.keyStroke({}, "tab", nil, app)
	hs.timer.usleep(1000000)
	hs.eventtap.keyStroke({}, "return", nil, app)
	local mp4url = hs.pasteboard.getContents()
	-- hs.execute("nohup aria2c '" .. mp4url .. "' " .. path)
	-- end)
	return mp4url
end
local function download(url, path)
	local dir = path:gsub("/[^/]*$", "")
	hs.execute("mkdir -p " .. dir)

	-- 创建下载请求
	finish = false
	hs.http.asyncGet(url, nil, function(status, body, headers)
		finish = true
		if status == 200 then
			-- 保存下载的文件
			local file = io.open(path, "wb")
			if file then
				file:write(body)
				file:close()
				hs.alert.show("File downloaded successfully!")
			else
				hs.alert("Can't open flie:" .. path)
			end
		else
			hs.alert.show("Download failed. Status: " .. status)
		end
	end)
end

local data = {
	{ 53, 17 },
	{ 54, 23 },
	{ 55, 23 },
	{ 58, 24 },
	{ 59, 24 },
	{ 61, 24 },
	{ 62, 24 },
	{ 64, 24 },
	{ 63, 24 },
	{ 14, 24 },
	{ 711, 24 },
}
local urls = {}
for se, ep in ipairs(data) do
	urls[se] = {}
	for e = 1, ep[2] do
		local url = "https://www.zxzj.pro/video/" .. ep[1] .. "-1-" .. e .. ".html"
		url = getlink(url)
		urls[se][e] = url
	end
end

local se = 1
local e = 1
local function downloadNext()
	if not finish then
		return
	end
	local url = urls[se][e]
	local path = "/Volumes/Portyinya/bigbang/s" .. se .. "/" .. e .. ".mp4"
	download(url, path)
	if e < #urls[se] then
		e = e + 1
	else
		e = 1
		se = se + 1
	end
end
hs.g.bigbang = hs.timer.doEvery(1, downloadNext)
