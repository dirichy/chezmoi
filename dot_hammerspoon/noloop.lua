local M = {}
M.running = false
M.screen = hs.screen.mainScreen()
M.screenFrame = M.screen:frame()
M.frames = {
	[1] = {
		[1] = M.screenFrame,
		[3] = hs.geometry.rect({ M.screenFrame.w / 3, M.screenFrame.y, M.screenFrame.w / 3, M.screenFrame.h }),
		[4] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.h / 3, M.screenFrame.w, M.screenFrame.h / 3 }),
	},
	[2] = {
		[1] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.y, M.screenFrame.w / 2, M.screenFrame.h }),
		[2] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.y, M.screenFrame.w / 2, M.screenFrame.h / 2 }),
		[3] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.y, M.screenFrame.w, M.screenFrame.h / 2 }),
		[4] = hs.geometry.rect({ M.screenFrame.w / 2, M.screenFrame.y, M.screenFrame.w / 2, M.screenFrame.h / 2 }),
		[5] = hs.geometry.rect({ M.screenFrame.w / 2, M.screenFrame.y, M.screenFrame.w / 2, M.screenFrame.h }),
		[6] = hs.geometry.rect({
			M.screenFrame.w / 2,
			M.screenFrame.h / 2,
			M.screenFrame.w / 2,
			M.screenFrame.h / 2,
		}),
		[7] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.h / 2, M.screenFrame.w, M.screenFrame.h / 2 }),
		[8] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.h / 2, M.screenFrame.w / 2, M.screenFrame.h / 2 }),
	},
	[3] = {
		[1] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.y, M.screenFrame.w / 3, M.screenFrame.h }),
		[2] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.y, M.screenFrame.w * 2 / 3, M.screenFrame.h }),
		[3] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.y, M.screenFrame.w, M.screenFrame.h / 3 }),
		[4] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.y, M.screenFrame.w, M.screenFrame.h * 2 / 3 }),
		[5] = hs.geometry.rect({ M.screenFrame.w * 2 / 3, M.screenFrame.y, M.screenFrame.w / 3, M.screenFrame.h }),
		[6] = hs.geometry.rect({ M.screenFrame.w / 3, M.screenFrame.y, M.screenFrame.w * 2 / 3, M.screenFrame.h }),
		[7] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.h * 2 / 3, M.screenFrame.w, M.screenFrame.h / 3 }),
		[8] = hs.geometry.rect({ M.screenFrame.x, M.screenFrame.h / 3, M.screenFrame.w, M.screenFrame.h * 2 / 3 }),
	},
}
M.start = function()
	M.running = true
	M.cyclyCache = {}
end
M.callback = function(i, j)
	if M.frames[i] and M.frames[i][j] then
		local window = hs.window.focusedWindow()
		if window then
			window:setFullScreen(false)
			window:setFrame(M.frames[i][j]) -- 设置窗口为屏幕下半部分
			return true
		end
	end
end

function M.stop()
	M.running = false
end
local cyclyShortcuts = {
	left_arrow = { { 2, 1 }, { 3, 1 }, { 3, 2 } },
	up_arrow = { { 2, 3 }, { 3, 3 }, { 3, 4 } },
	right_arrow = { { 2, 5 }, { 3, 5 }, { 3, 6 } },
	down_arrow = { { 2, 7 }, { 3, 7 }, { 3, 8 } },
}
function M.cycly(key)
	if not M.cyclyCache.key then
		M.cyclyCache.key = key
		M.cyclyCache.number = 1
	elseif M.cyclyCache.key ~= key then
		M.cyclyCache.key = key
		M.cyclyCache.number = 1
	else
		M.cyclyCache.number = M.cyclyCache.number % #cyclyShortcuts[key] + 1
	end
	M.callback(cyclyShortcuts[key][M.cyclyCache.number])
end
hs.loop = M
