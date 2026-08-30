return {
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
}
