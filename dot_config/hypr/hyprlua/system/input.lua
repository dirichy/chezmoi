local uv = hypr.uv
local M = {}
local handle
local function wtype(str)
	if handle then
		handle:kill()
		handle:close()
		handle = nil
	end
	local stdin = uv.new_pipe()
	handle = uv.spawn("wl-copy", {
		stdio = { stdin, nil, nil },
	}, function(code, signal)
		uv.close(handle)
		handle = nil
		local timer = uv.new_timer()
		hypr.keybind.sendkey("v", hypr.keybind.modifier.CTRL)
	end)
	stdin:write(str)
	stdin:close()
end
function M.prompt(title, prompt, callback)
	if handle then
		handle:kill()
		handle:close()
		handle = nil
	end
	title = title or "Hyprlua Input"
	prompt = prompt or "Please Input:"
	local stdout = uv.new_pipe(false)
	handle = uv.spawn("wofi", {
		args = {
			"--dmenu",
			"--width",
			"400",
			"--height",
			"50",
		},
		stdio = { nil, stdout, nil },
	}, function(code, signal)
		uv.close(handle)
		handle = nil
	end)
	local output = ""
	uv.read_start(stdout, function(err, data)
		if data then
			output = output .. data
		else
			output = output:sub(1, -2)
			stdout:close()
			if callback then
				return callback(output)
			else
				return wtype(output)
			end
		end
	end)
end
return M
