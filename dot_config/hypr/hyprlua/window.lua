--# selene: allow(unused_variable)
---@diagnostic disable: unused-local
local util = require("util")
---@class hypr.window
local M = {}
M.__index = M
M.__concat = function(a, b)
	if type(a) == "table" then
		a = "address:" .. a.address
	end
	if type(b) == "table" then
		b = "address:" .. b.address
	end
	return a .. b
end
M.__tostring = function(a)
	return "address:" .. a.address
end
local function table2window(t)
	return setmetatable(t, M)
end
---@return hypr.window[]
function M.allWindows()
	local windows = util.get_data_from_hyprctl("clients")
	for index, value in ipairs(windows) do
		windows[index] = table2window(value)
	end
	return windows
end
---@return string
function M:application()
	return self.class
end
---@return hypr.window
function M:toggleFloat()
	return util.dispatch.togglefloating(self)
end
---@return boolean
function M:close()
	return util.dispatch.killwindow(self)
end
---@return hypr.workspace
function M:getWorkspace()
	return self.workspace.id
end
local function windowMeetHint(window, hint)
	if type(hint) == "table" then
		for key, value in pairs(hint) do
			if window[key] ~= value then
				return false
			end
		end
		return true
	else
		for key, value in pairs({ class = hint, title = hint }) do
			if string.match(window[key], value) then
				return true
			end
		end
		return false
	end
end
---@param hint string|table
---@return hypr.window?
function M.find(hint)
	local allwindow = M.allWindows()
	for index, value in ipairs(allwindow) do
		if windowMeetHint(value, hint) then
			return value
		end
	end
	return nil
end
---@return boolean
function M:focus()
	return util.dispatch.focuswindow("address:" .. self.address)
end
---@return hypr.window?
function M.focusedWindow()
	local win = util.get_data_from_hyprctl("activewindow")
	if win.address then
		return setmetatable(util.get_data_from_hyprctl("activewindow"), M)
	end
	return nil
end
---@return hypr.geometry
function M:frame()
	return { self.at[1], self.at[2], self.size[1], self.size[2] }
end
function M:id()
	return self.address
end
function M:isFullScreen()
	return self.fullscreen == 1
end
function M:isFloating()
	return self.floating
end

---@return boolean
function M:moveToWorkspace(workspace)
	return util.dispatch.movetoworkspace(workspace.id .. "," .. self)
end
local dist = {
	h = function(win2, win1)
		local x1, y1, w1, h1 = unpack(win1:frame())
		if not win2 then
			return -x1 - w1
		end
		local x2, y2, w2, h2 = unpack(win2:frame())
		return y1 + h1 > y2 and y1 < y2 + h2 and x1 + w1 < x2 and x2 - x1 - w1
	end,
	l = function(win2, win1)
		local x1, y1, w1, h1 = unpack(win1:frame())
		if not win2 then
			return x1
		end
		local x2, y2, w2, h2 = unpack(win2:frame())
		return y2 + h2 > y1 and y2 < y1 + h1 and x2 + w2 < x1 and x1 - x2 - w2
	end,
	k = function(win2, win1)
		local x1, y1, w1, h1 = unpack(win1:frame())
		if not win2 then
			return -y1 - h1
		end
		local x2, y2, w2, h2 = unpack(win2:frame())
		return x1 + w1 > x2 and x1 < x2 + w2 and y1 + h1 < y2 and y2 - y1 - h1
	end,
	j = function(win2, win1)
		local x1, y1, w1, h1 = unpack(win1:frame())
		if not win2 then
			return y1
		end
		local x2, y2, w2, h2 = unpack(win2:frame())
		return x2 + w2 > x1 and x2 < x1 + w1 and y2 + h2 < y1 and y1 - y2 - h2
	end,
}

local function ifMove(dir, win)
	local workspace, id
	if type(win) == "number" then
		workspace = win
		id = ""
		win = nil
	else
		workspace = win:getWorkspace()
		id = win:id()
	end
	local allwin = M.allWindows()
	local best = 99999
	local ret = nil
	for index, wwin in ipairs(allwin) do
		if wwin:getWorkspace() ~= workspace or wwin:id() == id then
		else
			local dis = dist[dir](win, wwin)
			if dis then
				if dis < best then
					best = dis
					ret = wwin
				elseif dis == best then
					if wwin.focusHistoryID < ret.focusHistoryID then
						ret = wwin
					end
				end
			end
		end
	end
	return ret
end

local moveWorkSpace = {
	h = function(w)
		return (w - 2) % 9 + 1
	end,
	l = function(w)
		return w % 9 + 1
	end,
	j = function(w)
		return (w + 2) % 9 + 1
	end,
	k = function(w)
		return (w + 5) % 9 + 1
	end,
}
function M.moveFocusCross(dir, opts)
	local win = M.focusedWindow()
	if win then
		local tar = ifMove(dir, win)
		if tar then
			return tar:focus()
		end
	end
	local workspace
	if win then
		workspace = win:getWorkspace()
	else
		workspace = util.get_data_from_hyprctl("activeworkspace").id
	end
	workspace = moveWorkSpace[dir](workspace)
	local tar = ifMove(dir, workspace)
	if tar then
		hypr.dispatch.workspace(tostring(workspace))
		return tar:focus()
	end
	return hypr.dispatch.workspace(tostring(workspace))
end

function M:gettitle()
	return self.title
end

function M.toggleFullScreen()
	return util.dispatch.fullscreen()
end
return M
