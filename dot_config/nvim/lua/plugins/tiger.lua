return {
	{
		enabled = false,
		vim.fn.isdirectory(vim.env.HOME .. "/tiger.nvim/") == 0 and "dirichy/tiger.nvim",
		dir = vim.fn.isdirectory(vim.env.HOME .. "/tiger.nvim/") == 1 and vim.env.HOME .. "/tiger.nvim",
		ft = { "tex", "latex" },
		config = function(opts)
			require("tiger").setup()
		end,
	},
}
