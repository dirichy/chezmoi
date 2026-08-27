return {
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			local config = require("nvim-surround.config")
			require("nvim-surround").setup({
				surrounds = {
					["b"] = {
						add = function()
							return { "\\{", "\\}" }
						end,
						find = "\\%b{}",
						delete = "^(\\{)().-(\\})()$",
					},
					["B"] = {
						add = function()
							return { "\\left\\{", "\\right\\}" }
						end,
						find = "\\left\\%b{}",
						delete = "^(\\left\\{)().-(\\right\\})()$",
					},
					["`"] = {
						add = { "`", "'" },
						find = "%b`'",
						delete = "^(`)().*(')()$",
					},
					["e"] = {
						add = function()
							local result = config.get_input("Enter the environment name: ")
							if result then
								return { { "\\begin{" .. result .. "}" }, { "\\end{" .. result .. "}" } }
							end
						end,
						find = function()
							return config.get_selection({ motion = "ae" })
						end,
						delete = "^(\\begin%b{})().*(\\end%b{})()$",
					},
					["m"] = {
						add = function()
							local result = config.get_input(
								"Enter math environment type, (j=\\(\\) t=\\[\\] e=equation default=j): "
							)
							local mathtype = {
								j = { "\\(", "\\)" },
								t = { "\\[", "\\]" },
								e = { { "\\begin{equation}", "" }, { "\\end{equation}", "" } },
							}
							if result and mathtype[result] then
								return mathtype[result]
							else
								return mathtype.j
							end
						end,
						find = function()
							return config.get_selection({
								motion = "am",
							})
						end,
						delete = function()
							return config.get_selections({ char = "m", pattern = "^(\\%(%s*\n*)().*(\\%)%s*\n*)()$" })
								or config.get_selections({ char = "m", pattern = "^(\\%[%s*\n*)().*(\\%]%s*\n*)()$" })
								or config.get_selections({
									char = "m",
									pattern = "^(\\begin%b{}%s*\n*)().*(\\end%b{}%s*\n*)()$",
								})
								or config.get_selections({ char = "m", pattern = "^(%$%$%s*\n*)().*(%$%$%s*\n*)()" })
								or config.get_selections({ char = "m", pattern = "^(%$%s*\n*)().*(%$%s*\n*)()" })
						end,
					},
				},
			})
		end,
	},
	{
		"m4xshen/hardtime.nvim",
		lazy = false,
		dependencies = { "MunifTanjim/nui.nvim" },
		opts = {
			showmode = false,
			max_count = 4,
			disable_mouse = false,
			restriction_mode = "hint",
			disabled_keys = {
				["<Up>"] = false,
				["<Down>"] = false,
				["<Left>"] = false,
				["<Right>"] = false,
			},
		},
	},
	{
		"monaqa/dial.nvim",
		keys = {
			{ "<c-a>", "<Plug>(dial-increment)" },
			{ "<c-x>", "<Plug>(dial-decrement)" },
		},
		config = function()
			local augend = require("dial.augend")
			require("dial.config").augends:register_group({
				default = {
					augend.integer.alias.decimal_int,
					augend.integer.alias.hex,
					augend.integer.alias.octal,
					augend.integer.alias.binary,
					augend.date.alias["%Y/%m/%d"],
					augend.date.alias["%Y-%m-%d"],
					augend.date.alias["%m/%d"],
					augend.date.alias["%H:%M"],
					augend.date.alias["%Y年%-m月%-d日"],
					augend.constant.new({
						elements = { "and", "or" },
						word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
						cyclic = true, -- "or" is incremented into "and" .
					}),
					augend.constant.new({
						elements = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
						word = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" },
						sord = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
						sord = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = {
							"星期一",
							"星期二",
							"星期三",
							"星期四",
							"星期五",
							"星期六",
							"星期日",
						},
						sord = true,
						cyclic = true,
					}),
					augend.constant.alias.bool,
					augend.constant.alias.alpha,
					augend.constant.alias.Alpha,
					augend.constant.new({
						elements = { "<", "\\leq", "=", "\\geq", ">", "\\neq" },
						sord = true,
						word = false,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "\\wedge", "\\vee" },
						sord = true,
						word = false,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "\\forall", "\\exists" },
						sord = true,
						word = false,
						cyclic = true,
					}),
				},
			})
		end,
	},
	{
		"gbprod/yanky.nvim",
		event = "VeryLazy",
		opts = {
			ring = {
				history_length = 100,
				storage = "shada",
				storage_path = vim.fn.stdpath("data") .. "/databases/yanky.db", -- Only for sqlite storage
				sync_with_numbered_registers = true,
				cancel_event = "update",
				ignore_registers = { "_" },
				update_register_on_cycle = false,
				permanent_wrapper = nil,
			},
			picker = {
				select = {
					action = nil, -- nil to use default put action
				},
				telescope = {
					use_default_mappings = true, -- if default mappings should be used
					mappings = nil, -- nil to use default mappings or no mappings (see `use_default_mappings`)
				},
			},
			system_clipboard = {
				sync_with_ring = true,
				clipboard_register = nil,
			},
			highlight = {
				on_put = true,
				on_yank = true,
				timer = 500,
			},
			preserve_cursor_position = {
				enabled = true,
			},
			textobj = {
				enabled = true,
			},
		},
		config = function(_, opts)
			require("yanky").setup(opts)
			pcall(require("telescope").load_extension, "yank_history")
		end,
		keys = {
			{
				"<leader>fy",
				function()
					require("telescope").extensions.yank_history.yank_history({})
				end,
				mode = { "n", "x" },
				desc = "Open Yank History",
			},
        -- stylua: ignore
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
			{ "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Text After Cursor" },
			{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Cursor" },
			{ "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put Text After Selection" },
			{ "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Selection" },
			{ "[y", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
			{ "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },
			{ "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
			{ "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
			{ "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
			{ "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
			{ ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and Indent Right" },
			{ "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and Indent Left" },
			{ ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put Before and Indent Right" },
			{ "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put Before and Indent Left" },
			{ "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put After Applying a Filter" },
			{ "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put Before Applying a Filter" },
		},
	},
	{
		"echasnovski/mini.ai",
		event = { "BufNewFile", "BufRead" },
		config = function()
			local ai = require("mini.ai")
			ai.setup()
		end,
	},
	{
		"numToStr/Comment.nvim",
		-- event = "VeryLazy",
		keys = {
			{
				"gcc",
				function()
					return vim.v.count == 0 and "<Plug>(comment_toggle_linewise_current)"
						or "<Plug>(comment_toggle_linewise_count)"
				end,
				expr = true,
				desc = "Comment a line",
			},
			{ "gc", mode = "n", "<Plug>(comment_toggle_linewise)" },
			{ "gc", mode = "x", "<Plug>(comment_toggle_linewise_visual)" },
		},
		config = function()
			require("Comment").setup()
			local ft = require("Comment.ft")
			ft.tex = { "%%s", "\\iffalse\n%s\n\\fi" }
			ft.ly = { "%%s", "%%{ %s %%}" }
		end,
	},
	{
		"ve5li/better-goto-file.nvim",
		config = true,
		---@module "better-goto-file"
		---@type better-goto-file.Options
		opts = {},
		keys = {
			{
				"gf",
				mode = { "n" },
				function()
					require("better-goto-file").goto_file()
				end,
				silent = true,
				desc = "Better go to file under cursor",
			},
			{
				"gf",
				mode = { "v" },
				'<Esc>:lua require("better-goto-file").goto_file_range()<cr>',
				silent = true,
				desc = "Better go to file in selection",
			},
			-- Open in new split.
			{
				"gF",
				mode = { "n" },
				function()
					require("better-goto-file").goto_file({ gf_command = "<C-w>f" })
				end,
				silent = true,
				desc = "Better go to file under cursor in new split",
			},
			{
				"gF",
				mode = { "v" },
				'<Esc>:lua require("better-goto-file").goto_file_range({ gf_command = "<C-w>f" })<cr>',
				silent = true,
				desc = "Better go to file in selection in new split",
			},
		},
	},
	-- lazy.nvim --
}
