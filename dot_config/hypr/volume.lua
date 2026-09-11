local M = {}
function M.raise(step)
	hl.exec_cmd("~/.config/hypr/scripts/volume.sh output raise " .. tostring(step))
end
function M.lower(step)
	hl.exec_cmd("~/.config/hypr/scripts/volume.sh output lower " .. tostring(step))
end
local step = 1
local flag = false
hl.timer(function()
	if not flag then
		step = 1
	end
	flag = false
end, { type = "repeat", timeout = 100 })
function M.accelerate_raise()
	M.raise(step)
	if flag then
		step = step + 1
	end
	flag = true
end
function M.accelerate_lower()
	M.lower(step)
	if flag then
		step = step + 1
	end
	flag = true
end
return M
