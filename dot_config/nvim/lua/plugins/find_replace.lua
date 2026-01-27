return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		keys = {
			{
				"<leader>fb",
				function()
					-- You can pass additional configuration to telescope to change theme, layout, etc.
					require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
					}))
				end,
				desc = "Find in current Buffer",
			},
			{
				"<leader>/",
				function()
					-- You can pass additional configuration to telescope to change theme, layout, etc.
					require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
					}))
				end,
				desc = "Find in current Buffer",
			},
			{
				"<leader><space>",
				function()
					--HACK:nvim-lastplace is not maintained and don't work when neo-tree opening, so we close neo-tree before using telescope.
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").buffers({ sort_mru = true })
				end,
			},
			{
				"<leader>f?",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").builtin()
				end,
				desc = "Find What to find",
			},
			{
				"<leader>fc",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").commands()
				end,
				desc = "Find Command",
			},
			{
				"<leader>ff",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").find_files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").live_grep()
				end,
				desc = "Live Grep",
			},
			{
				"<leader>fh",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").help_tags()
				end,
				desc = "Find Help",
			},
			{
				"<leader>fk",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").keymaps()
				end,
				desc = "Find Keymap",
			},
			{
				"<leader>fm",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").marks()
				end,
				desc = "Find Mark",
			},
			{
				"<leader>fr",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").oldfiles()
				end,
				desc = "Find Recent flies",
			},
			{
				"<leader>qf",
				function()
					if package.loaded["neo-tree"] then
						vim.cmd("Neotree close")
					end
					require("telescope.builtin").quickfix()
				end,
			},
		},
		config = function()
			require("telescope").setup({
				extensions = {
					fzf = {
						fuzzy = true, -- false will only do exact matching
						override_generic_sorter = true, -- override the generic sorter
						override_file_sorter = true, -- override the file sorter
						case_mode = "smart_case", -- or "ignore_case" or "respect_case"
						-- the default case_mode is "smart_case"
					},
				},
			})
			require("telescope").load_extension("fzf")
		end,
	},
	{
		"MagicDuck/grug-far.nvim",
		cmd = { "GrugFar" },
		keys = {
			{ "<leader>or", "<cmd>GrugFar<cr>", desc = "Open Replace Window" },
		},
		config = function()
			require("grug-far").setup({})
		end,
	},
}
