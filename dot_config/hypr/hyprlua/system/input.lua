local uv = hypr.uv
local M = {}
local handle
local function wtype(str)
	hypr.cmd.wtype(str)
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
	handle = uv.spawn("zenity", {
		args = {
			"--entry",
			"--title='" .. title .. "'",
			"--text='" .. prompt .. "'",
		},
		stdio = { nil, stdout, nil },
	}, function(code, signal)
		uv.close(handle)
	end)
	local output = ""
	uv.read_start(stdout, function(err, data)
		if data then
			output = output .. data
		else
			output = output:sub(1, -2)
			if callback then
				callback(output)
			else
				wtype(output)
			end
			stdout:close()
		end
	end)
end
return M
