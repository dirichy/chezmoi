local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local fmta = require("luasnip.extras.fmt").fmta
-- stylua: ignore
local keywords = { ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true, ["while"] = true, }
local function condition(_, _, captures)
	if not keywords[captures[1]] then
		return false
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	cursor[1] = cursor[1] - 1
	cursor[2] = cursor[2] - 2
	if cursor[2] < 0 then
		cursor[2] = 0
	end
	local node = vim.treesitter.get_node({ pos = cursor })
	if not node then
		return false
	end
	local parent = node:parent()
	if not parent then
		return false
	end
	if parent:type() == "dot_index_expression" and node:equal(parent:field("field")[1]) then
		local grand_parent = parent:parent()
		if
			grand_parent
			and grand_parent:type() == "function_declaration"
			and parent:equal(grand_parent:field("name")[1])
		then
			return false
		end
		return true
	end
	local grand_parent = parent:parent()
	if not grand_parent then
		return
	end
	if
		grand_parent:type() == "table_constructor"
		and parent:type() == "field"
		and node:equal(parent:field("value")[1])
	then
		return true
	end
	return false
end
local function conceal_condition(_, _, captures)
	if not keywords[captures[1]] then
		return false
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	cursor[1] = cursor[1] - 1
	cursor[2] = cursor[2] - 4
	if cursor[2] < 0 then
		cursor[2] = 0
	end
	local node = vim.treesitter.get_node({ pos = cursor })
	if not node then
		return false
	end
	local parent = node:parent()
	if not parent then
		return false
	end
	-- value: (bracket_index_expression ; [92, 4] - [92, 11]
	--   table: (identifier) ; [92, 4] - [92, 5]
	--   field: (string ; [92, 6] - [92, 10]
	--     content: (string_content))))) ; [92, 7] - [92, 9]
	local grand_parent = parent:parent()
	if not grand_parent then
		return
	end
	if
		grand_parent:type() == "bracket_index_expression"
		and parent:equal(grand_parent:field("field")[1])
		and node:equal(parent:field("content")[1])
	then
		return true
	end
	return false
end
local M = {
	--keywords as table key, e.g., convert {end=1} into {["end"]=1}
	s(
		{ trig = "([a-z_]*)=", snippetType = "autosnippet", regTrig = true, wordTrig = false },
		fmta('["<>"]=<>', {
			f(function(_, snip)
				return snip.captures[1]
			end),
			i(0),
		}),
		{
			condition = condition,
		}
	),
	--keywords key indexing, e.g., convert x.when into x["when"]
	s(
		{ trig = "%.([a-z_]*)", snippetType = "autosnippet", regTrig = true, wordTrig = false },
		fmta('["<>"]<>', {
			f(function(_, snip)
				return snip.captures[1]
			end),
			i(0),
		}),
		{
			condition = condition,
		}
	),
	-- conceal when use some key with one of keywords as prefix, e.g.,
	-- you want to type a.inspect, but when you type a.in,
	-- the snip above will convert it into a["in"].
	-- So we need to convert it back when you continue type.
	-- In fact, we will convert a["in"]s into a.ins.
	s({
		trig = [=[%["(%a*)"%]([%a_])]=],
		wordTrig = false,
		regTrig = true,
		snippetType = "autosnippet",
	}, {
		f(function(_, snip)
			return "." .. snip.captures[1] .. snip.captures[2]
		end),
	}, { condition = conceal_condition }),
}
return M
