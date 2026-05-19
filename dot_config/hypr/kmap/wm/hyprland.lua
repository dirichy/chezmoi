local hypr = {}
function hypr.space(space)
	return hl.dsp.focus({ workspace = space, on_current_monitor = true })
end
local dir_table = {
	h = "left",
	j = "down",
	k = "up",
	l = "right",
}
local function wrap_dsp(...)
	local dsps = { ... }
	return function()
		for _, dsp in ipairs(dsps) do
			local result = hl.dispatch(dsp)
			-- hl.notification.create({ text = tostring(result.ok), duration = 5000 })
			if result.ok then
				return result.ok
			end
		end
		return false
	end
end

local dist = {
	h = function(win2, win1)
		local x1, y1, w1, h1 = win1.at.x, win1.at.y, win1.size.x, win1.size.y
		if not win2 then
			return -x1 - w1
		end
		local x2, y2, w2, h2 = win2.at.x, win2.at.y, win2.size.x, win2.size.y
		return y1 + h1 > y2 and y1 < y2 + h2 and x1 + w1 < x2 and x2 - x1 - w1
	end,
	l = function(win2, win1)
		local x1, y1, w1, h1 = win1.at.x, win1.at.y, win1.size.x, win1.size.y
		if not win2 then
			return x1
		end
		local x2, y2, w2, h2 = win2.at.x, win2.at.y, win2.size.x, win2.size.y
		return y2 + h2 > y1 and y2 < y1 + h1 and x2 + w2 < x1 and x1 - x2 - w2
	end,
	k = function(win2, win1)
		local x1, y1, w1, h1 = win1.at.x, win1.at.y, win1.size.x, win1.size.y
		if not win2 then
			return -y1 - h1
		end
		local x2, y2, w2, h2 = win2.at.x, win2.at.y, win2.size.x, win2.size.y
		return x1 + w1 > x2 and x1 < x2 + w2 and y1 + h1 < y2 and y2 - y1 - h1
	end,
	j = function(win2, win1)
		local x1, y1, w1, h1 = win1.at.x, win1.at.y, win1.size.x, win1.size.y
		if not win2 then
			return y1
		end
		local x2, y2, w2, h2 = win2.at.x, win2.at.y, win2.size.x, win2.size.y
		return x2 + w2 > x1 and x2 < x1 + w1 and y2 + h2 < y1 and y1 - y2 - h2
	end,
}
function hypr.focus_window(dir)
	return function()
		local win = hl.get_active_window()
		if not win then
			return
		end
		local space = hl.get_active_workspace()
		local allwin = hl.get_workspace_windows(space)
		local best = 99999
		local ret = nil
		for index, wwin in ipairs(allwin) do
			if wwin.pid ~= win.pid then
				local dis = dist[dir](win, wwin)
				if dis then
					if dis < best then
						best = dis
						ret = wwin
					elseif dis == best then
						if wwin.focus_history_id < ret.focus_history_id then
							ret = wwin
						end
					end
				end
			end
		end
		if ret then
			return hl.dispatch(hl.dsp.focus({ direction = dir_table[dir] or dir }))
		else
			return false
		end
	end
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
function hypr.focus_space(dir)
	return function()
		local space = hl.get_active_workspace()
		if not space then
			return
		end
		local id = space.id
		hl.dispatch(hl.dsp.focus({ workspace = moveWorkSpace[dir](id) }))
		return not id == hl.get_active_workspace().id
	end
end
hypr.focus = function(dir)
	local fw = hypr.focus_window(dir)
	local fs = hypr.focus_space(dir)
	return function()
		return fw() or fs()
	end
end
function hypr.move_win_to_space(space)
	return wrap_dsp(hl.dsp.window.move({ workspace = space, follow = true }))
end
function hypr.swap_window(dir)
	return wrap_dsp(hl.dsp.window.swap({ direction = dir_table[dir] or dir }))
end
function hypr.toggle_float(float)
	if float == nil then
		return wrap_dsp(hl.dsp.window.float())
	else
		return wrap_dsp(hl.dsp.window.float({ action = float and "set" or "unset" }))
	end
end
function hypr.toggle_fullscreen(fullscreen)
	if fullscreen == nil then
		return wrap_dsp(hl.dsp.window.fullscreen())
	else
		return wrap_dsp(hl.dsp.window.fullscreen({ action = fullscreen and "set" or "unset" }))
	end
end
function hypr.close_window(win)
	return wrap_dsp(hl.dsp.window.close())
end
function hypr.resize(win)
	return wrap_dsp(hl.dsp.window.resize())
end
hypr.get_active_window = hl.get_active_window
return hypr
