---@alias key string|integer
---@alias mod string|string[]|integer
---@alias to.key key
---@alias to.key_with_mod {[1]:key,[2]:mod}
---@alias to.shell SHELL
---@alias to to.key|to.key_with_mod|to.shell|HL.Dispatcher|function
---@class keybinder
---@field bind fun(key:key,mod:mod,fn:to,conditions:function?,priority:integer?,opts:table?)
---@field createmod fun(key:key,name:string,overload:to,conditions:function)
---@field modifier table<string,integer>
if hl then
	---@type keybinder
	return require("kmap.bind.hyprland")
end
