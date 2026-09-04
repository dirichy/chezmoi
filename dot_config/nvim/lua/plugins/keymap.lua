return {
	{
		vim.fn.isdirectory(vim.env.HOME .. "/keyflow.nvim/") == 0 and "dirichy/keyflow.nvim",
		dir = vim.fn.isdirectory(vim.env.HOME .. "/keyflow.nvim/") == 1 and vim.env.HOME .. "/keyflow.nvim",
		lazy = false,
		config = function()
			local keyflow = require("keyflow")
			keyflow.mode({
				name = "Move Screen",
				mode = "n",
				body = "z",
				heads = {
					l = "zl",
					h = "zh",
					L = "zL",
					H = "zH",
					j = "<C-e>",
					k = "<C-y>",
					J = "<C-d>",
					K = "<C-u>",
				},
			})
		end,
	},
	{
		"folke/which-key.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({
				icons = {
					rules = {
						{ plugin = "lazygit.nvim", icon = "󰊢", color = "orange" },
						{ plugin = "ccc.nvim", icon = "", color = "yellow" },
						{ plugin = "yazi.nvim", icon = "󰇥", color = "blue" },
						{ plugin = "latex.nvim", cat = "filetype", name = "tex" },
						{ pattern = "mason", icon = "", color = "green" },
						{ pattern = "playground", icon = "󰙨", color = "red" },
					},
				},
				win = {
					no_overlap = false,
				},
			})
			wk.add({
				{ "<leader>n", group = "Noice" },
				{ "<leader>o", group = "Open window" },
				{ "<leader>b", group = "Buffer" },
				{ "<leader>t", group = "LaTeX", icon = { cat = "filetype", name = "tex" } },
				{ "<leader>f", group = "Find", icon = { icon = "", color = "blue" } },
				{ "<leader>g", group = "Git" },
				{ "<leader>q", group = "Session" },
				{ "g", group = "Goto" },
				{ "<leader>u", group = "Toggle" },
				{ "<leader>ot", "<cmd>terminal<cr>", desc = "Open Terminal" },
				{ "<leader>ol", "<cmd>Lazy<cr>", desc = "Open Lazy" },
				-- { "<leader>om", "<cmd>Mason<cr>", desc = "Open Mason(for LSP install)", icon = "" },
			})
			wk.add(require("mapper").which_key_spec)
		end,
	},
}
