-- / 的每一级都追加子项键；符号数据与独立短入口共用 symbols.yaml。
local date_commands = require("date_commands")
local M = {}

-- { 下一键, 显示名称, 数据键或子菜单, 英文检索词（可选） }；大小写分别用于小写 / 大写变体。
local groups = {
	{ "a", "箭头", "jt", "arrows" },
	{ "m", "数学与数字", {
		{ "s", "数学符号", "sx", "math mathematics" }, { "f", "分数", "fs", "fractions" },
		{ "u", "上标", "sb", "superscript" }, { "d", "下标", "xb", "subscript" },
		{ "r", "罗马数字", "lm", "roman numerals" }, { "R", "大写罗马数字", "lmd", "roman uppercase" },
		{ "n", "数字", "numbers", "numbers digits" },
		{ "l", "字母序号", { { "c", "圆圈字母", "zmq", "circled letters" }, { "b", "括号字母", "zmh", "parenthesized letters" } } },
		{ "g", "几何与图形", { { "s", "星形", "xh", "stars" }, { "b", "方块", "fk", "blocks" }, { "g", "几何图形", "jh", "geometry shapes" } } },
		{ "o", "除号", "chu", "division" }, { "t", "正字计数", "zz", "tally counting" }, { "T", "正字计数（别名）", "zzjs", "tally counting alias" },
		{ "p", "圆周率", "pi", "pi" }, { "P", "圆周率变体", "pai", "pi variant" }, { "a", "角度", "du", "degrees temperature" },
	} },
	{ "l", "字母与语言", {
		{ "g", "希腊字母", "xl", "greek" }, { "G", "大写希腊字母", "xld", "greek uppercase" },
		{ "r", "俄文字母", "ey", "russian cyrillic" }, { "R", "大写俄文字母", "eyd", "russian uppercase cyrillic" },
		{ "p", "拼音", "py", "pinyin" }, { "P", "大写拼音", "pyd", "pinyin uppercase" }, { "z", "注音", "zy", "bopomofo zhuyin" },
		{ "t", "声调", "sd", "tone marks" },
		{ "j", "日语", { { "h", "平假名", "jm", "hiragana" }, { "k", "片假名", "pjm", "katakana" }, { "i", "伊吕波", "iro", "iroha" },
			{ "c", "圈号假名", "jmq", "circled kana" }, { "w", "半角片假名", "jmbj", "halfwidth katakana" }, { "s", "假名行与段", {} },
		} },
		{ "k", "韩文", { { "a", "韩文", "hw", "korean hangul" }, { "c", "圈号韩文", "hwq", "circled hangul" }, { "b", "括号韩文", "hwh", "parenthesized hangul" } } },
		{ "v", "拉丁字母变体", {} },
	} },
	{ "e", "表情与国旗", {
		{ "f", "表情", "bq", "emoji faces" }, { "p", "人物", "bqrw", "people" }, { "h", "手势", "bqsj", "hands gestures" },
		{ "l", "爱心", "bqax", "hearts love" }, { "c", "服饰", "bqfs", "clothing" }, { "s", "标志", "bqbz", "signs" },
		{ "y", "符号", "bqfh", "symbols" }, { "o", "食物", "bqsw", "food" }, { "e", "节日", "bqjr", "celebrations holidays" },
		{ "b", "运动", "bqyd", "sports" }, { "a", "动物", "bqdw", "animals" }, { "v", "植物", "bqzw", "plants" },
		{ "u", "房屋", "bqfw", "buildings houses" }, { "i", "家具", "bqjj", "furniture" }, { "t", "时间", "bqsjt", "clocks time" },
		{ "n", "自然", "bqzr", "nature weather" }, { "r", "果蔬", "bqgs", "fruit vegetables" }, { "g", "国旗（英文首字母）", {} },
		{ "F", "旗帜", "flags", "flags pennant" },
	} },
	{ "g", "棋牌与运动", {
		{ "p", "扑克", "pk", "poker cards" }, { "m", "麻将", "mj", "mahjong" }, { "d", "骰子", "sz", "dice" },
		{ "j", "将棋", "shogi", "shogi japanese chess" }, { "C", "跳棋", "checkers", "checkers draughts" },
		{ "s", "运动", "sports", "sports football baseball skiing skating" },
		{ "c", "国际象棋", "gjxq", "chess" }, { "x", "象棋", "xq", "chinese chess" }, { "z", "中国象棋", "zgxq", "chinese chess" },
	} },
	{ "n", "自然与传统", {
		{ "w", "天气", "tq", "weather" }, { "m", "音乐", "yy", "music" }, { "s", "两性", "lx", "gender" },
		{ "b", "八卦", "bg", "bagua trigrams" }, { "B", "八卦名称", "bgm", "bagua names" },
		{ "h", "六十四卦", "lssg", "hexagrams" }, { "H", "六十四卦名称", "lssgm", "hexagram names" },
		{ "y", "太玄经", "txj", "taixuanjing" }, { "a", "天文", "tt", "astronomy planets aspects" }, { "z", "星座", "xz", "zodiac" },
		{ "Z", "星座名称", "xzm", "zodiac names" }, { "c", "十二宫", "seg", "zodiac houses" },
		{ "t", "天干", "tg", "heavenly stems" }, { "e", "地支", "dz", "earthly branches" }, { "g", "干支", "gz", "sexagenary cycle" }, { "q", "节气", "jq", "solar terms" },
		{ "r", "宗教", "religion", "religion faith cross church shrine" }, { "l", "地点", "places", "places landmark castle mountain camping" },
	} },
	{ "w", "标点与文字", {
		{ "b", "括号", "kh", "brackets parentheses" }, { "p", "标点", "bd", "punctuation" }, { "P", "中文标点", "bdz", "vertical punctuation" },
		{ "v", "竖排标点", "bdt", "question exclamation" }, { "r", "康熙部首", "kx", "kangxi radicals" }, { "R", "部首补充", "zkx", "radicals supplement" },
		{ "s", "笔画", "bh", "strokes" }, { "c", "圈号汉字", "hzq", "circled chinese" }, { "C", "括号汉字", "hzh", "parenthesized chinese" },
		{ "d", "日期符号", "rq", "date symbols" }, { "m", "月份符号", "yf", "month symbols" }, { "t", "时钟符号", "sj", "hour symbols" },
		{ "z", "零宽字符", "lkkg", "zero width spaces" }, { "i", "制表符", "tab", "tab whitespace" }, { "a", "星号", "zxh", "asterisks" },
		{ "h", "井号", "zjh", "hash" }, { "e", "重复号", "zdh", "ditto repeat" }, { "o", "艾特", "zat", "at copyright" },
		{ "w", "曜日", "yr", "weekday symbols" }, { "j", "汉字结构", "jg", "ideographic structure" }, { "f", "偏旁", "pp", "radicals components" },
		{ "l", "版权注册", "copyright", "copyright registered phonogram" },
		{ "M", "商标", "tm", "trademark" }, { "S", "服务商标", "sm", "service mark" },
	} },
	{ "c", "货币", "hb", "currency money" },
	{ "u", "单位", "dw", "units" },
	{ "k", "键盘符号", "dn", "keyboard computer" },
	{ "v", "勾叉", {
		{ "c", "对号", "dui", "check tick" }, { "x", "错号", "cuo", "cross wrong" }, { "b", "复选框", "checkbox", "checkbox ballot box" },
	} },
	{ "p", "电话传真", "telephone", "telephone phone fax" },
	{ "r", "回收", "recycling", "recycle recycling plastic paper" },
	{ "j", "交通", "transport", "transport traffic road vehicle ferry boat fuel" },
	{ "i", "工具", "tools", "tools instruments gear mining chains" },
	{ "s", "科学", "science", "science atom chemistry laboratory" },
	{ "h", "安全健康", {
		{ "w", "警告", "warning", "warning hazard danger radiation biohazard voltage" },
		{ "m", "医疗", "medical", "medical medicine hospital rescue" },
		{ "a", "无障碍", "accessibility", "accessibility wheelchair disability" },
	} },
	{ "q", "私人短语", {}, "phrases snippets personal" },
}

