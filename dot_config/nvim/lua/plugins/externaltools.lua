return {
	{
		"pwntester/octo.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			-- OR 'ibhagwan/fzf-lua',
			"nvim-tree/nvim-web-devicons",
		},
		cmd = "Octo",
		config = function()
			require("octo").setup()
		end,
	},
	---@type LazySpec
	{
		"mikavilpas/yazi.nvim",
		-- event = "VeryLazy",
		keys = {
			-- 👇 in this section, choose your own keymappings!
			{
				"<leader>oy",
				function()
					require("yazi").yazi()
				end,
				desc = "Open Yazi",
			},
			{
				-- Open in the current working directory
				"<leader>oY",
				function()
					require("yazi").yazi(nil, vim.fn.getcwd())
				end,
				desc = "Open Yazi in nvim's working directory",
			},
			-- {
			-- 	"<c-up>",
			-- 	function()
			-- 		-- NOTE: requires a version of yazi that includes
			-- 		-- https://github.com/sxyazi/yazi/pull/1305 from 2024-07-18
			-- 		require("yazi").toggle()
			-- 	end,
			-- 	desc = "Resume the last yazi session",
			-- },
		},
		---@type YaziConfig
		opts = {
			-- if you want to open yazi instead of netrw, see below for more info
			open_for_directories = false,

			-- enable these if you are using the latest version of yazi
			-- use_ya_for_events_reading = true,
			-- use_yazi_client_id_flag = true,

			keymaps = {
				show_help = "?",
			},
		},
	},
}
