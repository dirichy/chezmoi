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
	hypr.cmd2 = require("cmd").system
	hypr.dispatch = require("util").dispatch
	hypr.keyword = require("util").keyword
	hypr.debounce = require("util").debounce
	hypr.keybind = require("keybind")
	hypr.sunshine = require("sunshine")
	hypr.input = require("system.input")
	print("loading config")
	local e, r = pcall(require, "config")
	if e then
		print(e)
	end
	print("loaded config")
	uv.check_stop(check) -- 只执行一次
end)
require("ipcuv")
