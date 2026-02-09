#!/usr/bin/luajit
hypr = {}
hypr.json = require("cjson")
local uv = require("luv")
hypr.uv = uv
local check = uv.new_check()
uv.check_start(check, function()
	print("Executed right after uv.run starts")
	hypr.window = require("window")
	hypr.monitor = require("system.monitor")
	hypr.event = require("event")
	hypr.cmd = require("util").cmd
	hypr.dispatch = require("util").dispatch
	hypr.keyword = require("util").keyword
	hypr.debounce = require("util").debounce
	hypr.keybind = require("keybind")
	pcall(require, "config")
	uv.check_stop(check) -- 只执行一次
end)
require("ipcuv")
