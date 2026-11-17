-- /simpstats 显示最常多打的前 20 项；选择候选只会提交对应的字。
local tracker = require("tiger.simp_tracker")
return function(input, segment, env)
	if input ~= "/simpstats" then return end
	local entries, failed = tracker.summary(env)
	if failed then
		yield(Candidate("simp_stats", segment.start, segment._end, "统计写入失败", "当前会话仍有内存统计"))
	end
	if #entries == 0 then
		yield(Candidate("simp_stats", segment.start, segment._end, "暂无简码统计", "只记录可以少按键的单字"))
	end
	for index = 1, math.min(20, #entries) do
		local entry = entries[index]
		local comment = string.format("%s → %s · %d 次 · 多按 %d 键", entry.actual, entry.short, entry.count, entry.extra)
		yield(Candidate("simp_stats", segment.start, segment._end, entry.char, comment))
	end
end
