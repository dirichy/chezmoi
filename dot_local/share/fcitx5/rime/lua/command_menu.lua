-- 功能入口与 / 符号菜单共用原生候选选择机制。
local M = {}

local function entries(env)
	local result = { { "s", "切换方案" }, { "o", "设置" } }
	local schema = env.engine.schema
	if (schema.schema_id == "tiger" or schema.schema_id == "tiger_full")
		and schema.config:get_bool("features/keystroke_stats") ~= false then
		result[#result + 1] = { "k", "击键统计" }
	end
	return result
end

local function prefix(env)
	return env.engine.schema.config:get_string("input_keys/command_prefix") or ";"
end

function M.func(input, segment, env)
	if input ~= prefix(env) then return end
	for _, entry in ipairs(entries(env)) do
		local candidate = Candidate("command_menu@" .. entry[1], segment.start, segment._end, entry[2], entry[1])
		candidate.quality = 100 -- 功能菜单排在原有标点候选前。
		yield(candidate)
	end
end

function M.action(candidate, env)
	local key = candidate.type:match("^command_menu@([a-z])$")
	if not key then return nil end
	for _, entry in ipairs(entries(env)) do
		if entry[1] == key then
			if key == "k" then return { command = key } end
			return { input = prefix(env) .. key }
		end
	end
end

return M
