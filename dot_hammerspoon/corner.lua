-- 设置触发角的屏幕位置
local screenWidth = hs.screen.mainScreen():frame().w
local screenHeight = hs.screen.mainScreen():frame().h

-- 定义热角的位置和自定义操作
local hotCorners = {
	topLeft = { x = 0, y = 0 },
	topRight = { x = screenWidth, y = 0 },
	bottomLeft = { x = 0, y = screenHeight },
	bottomRight = { x = screenWidth, y = screenHeight },
}

-- 定义当鼠标移动到某个角落时触发的操作
local function checkHotCorners()
	local mousePos = hs.mouse.absolutePosition()
	for corner, pos in pairs(hotCorners) do
		if math.abs(mousePos.x - pos.x) < 5 and math.abs(mousePos.y - pos.y) < 50 then
			if corner == "topLeft" then
				hs.alert(1)
			elseif corner == "topRight" then
			elseif corner == "bottomLeft" then
			elseif corner == "bottomRight" then
			end
		end
	end
end

-- 每秒检查鼠标位置
hs.g.corner_checker = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, checkHotCorners)
-- hs.g.corner_checker:start()
