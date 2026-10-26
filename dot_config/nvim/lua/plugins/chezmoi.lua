return {
	vim.fn.isdirectory(vim.env.HOME .. "/vimoi.nvim/") == 0 and "dirichy/vimoi.nvim",
	dir = vim.fn.isdirectory(vim.env.HOME .. "/vimoi.nvim/") == 1 and vim.env.HOME .. "/vimoi.nvim",
	opts = {
		completion = {
			mask = false,
		},
	},
}
