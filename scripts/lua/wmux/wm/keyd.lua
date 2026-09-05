local M = {}

local function noop()
	return function() end
end

function M.move_to_space(space)
	return noop()
end

function M.focus_window(dir)
	return noop()
end

function M.focus_space(dir)
	return noop()
end

function M.focus(dir)
	return noop()
end

function M.move_win_to_space(space)
	return noop()
end

function M.swap_win(dir)
	return noop()
end

function M.toggle_float(float)
	return noop()
end

function M.toggle_fullscreen(fullscreen)
	return noop()
end

function M.close_window()
	return noop()
end

function M.resize()
	return noop()
end

function M.get_active_window()
	return nil
end

function M.capture_screen(area)
	return noop()
end

function M.toggle_pin(pin)
	return noop()
end

function M.rotate_space()
	return noop()
end

return M
