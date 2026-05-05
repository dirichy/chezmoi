local util = require("util")
local json = hypr.json
local uv = hypr.uv
local M = {}
M.qq = {}

M.qq.active = function()
	uv.spawn("/home/dirichy/.local/bin/qq", { detached = true })
end

M.wechat = {}
M.wechat.active = function()
	uv.spawn("/usr/bin/wechat-universal", { detached = true })
end
return M
