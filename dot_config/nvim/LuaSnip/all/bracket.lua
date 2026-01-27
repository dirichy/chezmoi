local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet

-- vim.keymap.set("i", "<CR>", function()
-- 	local node = require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
-- 	local text = node and node:get_text()
-- 	local flag = node and node.parent and node.parent.name == "testfuck" and #text == 1 and text[1] == ""
-- 	if flag then
-- 		return "\r\t"
-- 	else
-- 		return "\r"
-- 	end
-- end, { noremap = true, expr = true })

local function bracket(open, close, opts)
	return s({ trig = open, wordTrig = false, snippetType = "autosnippet" }, {
		t(open),
		i(1),
		t(close),
		i(0),
	}, opts)
end
local function make_snip(brackets, opts, tab)
	local result = tab or {}
	for index, value in ipairs(brackets) do
		table.insert(result, bracket(value[1], value[2], value[3] or opts))
	end
	return result
end

local M = make_snip({ { "(", ")" }, { "[", "]" }, { "{", "}" }, { '"', '"' }, { "'", "'" } }, {
	condition = function()
		return vim.bo.filetype ~= "tex"
	end,
})
make_snip({
	{
		"`",
		"'",
		{
			condition = function()
				return vim.bo.filetype == "tex" and require("nvimtex.conditions.luasnip").in_text()
			end,
		},
	},
	{ "{", "}" },
	{ "$", "$" },
}, {
	condition = function()
		return vim.bo.filetype == "tex"
	end,
}, M)

return M
