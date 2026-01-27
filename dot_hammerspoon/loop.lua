local ring = require("ring")
local M = {}
M.running = false
-- 获取屏幕的分辨率
local function showframe(frame)
	M.canvas:delete()
	M.canvas = hs.canvas.new(M.screenFrame)
	M.canvas[1] = {
		type = "rectangle",
		action = "strokeAndFill",
		strokeWidth = 5,
		radius = 20,
		strokeColor = { red = 1, alpha = 1 },
		fillColor = { red = 0.3, green = 0.3, blue = 0.3, alpha = 0.5 },
		frame = { x = frame.x + 3, y = frame.y + 3, w = frame.w - 6, h = frame.h - 6 },
	}
	M.canvas:show()
end
M.rings = {
	{
		radius = 20,
		width = 20,
		color = { red = 0.7, green = 0.5, blue = 0.5, alpha = 0.7 },
		previewcolor = { red = 1, green = 0, blue = 0, alpha = 1 },
		trigDistance = { 10, 30 },
		terms = {
			{
				startAngle = -90,
				endAngle = 0,
				arcRadii = false,
			},
			{
				startAngle = 0,
				endAngle = 90,
				arcRadii = false,
				preview = function()
					showframe(M.screenFrame)
					return true
				end,
				callback = function()
					local window = hs.window.focusedWindow()
					return window:setFullScreen(true)
				end,
			},
			{
				startAngle = 90,
				endAngle = 180,
				arcRadii = false,
			},
			{
				startAngle = 180,
				endAngle = 270,
				arcRadii = false,
			},
		},
	},
	{
		radius = 55,
		width = 50,
		color = { red = 0.5, green = 0.7, blue = 0.5, alpha = 0.7 },
		previewcolor = { green = 1, alpha = 1 },
		trigDistance = { 30, 80 },
		terms = {},
	},
	{
		radius = 90,
		width = 20,
		color = { red = 0.5, green = 0.5, blue = 0.7, alpha = 0.7 },
		previewcolor = { blue = 1, alpha = 1 },
		trigDistance = { 80, 10000 },
		terms = {},
	},
}
for i = 1, 8 do
	M.rings[2].terms[i] = {
		startAngle = (-3.5 + i) * 45,
		endAngle = (-2.5 + i) * 45,
		arcRadii = false,
	}
end
for i = 1, 8 do
	M.rings[3].terms[i] = {
		startAngle = (-4 + i) * 45,
		endAngle = (-3 + i) * 45,
		arcRadii = false,
	}
end
function M.start()
	M.running = true
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
	if not M.canvas then
		M.canvas = hs.canvas.new(M.screenFrame)
	end
	M.canvas:show()
	M.canvas:level(100)
	ring:start({
		rings = M.rings,

		preview = function(i, j)
			if not i then
				M.canvas:hide()
				return true
			elseif M.frames[i] and M.frames[i][j] then
				showframe(M.frames[i][j])
				return true
			end
			return false
		end,
		callback = function(i, j)
			if M.frames[i] and M.frames[i][j] then
				local window = hs.window.focusedWindow()
				if window then
					window:setFullScreen(false)
					window:setFrame(M.frames[i][j]) -- 设置窗口为屏幕下半部分
					return true
				end
			end
			return false
		end,
	})
end

function M.stop(abort)
	M.running = false
	if M.canvas then
		M.canvas:delete()
	end
	M.cyclyCache = {}
	ring:stop(abort)
end

M.cyclyCache = {}
function M.forceChoose(i, j)
	if not M.running then
		M.start()
	end
	if type(i) == "table" then
		j = i[2]
		i = i[1]
	end
	ring:forceChoose(i, j)
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
	M.forceChoose(cyclyShortcuts[key][M.cyclyCache.number])
end
hs.loop = M
