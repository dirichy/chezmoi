---@class SHELL
---@field cmd string
local SHELL = {}
SHELL.__index = SHELL
function SHELL.new(cmd)
	local res = { cmd = cmd }
	return setmetatable(res, SHELL)
end
---@type fun(a:SHELL,b:SHELL):SHELL
function SHELL.__bor(a, b)
	return SHELL.new("(" .. a.cmd .. ") || (" .. b.cmd .. ")")
end
---@type fun(a:SHELL,b:SHELL):SHELL
function SHELL.__band(a, b)
	return SHELL.new("(" .. a.cmd .. ") && (" .. b.cmd .. ")")
end
---@type fun(a:SHELL,b:SHELL):SHELL
function SHELL.__add(a, b)
	return SHELL.new("(" .. a.cmd .. ") ; (" .. b.cmd .. ")")
end
function SHELL:karabiner()
	return { shell_command = self.cmd }
end
function SHELL:hyprland()
	return hl.dsp.exec_cmd(self.cmd)
end
return SHELL
