local M = {}
---@param fn function
---@param delay integer? time in ms
---@param last boolean? if true, will wait first, and new call will override old call. else, will call first, then wait. new call will be droped.
---@return function
M.debounce = function(fn, delay, last)
	delay = delay or 200
	local timer = nil
	if last then
		local args = {}
		timer = hl.timer(function()
			timer:set_enabled(false)
			fn(table.unpack(args))
		end, { timeout = delay, type = "repeat" })
		return function(...)
			args = { ... }
			if timer:is_enabled() then
				-- timer:set_enabled(false)
				-- timer = nil
				return
			else
				-- fn(...)
				timer:set_enabled(true)
			end
		end
	else
		timer = hl.timer(function()
			timer:set_enabled(false)
		end, { timeout = delay, type = "repeat" })
		return function(...)
			-- args = { ... }
			if timer:is_enabled() then
				-- timer:set_enabled(false)
				-- timer = nil
				return
			else
				fn(...)
				timer:set_enabled(true)
			end
		end
	end
end
return M
