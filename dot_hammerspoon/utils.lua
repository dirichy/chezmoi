local module = {}

function noop() end

function module.debounce(func, delay)
	local timer = nil

	return function(...)
		local args = { ... }

		if timer then
			timer:stop()
			timer = nil
		end

		timer = hs.timer.doAfter(delay, function()
			func(table.unpack(args))
		end)
	end
end

function module.throttle(func, delay)
	local wait = false
	local storedArgs = nil
	local timer = nil

	local function checkStoredArgs()
		if storedArgs == nil then
			wait = false
		else
			func(table.unpack(storedArgs))
			storedArgs = nil
			timer = hs.timer.doAfter(delay, checkStoredArgs)
		end
	end

	return function(...)
		local args = { ... }

		if wait then
			storedArgs = args
			return
		end

		func(table.unpack(args))
		wait = true
		timer = hs.timer.doAfter(delay, checkStoredArgs)
	end
end

function module.clamp(value, min, max)
	return math.max(math.min(value, max), min)
end

--- 过渡效果工具函数
-- @param options 参数配置
--   @field duration 过渡时长
--   @field easing 缓动函数，函数接受一个真实进度并返回缓动后的进度
--   @field onProgress 过渡时触发
--   @field onEnd 过渡结束后触发
-- @return 用于取消过渡的函数
function module.animate(options)
	local duration = options.duration
	local easing = options.easing
	local onProgress = options.onProgress
	local onEnd = options.onEnd or noop

	local st = hs.timer.absoluteTime()
	local timer = nil

	local function progress()
		local now = hs.timer.absoluteTime()
		local diffSec = (now - st) / 1000000000

		if diffSec <= duration then
			onProgress(easing(diffSec / duration))
			timer = hs.timer.doAfter(1 / 60, function()
				progress()
			end)
		else
			timer = nil
			onProgress(1)
			onEnd()
		end
	end

	-- 初始执行
	progress()

	return function()
		if timer then
			timer:stop()
			onEnd()
		end
	end
end

function module.bindHold(mods, key, func, opts)
	opts = opts or {}
	opts.delay = opts.delay or 1
	opts.alert = opts.alert or {}
	local storedTime = nil
	local timer = nil

	local function start()
		storedTime = hs.timer.secondsSinceEpoch()
		timer = hs.timer.doAfter(opts.delay, function()
			func()
			if opts.alert.done then
				hs.alert(opts.alert.done)
			end
		end)
		if opts.alert.start then
			hs.alert(opts.alert.start)
		end
	end
	local function stop()
		if hs.timer.secondsSinceEpoch() < storedTime + opts.delay then
			storedTime = nil
			if timer then
				timer:stop()
			end
			timer = nil
			if opts.alert.abort then
				hs.alert(opts.alert.abort)
			end
		end
	end
	hs.hotkey.bind(mods, key, start, stop)
end

function module.bindDoubleClick(mods, key, func, opts)
	opts = opts or {}
	opts.delay = opts.delay or 0.4
	local lastPressedTime = 0
	local function storeOrExcute()
		local curTime = hs.timer.secondsSinceEpoch()
		if curTime < lastPressedTime + 0.5 then
			func()
			lastPressedTime = 0
		else
			lastPressedTime = curTime
		end
	end
	hs.hotkey.bind(mods, key, storeOrExcute)
end

return module
