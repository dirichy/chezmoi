---@alias key string|integer
---@class fallbackmod
---@field mod integer?
---@field fallback integer
---@field virtual boolean?
---@alias mod string|string[]|integer|fallbackmod
---@alias to.key key
---@alias to.key_with_mod {[1]:key,[2]:mod}
---@alias to.shell SHELL
---@alias to to.key|to.key_with_mod|to.shell|HL.Dispatcher|function
---@alias condition function|string|string[]
---@class keybinder
---@field bind fun(key:key,mod:mod,fn:to,conditions:condition?,priority:integer?,opts:table?)
---@field createmod? fun(key:key,name:string,overload:to,conditions:condition?,fallback:integer?):mod
---@field modifier table<string,integer>
---@field feature {createmod?:boolean, physicalmod?:boolean, virtualmod?:boolean, fallbackmod?:boolean}?
if arg and arg[1] then
	return require("wmux.bind." .. arg[1])
end
if hl then
	---@type keybinder
	return require("wmux.bind.hyprland")
elseif hs then
	return require("wmux.bind.hammerspoon")
end
