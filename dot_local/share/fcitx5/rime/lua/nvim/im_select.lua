local ascii_mode
local lastdata = "i"
local function get_vim_mode(key, env)
	local pipe = io.popen("/opt/homebrew/bin/socat - /tmp/vimmode")
	local data = pipe:read("*l")
	if data ~= lastdata then
		lastdata = data
		if data ~= "i" then
			ascii_mode = env.engine.context:get_option("ascii_mode")
			if not ascii_mode then
				env.engine.context:set_option("ascii_mode", true)
				return 0
			end
		else
			env.engine.context:set_option("ascii_mode", false)
			if not env.engine.context.get_option("ascii_mode") then
				return 0
			end
			if not ascii_mode then
				env.engine.context:set_option("ascii_mode", false)
				return 0
			end
		end
	end
end
return get_vim_mode