-- 分组的检索词；叶条目也可直接用第四项自行配置。
local group_keywords = {
	["勾叉"] = "check cross verification", ["安全健康"] = "safety health", ["数学与数字"] = "math numbers", ["字母与语言"] = "languages letters",
	["表情与国旗"] = "emoji flags", ["棋牌与运动"] = "games sports", ["自然与传统"] = "nature tradition",
	["标点与文字"] = "writing punctuation", ["字母序号"] = "letter numbering", ["几何与图形"] = "geometry shapes",
	["日语"] = "japanese", ["韩文"] = "korean", ["拉丁字母变体"] = "latin alphabet",
	["假名行与段"] = "kana syllables", ["国旗（英文首字母）"] = "flags countries",
}
local command_info = {
	date = { "日期", "date" }, dateen = { "英文日期", "date english" },
	datezh = { "中文日期", "date chinese" }, datetime = { "日期时间", "datetime" },
	week = { "星期", "weekday week" }, month = { "月份", "month" },
	time = { "时间", "time" }, timestamp = { "时间戳", "timestamp unix epoch" },
}

local short_aliases = { jt = "/jt", sx = "/sx", fs = "/fs", kh = "/b", bd = "/bd", hb = "/hb",
	dw = "/u", bq = "/bq", tq = "/tq", yy = "/yy", pk = "/pk", mj = "/mj", sz = "/sz" }
