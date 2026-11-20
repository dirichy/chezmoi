-- 只列出当前方案实际启用的普通开关，桌面和手机共用。
local M = {}
local labels = {
	ascii_mode = "中英文", ascii_punct = "标点", full_shape = "全半角",
	traditionalization = "简繁", emoji = "Emoji", pinyin = "读音", chaifen = "拆分",
	charset_comment_filter = "Unicode 分区", udpf_switch = "Unicode 编码",
	simp_hint = "简码提醒", simp_record = "简码统计", search_single_char = "单字优先",
}
local states = {
	ascii_mode = { "中文", "英文" }, ascii_punct = { "中文", "英文" },
	full_shape = { "半角", "全角" }, traditionalization = { "简体", "繁体" },
}

local function entries(env)
	local config, result = env.engine.schema.config, {}
	local switches = config:get_list("switches")
	if not switches then return result end
	for index = 0, switches.size - 1 do
		local path = "switches/@" .. index
		local name = config:get_string(path .. "/name")
		if name and name:sub(1, 1) ~= "_" then
			local enabled = env.engine.context:get_option(name)
			local current = enabled and 1 or 0
			local state
			if states[name] then
				state = states[name][current + 1]
			elseif labels[name] then
				state = enabled and "开" or "关"
			else
				state = config:get_string(path .. "/states/@" .. current) or (enabled and "开" or "关")
			end
			result[#result + 1] = { name = name, label = labels[name] or name,
				state = state, enabled = enabled }
		end
	end
	return result
end

function M.open(env)
	env.engine.context:push_input("o")
	return 1
end

function M.func(input, segment, env)
	local prefix = env.engine.schema.config:get_string("input_keys/command_prefix") or ";"
	if input ~= prefix .. "o" then return end
	for _, option in ipairs(entries(env)) do
		yield(Candidate("option_toggle@" .. option.name, segment.start, segment._end,
			option.label, option.state))
	end
end

function M.action(candidate, env)
	local name = candidate.type:match("^option_toggle@([A-Za-z][A-Za-z0-9_]*)$")
	if not name then return nil end
	for _, option in ipairs(entries(env)) do
		if option.name == name then return { option = name, value = not option.enabled } end
	end
end

return M
