local ls = require("luasnip")
local s = ls.snippet
local sn = ls.sn
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local fmta = require("luasnip.extras.fmt").fmta
local line_begin = require("luasnip.extras.expand_conditions").line_begin
local expression_context = {
	expression_list = ",",
	table_constructor = ",",
	arguments = "",
	field = ",",
	return_statement = "",
}
local statement_context = {
	block = true,
	chunk = true,
}
local function is_express_fn()
	local node = vim.treesitter.get_node()

	while node do
		local t = node:type()

		if expression_context[t] then
			return expression_context[t]
		end

		if statement_context[t] then
			return false
		end

		node = node:parent()
	end

	return false
end
return {
	s(
		{ trig = "if" },
		fmta(
			[[
if <> then
  <>
end
  ]],
			{
				i(1, "condition"),
				i(2),
			}
		)
	),
	s(
		{ trig = "while" },
		fmta(
			[[
while <> do
  <>
end
    ]],
			{
				i(1, "condition"),
				i(2),
			}
		)
	),
	s(
		{ trig = "repeat" },
		fmta(
			[[
repeat
  <>
until <>
  ]],
			{
				i(1),
				i(2, "true"),
			}
		)
	),
	s(
		{ trig = "fn" },
		fmta(
			[[
<>function <>(<>)
  <>
end<>
  ]],
			{
				f(function(args, parent)
					local name = args[1][1]
					if string.match(name, "[:.]") then
						return ""
					else
						return "loacl "
					end
				end, { 1 }),
				d(1, function()
					if is_express_fn() then
						return sn(1, { t("") })
					else
						return sn(1, { i(1, "name") })
					end
				end),
				i(2),
				i(3),
				f(is_express_fn),
			}
		)

		-- {
		-- 	condition = is_express_fn,
		-- 	show_condition = is_express_fn,
		-- }
	),
	s(
		{ trig = "do" },
		fmta(
			[[
do
  <>
end
      ]],
			{ i(1) }
		),
		{
			condition = function(line_to_cursor)
				return line_to_cursor:match("^while%s")
			end,
			show_condition = function(line_to_cursor)
				return line_to_cursor:match("^while%s")
			end,
		}
	),
	s(
		{ trig = "then" },
		fmta(
			[[
then
  <>
end
      ]],
			{ i(1) }
		),
		{
			condition = function(line_to_cursor)
				return line_to_cursor:match("^if%s")
			end,
			show_condition = function(line_to_cursor)
				return line_to_cursor:match("^if%s")
			end,
		}
	),
}
