-- select_character_processor: 以词定字
-- 详见 `lua/select_character.lua`
package.path = "/opt/homebrew/share/lua/5.4/?.lua;/opt/homebrew/share/lua/5.4/?/init.lua;/opt/homebrew/lib/lua/5.4/?.lua;/opt/homebrew/lib/lua/5.4/?/init.lua;"
	.. package.path
package.cpath = "/opt/homebrew/lib/lua/5.4/?.so;" .. package.cpath
select_character = require("select_character")
-- date_translator: 动态日期时间输入
-- 详见 `lua/date_translator.lua`
date_translator = require("date_translator")

-- long_phrase_first: 最长词组和单字在先
-- 详见 `lua/candidate_sorting/long_phrase_first.lua`
long_phrase_first = require("candidate_sorting.long_phrase_first")

-- single_char_first: 单字在先
-- 详见 `lua/candidate_sorting/single_char_first.lua`
single_char_first = require("candidate_sorting.single_char_first")

-- single_char_only: 只显示单字
-- 详见 `lua/candidate_sorting/single_char_only.lua`
single_char_only = require("candidate_sorting.single_char_only")

-- unicode_input: Unicode 输入
-- 详见 `lua/candidate_sorting/unicode_input.lua`
unicode_input = require("unicode_input")

auto_put = require("nvim.mathmode")
charset_comment_filter = require("charset_comment_filter") --Unicode分区提示
core2022 = require("core2022_filter") --自定义字符集过滤（常用字集）
-- dz_ci = require("dz_ci_filter") --单字模式 这个别用，有问题的
number_translator = require("number")
lua_unicode_display_filter = require("unicode_display") --Unicode编码提示
calculator_translator = require("calculator_translator") --简易计算器
exe_processor = require("exe") -- 网页启动器
shijian2_translator = require("shijian2") -- 高级时间
-- vimmode = require("nvim.vimmode")
