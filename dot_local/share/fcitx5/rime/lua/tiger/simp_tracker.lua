-- 虎码简码练习：只记录单字编码差异，不记录句子、应用或剪贴板。
local M = {}
local short_codes = require("tiger.simp_table")
local stores = {}
local platform

local function store(env)
	local directory = rime_api.get_user_data_dir()
	local path = directory .. "/tiger-simp-stats.tsv"
	if stores[path] then return stores[path] end
	local data = { path = path, entries = {}, write_failed = false }
	local file = io.open(path, "r")
	if file then
		for line in file:lines() do
			local char, actual, short, extra = line:match("^([^\t]+)\t([a-z]+)\t([a-z]+)\t(%d+)\t%d+$")
			if char and tonumber(extra) == #actual - #short and #actual > #short then
				local key = char .. "\t" .. actual .. "\t" .. short
				local entry = data.entries[key] or { char = char, actual = actual, short = short, count = 0, extra = 0 }
				entry.count = entry.count + 1
				entry.extra = entry.extra + tonumber(extra)
				data.entries[key] = entry
			end
		end
		file:close()
	end
	stores[path] = data
	return data
end

local function quote(text)
	return "'" .. text:gsub("'", "'\\''") .. "'"
end

local function notify(char, actual, short)
	if platform == nil then
		local process = io.popen("uname -s 2>/dev/null", "r")
		platform = process and process:read("l") or ""
		if process then process:close() end
	end
	local text = char .. "：" .. actual .. " → " .. short
	if platform == "Linux" then
		os.execute("(command -v notify-send >/dev/null 2>&1 && notify-send -- "
			.. quote("虎码简码") .. " " .. quote(text) .. ") >/dev/null 2>&1 &")
	elseif platform == "Darwin" then
		local script = 'display notification "' .. text:gsub('"', '\\"') .. '" with title "虎码简码"'
		os.execute("(command -v osascript >/dev/null 2>&1 && osascript -e "
			.. quote(script) .. ") >/dev/null 2>&1 &")
	end
end

local function record(env, char, actual)
	local short = short_codes[char]
	if not short or #actual <= #short then return end
	local context = env.engine.context
	if context:get_option("simp_record") then
		local data = store(env)
		local key = char .. "\t" .. actual .. "\t" .. short
		local entry = data.entries[key] or { char = char, actual = actual, short = short, count = 0, extra = 0 }
		entry.count = entry.count + 1
		entry.extra = entry.extra + #actual - #short
		data.entries[key] = entry
		local file = io.open(data.path, "a")
		if file then
			local written = file:write(key, "\t", tostring(#actual - #short), "\t", tostring(os.time()), "\n")
			local closed = file:close()
			if not written or not closed then data.write_failed = true end
		else
			data.write_failed = true
		end
	end
	if context:get_option("simp_hint") then notify(char, actual, short) end
end

-- 手动上屏不经过 context 的 commit_notifier，字面空码清理时，逐个有效分段调用此公共入口。
function M.observe(env, text, input)
	if not text or not input or not input:match("^[a-z]+$") then return end
	local length = utf8.len(text)
	if not length or length ~= math.ceil(#input / 4) then return end
	-- fixed4segmentor 按四码分段；无法一一对应的自定义词或反查不猜测编码。
	local index = 0
	for _, codepoint in utf8.codes(text) do
		local actual = input:sub(index * 4 + 1, index * 4 + 4)
		record(env, utf8.char(codepoint), actual)
		index = index + 1
	end
end

function M.summary(env)
	local data = store(env)
	local entries = {}
	for _, entry in pairs(data.entries) do entries[#entries + 1] = entry end
	table.sort(entries, function(a, b)
		if a.count ~= b.count then return a.count > b.count end
		if a.extra ~= b.extra then return a.extra > b.extra end
		return a.char .. a.actual < b.char .. b.actual
	end)
	return entries, data.write_failed
end

function M.init(env)
	env.simp_connection = env.engine.context.commit_notifier:connect(function(context)
		M.observe(env, context:get_commit_text(), context.input)
	end)
end

function M.fini(env)
	if env.simp_connection then env.simp_connection:disconnect() end
end

function M.func() return 2 end

return M
