-- ;k 开始 / 结束击键统计，结果单位为次/秒；只计按下事件，不保存按键内容。
local M = {}

function M.init(env)
	env.recording = false
	env.press_count = 0
	env.started_at = 0
end

-- quick_input owns shortcut recognition and key guards.
function M.toggle(env)
	local now = rime_api.get_time_ms()
	if env.recording then
		local elapsed = math.max(now - env.started_at, 1)
		env.engine:commit_text("击键：" .. tostring(1000 * env.press_count / elapsed))
	else
		env.started_at = now
	end
	env.recording = not env.recording
	env.press_count = 0
	env.engine.context:clear()
	return 1
end

function M.observe(env)
	if env.recording then env.press_count = env.press_count + 1 end
end

return M