local latin = "aa AA ae AE ao AO au AU av AV ay AY db ff ffi ffl fi fl fn hv HV ij IJ lj ll LL ls lz nj Nj NJ oe OE oi OI oo OO ou OU qp Rx tc th ts tz TZ ue vy VY ww"
-- 菜单只显示一个数字总项；逐个数字由 /0 到 /10 直接进入。
local combined_sources = {
	numbers = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "szq", "szh", "szd", "szm" },
}

local function values(config, source)
	if combined_sources[source] then
		local result, seen = {}, {}
		for _, part in ipairs(combined_sources[source]) do
			for _, text in ipairs(values(config, part)) do
				if not seen[text] then result[#result + 1], seen[text] = text, true end
			end
		end
		return result
	end
	local path = "punctuator/symbols/symbol_" .. source
	local list, result = config:get_list(path), {}
	if list then
		for index = 0, list.size - 1 do result[#result + 1] = list:get_value_at(index).value end
	else
		local text = config:get_string(path)
		if text then result[1] = text end
	end
	return result
end

function M.init(env)
	env.symbol_nodes, env.symbol_prefixes, env.symbol_search = {}, {}, {}
	env.symbol_aliases = {}
	local config = env.engine.schema.config
	local map = config:get_map("punctuator/symbols")
	if not map then return end
	local sources, names = {}, {}
	for _, code in ipairs(map:keys()) do
		if code:sub(1, 7) == "symbol_" then sources[#sources + 1] = code:sub(8) end
		if code:sub(1, 1) == "/" then
			for length = 1, #code do env.symbol_prefixes[code:sub(1, length)] = true end
		end
	end
	table.sort(sources)
	-- 每次初始化构造新树，避免不同方案 / 组件实例共享可变菜单。
	local function build(code, definitions, parent)
		local node = env.symbol_nodes[code] or { code = code, parent = parent, children = {} }
		env.symbol_nodes[code] = node
		for _, definition in ipairs(definitions) do
			local key, name, data = table.unpack(definition)
			local child_code = code .. key
			local child
			if type(data) == "table" and data.phrases then
				child = { code = child_code, parent = code, phrases = data.phrases }
				env.symbol_nodes[child_code] = child
			elseif type(data) == "table" then
				child = build(child_code, data, code)
			else
				child = { code = child_code, parent = code, source = data, values = values(config, data) }
				env.symbol_nodes[child_code] = child
				names[data] = name
				for _, part in ipairs(combined_sources[data] or {}) do names[part] = name end
			end
			child.key, child.name = key, name
			child.keywords = definition[4] or group_keywords[name] or ""
			node.children[#node.children + 1] = child
			for length = 1, #child_code do env.symbol_prefixes[child_code:sub(1, length)] = true end
		end
		return node
	end
	build("/", groups)
	local variants, flags, kana = {}, {}, {}
	for _, source in ipairs(sources) do
		local data = values(config, source)
		local name = names[source] or table.concat(data, " ", 1, math.min(#data, 3))
		local key = source:match("^v([acglmnet])$") or source
		if source:match("^[A-Za-z]$") or source:match("^v[acglmnet]$") or (" " .. latin .. " "):find(" " .. source .. " ", 1, true) then
			variants[#variants + 1] = { key, name, source, "latin " .. key }
		end
		if source:match("^gq[a-z]$") then flags[#flags + 1] = { source:sub(3), name, source, "flag " .. source:sub(3) } end
		local syllable = source:match("^jm([kgsztdnhbpmyrwaiueo])$")
		if syllable then
			local vowel = syllable:match("[aiueo]")
			kana[#kana + 1] = { syllable, syllable .. (vowel and " 段" or " 行") .. " · " .. name, source, "japanese kana " .. syllable }
		end
	end
	-- 用完整构造函数补上动态分组，并保留父菜单中的同一个节点引用。
	local function fill(code, definitions)
		local existing = env.symbol_nodes[code]
		local populated = build(code, definitions, existing.parent)
		existing.children = populated.children
		env.symbol_nodes[code] = existing
	end
	fill("/lv", variants)
	fill("/eg", flags)
	fill("/ljs", kana)
	fill("/q", require("quick_phrases").definitions())
	-- 没有归入上面分类的数据直接列在总菜单末尾，用预览说明内容。
	local remaining = {}
	for _, source in ipairs(sources) do
		if not names[source] then
			local data = values(config, source)
			local preview = table.concat(data, " ", 1, math.min(#data, 3))
			local key = source
			local keywords = ""
			if source == "fh" then
				key, keywords = "o", "other miscellaneous symbols"
				preview = preview .. " …"
			elseif env.symbol_prefixes["/" .. key:sub(1, 1)] then
				key = key:upper()
			end
			remaining[#remaining + 1] = { key, preview, source, keywords }
		end
	end
	-- 日期工具与符号共用检索目录；实际内容仍由 date_translator 生成。
	for code, kind in pairs(date_commands) do
		local info = command_info[kind]
		local node = { code = code, name = info[1], keywords = info[2], command = true,
			parent = #code == 2 and "/" or code:sub(1, 2) }
		env.symbol_nodes[code] = node
	end
	for _, code in ipairs({ "/d", "/t" }) do
		local node = env.symbol_nodes[code]
		env.symbol_nodes["/"].children[#env.symbol_nodes["/"].children + 1] = node
	end
	build("/", remaining)
	-- 精确短入口也由本模块生成高优先级候选，避免模糊结果盖过原生符号。
	for alias, source in pairs(short_aliases) do
		env.symbol_aliases[source] = { values = values(config, alias), name = names[alias] or alias, source = alias }
	end
	for number = 0, 10 do
		local source = tostring(number)
		env.symbol_aliases["/" .. source] = { values = values(config, source), name = "数字 " .. source, source = source }
	end
	for code, node in pairs(env.symbol_nodes) do
		if code ~= "/" then env.symbol_search[#env.symbol_search + 1] = node end
	end
	table.sort(env.symbol_search, function(a, b) return a.code < b.code end)
end

local function entries(input, env)
	local node = env.symbol_nodes[input]
	if node then
		if node.command then
			local children = {}
			for _, entry in ipairs(env.symbol_search or {}) do
				if entry.command and entry.parent == input then children[#children + 1] = entry end
			end
			return children, node
		end
		return node.children, node
	end
	if input:sub(1, 1) ~= "/" then return nil end
	-- 多字母子项输入到一半时，仍提示当前层中匹配的下一项。
	for length = #input - 1, 1, -1 do
		local parent = env.symbol_nodes[input:sub(1, length)]
		if parent and parent.children then
			local matches = {}
			for _, child in ipairs(parent.children) do
				if child.code:sub(1, #input) == input then matches[#matches + 1] = child end
			end
			if #matches > 0 then return matches end
		end
	end
end

-- 分数越小越好：完整词、前缀、子序列；连续匹配及较短结果优先。
local function fuzzy_score(query, text)
	text = text:lower()
	if text == query then return 0 end
	if (" " .. text .. " "):find(" " .. query .. " ", 1, true) then return 1 end
	if text:sub(1, #query) == query then return 10 + (#text - #query) / 100 end
	local position, first, gaps = 0, nil, 0
	for index = 1, #query do
		local found = text:find(query:sub(index, index), position + 1, true)
		if not found then return nil end
		if first then gaps = gaps + found - position - 1 else first = found end
		position = found
	end
	return 100 + first * 2 + gaps * 3 + #text / 100
end

local function fuzzy_entries(input, env, exact, direct)
	local query = input:match("^/([A-Za-z]+)$")
	if not query then return {} end
	query = query:lower()
	local seen, matches = {}, {}
	if direct and direct.source then seen[direct.source] = true end
	for _, entry in ipairs(exact or {}) do seen[entry.source or entry.code] = true end
	for _, entry in ipairs(env.symbol_search or {}) do
		if entry.code ~= input then
			local path_score = fuzzy_score(query, entry.code:sub(2))
			local word_score = fuzzy_score(query, entry.keywords or "")
			local score = math.min(path_score or math.huge, word_score or math.huge)
			if score < math.huge then matches[#matches + 1] = { entry = entry, score = score } end
		end
	end
	table.sort(matches, function(a, b)
		if a.score ~= b.score then return a.score < b.score end
		if #a.entry.code ~= #b.entry.code then return #a.entry.code < #b.entry.code end
		local left, right = a.entry.code:lower(), b.entry.code:lower()
		if left ~= right then return left < right end
		if (a.entry.code == left) ~= (b.entry.code == right) then return a.entry.code == left end
		return a.entry.code < b.entry.code
	end)
	local result = {}
	for _, match in ipairs(matches) do
		local entry = match.entry
		local identity = entry.source or entry.code
		if not seen[identity] then result[#result + 1], seen[identity] = entry, true end
	end
	return result
end

function M.handle_key(key, env)
	local context = env.engine.context
	if context.input:sub(1, 1) ~= "/" then return 2 end
	-- 私人条目路径可含目录、数字、下划线及连字符；命中已知路径时才续写。
	if context.input:match("^/q[A-Za-z0-9_/-]*$") and key.keycode >= 0x20 and key.keycode < 0x7f then
		local char = string.char(key.keycode)
		local direct = env.symbol_nodes[context.input]
		if char:match("^[/0-9_-]$") and (not direct or not direct.phrases)
			and env.symbol_prefixes[context.input .. char] then
			context:push_input(char)
			return 1
		end
	end
	local node = env.symbol_nodes[context.input]
	if key.keycode == 0xff08 and node and node.parent then
		context.input = node.parent
		return 1
	end
	return 2
end

-- 候选只描述目标；单值上屏和多级导航共用同一个选择事件执行路径。
function M.action(candidate, env)
	local code = candidate.type:match("^symbol_menu(/[A-Za-z0-9_/-]+)$")
	local target = code and env.symbol_nodes[code]
	if not target then return nil end
	if target.phrases and #target.phrases == 1 then
		return { text = target.phrases[1].text }
	elseif target.values and #target.values == 1 then
		return { text = target.values[1] }
	end
	return { input = code }
end

function M.func(input, segment, env)
	local list, node = entries(input, env)
	node = node or (env.symbol_aliases or {})[input]
	if node and node.phrases then
		for _, phrase in ipairs(node.phrases) do
			local candidate = Candidate("quick_phrase", segment.start, segment._end, phrase.text, phrase.label)
			candidate.quality = 100
			yield(candidate)
		end
	end
	if node and node.values then
		for _, text in ipairs(node.values) do
			local candidate = Candidate("punct", segment.start, segment._end, text, "")
			candidate.quality = 100
			yield(candidate)
		end
	end
	local function emit(entry, quality, hint)
		-- 私人条目的名字已是完整 gopass 路径，不再在注释中重复。
		if entry.phrases then hint = "" end
		local candidate = Candidate("symbol_menu" .. entry.code, segment.start, segment._end, entry.name, hint)
		candidate.quality = quality
		yield(candidate)
	end
	-- 日期的实际内容由另一个翻译器以 100 生成，子命令提示紧随其后。
	local menu_quality = node and node.command and 75 or 100
	for _, entry in ipairs(list or {}) do
		-- 当前输入已显示父路径，注释只保留还需追加的键。
		local suffix = entry.code:sub(#input + 1)
		local hint = entry.code:sub(1, #input) == input and suffix ~= "" and suffix or entry.code
		emit(entry, menu_quality, hint)
	end
	for _, entry in ipairs(fuzzy_entries(input, env, list, node)) do
		emit(entry, 50, entry.code)
	end
end

return M
