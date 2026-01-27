return {
	{
		"stevearc/aerial.nvim",
		keys = {
			{ "<leader>oa", "<cmd>AerialToggle!<cr>", desc = "Open AerialToggle!" },
			{ "]a", "<cmd>AerialNext<cr>", desc = "Aerial Next" },
			{ "[a", "<cmd>AerialPrev<cr>", desc = "Aerial Prev" },
			{ "<leader>fa", "<cmd>Telescope aerial<cr>", desc = "Find Aerial" },
		},
		-- Optional dependencies
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("aerial").setup({
				autojump = true,
				close_on_select = true,
			})
			require("telescope").load_extension("aerial")
		end,
	},
	{
		"danymat/neogen",
		keys = {
			{ "<leader>id", "<cmd>Neogen<cr>", desc = "Insert Doc" },
		},
		config = function()
			require("neogen").setup({ snippet_engine = "luasnip" })
		end,
		-- Uncomment next line if you want to follow only stable versions
		-- version = "*"
	},
	--TODO:config this plugin
	{
		"folke/todo-comments.nvim",
		event = { "BufRead", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},
	{
		"stevearc/conform.nvim",
		event = "CmdlineEnter",
		keys = {
			{
				"<leader>F",
				function()
					require("conform").format({ bufnr = 0 })
				end,
				desc = "Format Code",
			},
		},
		config = function()
			require("conform").setup({
				formatters = {
					["tex-fmt"] = {
						command = "tex-fmt",
						args = { "--stdin", "--nowrap", "--print" },
					},
					["pangu"] = {
						command = "sed",
						args = {
							"-E",
							"-e",
							[[s/([一-龥])\\\(/\1 \\\(/g]],
							"-e",
							[[s/\\\)([一-龥])/\\) \1/g]],
						},
						stdin = true,
					},
					["puncture"] = {
						command = "gsed",
						args = {
							"-E",
							"-e",
							[[s/\\\)\s*[,，]/\\)\\nolinebreak[4]，/g]],
							"-e",
							[[s/\\\)\s*[.。]/\\)\\nolinebreak[4]。/g]],
							"-e",
							[[s/\\\)\s*[；;]/\\)\\nolinebreak[4]；/g]],
							-- "-e",
							-- [[s/^(\s*)[,，]/\1，/g]],
							-- "-e",
							-- [[s/^(\s*)[.。]/\1。/g]],
							-- "-e",
							-- [[s/^(\s*)[；;]/\1；/g]],
							"-e",
							[[s/([，。；])\s*/\1/g]],
						},
						stdin = true,
					},
				},
				formatters_by_ft = {
					lua = { "stylua" },
					-- Conform will run multiple formatters sequentially
					python = { "isort", "black" },
					-- You can customize some of the format options for the filetype (:help conform.format)
					rust = { "rustfmt", lsp_format = "fallback" },
					-- Conform will run the first available formatter
					javascript = { "prettierd", "prettier", stop_after_first = true },
					tex = { "tex-fmt", "injected" }, --, "pangu", "puncture" },
					-- tex = { "tex-fmt", "injected", "pangu", "puncture" },
					c = { "clang-format" },
					json = { "clang-format" },
					jsonc = { "prettierd" },
					zsh = { "beautysh" },
					html = { "prettierd" },
					yaml = { "prettierd" },
					liquid = function(bufer)
						local formter_by_name = {
							html = { "prettierd" },
							json = { "clang-format" },
						}
						local real_filetype = vim.api.nvim_buf_get_name(bufer)
						real_filetype = real_filetype:match("[^.]*$")
						return formter_by_name[real_filetype] or {}
					end,
				},
			})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function(args)
					require("conform").format({ bufnr = args.buf })
				end,
			})
		end,
	},
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
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		keys = {
			{
				"<leader>uz",
				function()
					-- --HACK:Neotree will break ZenMode
					if package.loaded["neo-tree"] then
						vim.cmd.Neotree("close")
					end
					vim.cmd.ZenMode()
				end,
				desc = "Toggle ZenMode",
			},
		},
		opts = {
			plugins = {
				tmux = { enabled = true },
				kitty = {
					enabled = true,
					font = "+4",
				},
			},
		},
		config = true,
	},
	{
		"folke/trouble.nvim",
		opts = {}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
}
