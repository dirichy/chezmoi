return {
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
}
