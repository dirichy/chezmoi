local M = {}

local function state_dir()
	local xdg_state = os.getenv("XDG_STATE_HOME")
	if xdg_state and xdg_state ~= "" then
		return xdg_state .. "/wmux"
	end
	local home = os.getenv("HOME")
	if home and home ~= "" then
		return home .. "/.local/state/wmux"
	end
	return nil
end

function M.warn(scope, message)
	local dir = state_dir()
	if not dir then
		return
	end
	os.execute("mkdir -p " .. string.format("%q", dir) .. " >/dev/null 2>&1")
	local file = io.open(dir .. "/warnings.log", "a")
	if not file then
		return
	end
	file:write(os.date("%Y-%m-%d %H:%M:%S"), " [", scope, "] ", message, "\n")
	file:close()
end

return M
