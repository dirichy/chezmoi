return {
	{
		enabled = false,
		vim.fn.isdirectory("/Users/dirichy/tiger.nvim/") == 0 and "dirichy/tiger.nvim",
		dir = vim.fn.isdirectory("/Users/dirichy/tiger.nvim/") == 1 and "/Users/dirichy/tiger.nvim",
		ft = { "tex", "latex" },
		config = function(opts)
			require("tiger").setup()
		end,
	},
}
