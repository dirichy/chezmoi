-- 公共日期工具：四套方案统一使用 date_commands 中的斜杠入口。
local M = {}
local commands = require("date_commands")
local digits = { ["0"] = "〇", ["1"] = "一", ["2"] = "二", ["3"] = "三", ["4"] = "四",
	["5"] = "五", ["6"] = "六", ["7"] = "七", ["8"] = "八", ["9"] = "九" }
local months = { "January", "February", "March", "April", "May", "June", "July", "August",
	"September", "October", "November", "December" }

function M.init(env)
	env.date_keywords = {}
	for input, kind in pairs(commands) do
		env.date_keywords[input] = kind
	end
	env.date_keywords["/path"] = "path"
	env.date_keywords["/version"] = "version"
end

function M.func(input, seg, env)
	local kind = env.date_keywords[input]
	if not kind then
		return
	end
	local now = os.time()
	local function emit(text, comment)
		local candidate = Candidate(kind, seg.start, seg._end, tostring(text), comment or "")
		candidate.quality = 100
		yield(candidate)
	end
	if kind == "date" then
		emit(os.date("%Y-%m-%d", now))
		emit(os.date("%Y年%m月%d日", now))
		emit(os.date("%Y%m%d", now))
	elseif kind == "time" then
		emit(os.date("%H:%M:%S", now))
		emit(os.date("%H时%M分%S秒", now))
		emit(os.date("%H%M%S", now))
	elseif kind == "timestamp" then
		emit(now)
	elseif kind == "datetime" then
		emit(os.date("%Y-%m-%d %H:%M:%S", now))
		local zone = os.date("%z", now):gsub("(%d%d)(%d%d)$", "%1:%2")
		emit(os.date("%Y-%m-%dT%H:%M:%S", now) .. zone)
		emit(os.date("%Y%m%d%H%M", now))
	elseif kind == "week" then
		local weekdays = { "日", "一", "二", "三", "四", "五", "六" }
		local day = weekdays[tonumber(os.date("%w", now)) + 1]
		emit("周" .. day)
		emit("星期" .. day)
		emit(os.date("%A", now))
		emit(os.date("%a", now))
		emit(os.date("%W", now), "周数")
	elseif kind == "month" then
		emit(os.date("%B", now))
		emit(os.date("%b", now))
	elseif kind == "datezh" then
		local year = os.date("%Y", now):gsub("%d", digits)
		local function chinese(number)
			if number < 10 then return digits[tostring(number)] end
			local tens, units = math.floor(number / 10), number % 10
			return (tens == 1 and "" or digits[tostring(tens)]) .. "十"
				.. (units == 0 and "" or digits[tostring(units)])
		end
		emit(year .. "年" .. chinese(tonumber(os.date("%m", now))) .. "月"
			.. chinese(tonumber(os.date("%d", now))) .. "日")
	elseif kind == "dateen" then
		local month = months[tonumber(os.date("%m", now))]
		local day = tonumber(os.date("%d", now))
		local year = os.date("%Y", now)
		emit(day .. " " .. month .. " " .. year)
		emit(month .. " " .. day .. ", " .. year)
	elseif kind == "path" then
		emit(package.path)
	elseif kind == "version" then
		emit(_VERSION)
	end
end

return M
