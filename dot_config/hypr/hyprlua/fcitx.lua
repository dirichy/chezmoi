local M = {}
local fcitx_remote = "fcitx5-remote"
M.active = function()
	hypr.cmd2({ fcitx_remote, "-o" }):await()
end
M.disable = function()
	hypr.cmd2({ fcitx_remote, "-c" }):await()
end
---@param callback nil if set, will run async and use callback for vim.system
---@return boolean
---@overload fun(callback:fun(boolean)):nil
function M.is_active(callback)
	if not callback then
		local output = hypr.cmd2(fcitx_remote):await().stdout or ""
		output = string.gsub(output, "%s", "")
		return output == "2"
	end
	hypr.cmd2(fcitx_remote, {
		callback = function(result)
			local output = result.stdout or ""
			output = string.gsub(output, "%s", "")
			callback(output == "2")
		end,
	})
end
return M
