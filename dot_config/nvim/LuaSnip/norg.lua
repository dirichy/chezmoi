local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local extras = require("luasnip.extras")
local l = extras.lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local line_begin = require("luasnip.extras.expand_conditions").line_begin
return {
	s(
		{ trig = "tipa", snippetType = "autosnippet" },
		fmta("$|\\tipa{<>}|$", {
			i(1),
		})
	),
	s(
		{ trig = "jj", snippetType = "autosnippet" },
		fmta("$|<>|$ <>", {
			i(1),
			i(0),
		})
	),
	s(
		{ trig = "tt", snippetType = "autosnippet" },
		fmta(
			[[
@code latex
\[
<>
\]
@end
<>
	   ]],
			{
				i(1),
				i(0),
			}
		)
	),
	s(
		{ trig = ".eq", snippetType = "autosnippet" },
		fmta(
			[[
@code latex
\begin{equation}
<>
\end{equation}
@end
<>
	   ]],
			{
				i(1),
				i(0),
			}
		)
	),
	s(
		{ trig = "|$ ([^%a])", regTrig = true, wordTrig = false, snippetType = "autosnippet", priority = 2000 },
		fmta("|$<>", {
			f(function(_, snip)
				return snip.captures[1]
			end),
		})
	),
	s({
		trig = "h([1-6])",
		name = "Heading",
		dscr = "Add Heading",
		regTrig = true,
		hidden = true,
	}, {
		f(function(_, snip)
			return string.rep("*", tonumber(snip.captures[1])) .. " "
		end, {}),
	}, {
		condition = line_begin,
	}),
	s({
		trig = "q([1-6])",
		name = "Quote",
		dscr = "Add Quote",
		regTrig = true,
		hidden = true,
	}, {
		f(function(_, snip)
			return string.rep(">", tonumber(snip.captures[1])) .. " "
		end, {}),
	}, {
		condition = line_begin,
	}),
	s({
		trig = "i([1-6])",
		name = "Unordered lists",
		dscr = "Add Unordered lists",
		regTrig = true,
		hidden = true,
	}, {
		f(function(_, snip)
			return string.rep("-", tonumber(snip.captures[1])) .. " "
		end, {}),
	}, {
		condition = line_begin,
	}),
	s({
		trig = "e([1-6])",
		name = "Ordered lists",
		dscr = "Add Ordered lists",
		regTrig = true,
		hidden = true,
	}, {
		f(function(_, snip)
			return string.rep("~", tonumber(snip.captures[1])) .. " "
		end, {}),
	}, {
		condition = line_begin,
	}),
}
