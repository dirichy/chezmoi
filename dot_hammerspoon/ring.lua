---@class ring.Chooser
---@field rings ring.Ring[]
---@field preview? function
---@field callback? function
---@class ring.Ring
---@field radius number
---@field width number
---@field color table
---@field previewcolor table
---@field preview? function[] | function
---@field callback? function
---@field trigDistance number[]
---@field terms ring.Term[]
---@class ring.Term
---@field startAngle number
---@field endAngle number
---@field arcRadii boolean
---@field preview function
---@field callback function

local M = {}
function M:forceChoose(i, j)
	self.choosed = { i, j }
	local ring = self.rings[i]
	local term = ring.terms[j]
	self.canvas[#self.rings + 1] = {
		type = "arc",
		action = "stroke", -- 边框模式
		startAngle = term.startAngle,
		endAngle = term.endAngle,
		strokeColor = ring.previewcolor,
		strokeWidth = ring.width, -- 设置圆弧宽度
		radius = ring.radius, -- 内层半径
		center = self.center, -- 圆心
		arcRadii = false, -- 禁用自定义弧半径
	}
	return self.chooser.preview and self.chooser.preview(i, j)
		or self.rings[i].preview and self.rings[i].preview(j)
		or self.rings[i].terms[j].preview and self.rings[i].terms[j].preview()
end
---@param chooser ring.Chooser
function M:start(chooser)
	if self.working then
		return
	end
	self.choosed = nil
	self.chooser = chooser
	local rings = chooser.rings
	self.working = true
	self.rings = rings
	self.canvasSize = 2 * (self.rings[#self.rings].width + self.rings[#self.rings].radius)
	self.center = { x = self.canvasSize / 2, y = self.canvasSize / 2 } -- 圆心在画布中心
	self.initialMousePosition = hs.mouse.absolutePosition()
	self.canvasPosition = {
		x = self.initialMousePosition.x - self.canvasSize / 2,
		y = self.initialMousePosition.y - self.canvasSize / 2,
	}
	self.canvas = hs.canvas.new({
		x = 0,
		y = 0,
		w = self.canvasSize,
		h = self.canvasSize,
	})
	local canvas = self.canvas
	for i, ring in ipairs(self.rings) do
		canvas[i] = {
			type = "circle",
			action = "stroke", -- 边框模式
			strokeColor = ring.color,
			strokeWidth = ring.width, -- 设置圆弧宽度
			radius = ring.radius, -- 内层半径
			center = self.center, -- 圆心
			arcRadii = false, -- 禁用自定义弧半径
		}
	end
	canvas:topLeft(self.canvasPosition)
	canvas:show()
	self.timer = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
		self:update()
	end)
	self.timer:start()
end
function M:preview(i, angle, execute)
	if not i then
		if self.canvas[#self.rings + 1] then
			self.canvas[#self.rings + 1] = nil
		end
		local ring = self.rings[1]
		return ring and ring.preview and ring.preview()
	end
	local ring = self.rings[i]
	for j, term in ipairs(ring.terms) do
		if (angle - term.startAngle) % 360 < term.endAngle - term.startAngle then
			if execute then
				return self.chooser.callback and self.chooser.callback(i, j)
					or ring.callback and ring.callback(j, angle)
					or term.callback and term.callback()
			else
				self.canvas[#self.rings + 1] = {
					type = "arc",
					action = "stroke", -- 边框模式
					startAngle = term.startAngle,
					endAngle = term.endAngle,
					strokeColor = ring.previewcolor,
					strokeWidth = ring.width, -- 设置圆弧宽度
					radius = ring.radius, -- 内层半径
					center = self.center, -- 圆心
					arcRadii = false, -- 禁用自定义弧半径
				}
				self.choosed = { i, j }
				return self.chooser.preview and self.chooser.preview(i, j)
					or ring.preview and ring.preview(j, angle)
					or term.preview and term.preview()
			end
		end
	end
end
function M:delete()
	self.rings = nil
	self.chooser = nil
	self.canvas:delete()
	if self.timer then
		self.timer:stop()
		self.timer = nil
	end
	self.choosed = nil
end
function M:stop(abort)
	if not self.working then
		return
	end
	self.working = false
	local result = nil
	if not abort then
		if self.choosed then
			local i = self.choosed[1]
			local j = self.choosed[2]
			result = self.chooser.callback and self.chooser.callback(i, j)
				or self.rings[i].callback and self.rings[i].callback(j)
				or self.rings[i].terms[j].callback and self.rings[i].terms[j].callback()
		end
	end
	M:delete()
	return result
end
function M:update()
	local mousePosition = hs.mouse.absolutePosition()

	-- 计算鼠标相对于圆心的角度
	local canvasCenter = {
		x = self.canvasPosition.x + self.canvasSize / 2,
		y = self.canvasPosition.y + self.canvasSize / 2,
	}
	local dx = mousePosition.x - canvasCenter.x
	local dy = mousePosition.y - canvasCenter.y
	local angle = math.deg(math.atan2(dy, dx))

	-- 调整角度偏移，修正屏幕坐标系
	angle = angle + 90

	-- 使用 mod 360 来保证角度在 [0, 360) 之间
	angle = angle % 360

	-- 计算鼠标到圆心的距离
	local distanceFromCenter = math.sqrt(dx ^ 2 + dy ^ 2)
	-- 根据距离决定是内层还是外层的圆弧变红
	if not self.rings then
		return
	end
	if distanceFromCenter < self.rings[1].trigDistance[1] then
		self:preview()
	end
	for i, ring in ipairs(self.rings) do
		if distanceFromCenter > ring.trigDistance[1] and distanceFromCenter <= ring.trigDistance[2] then
			self:preview(i, angle)
		end
	end
end

return M
