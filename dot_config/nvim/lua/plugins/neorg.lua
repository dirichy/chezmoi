return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			render_modes = true,
			anti_conceal = {
				enabled = true,
				disabled_modes = false,
				above = 0,
				below = 0,
			},
			win_options = {
				concealcursor = {
					rendered = "nvic",
				},
			},
		},
	},
}
