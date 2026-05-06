local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local fmta = require("luasnip.extras.fmt").fmta
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
function <>(<>)
  <>
end
  ]],
			{
				i(1, "name"),
				i(2, "arglist"),
				i(3),
			}
		)
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
