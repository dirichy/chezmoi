return {
	vim.fn.isdirectory(vim.env.HOME .. "/keyflow.nvim/") == 0 and "dirichy/keyflow.nvim",
	dir = vim.fn.isdirectory(vim.env.HOME .. "/keyflow.nvim/") == 1 and vim.env.HOME .. "/keyflow.nvim",
	lazy = false,
	config = function()
		local keyflow = require("keyflow")
		keyflow.mode.new({
			name = "Move Screen",
			vimmode = "n",
			trigger = "z",
			maps = {
				l = "zl",
				h = "zh",
				L = "zL",
				H = "zH",
				j = "<C-e>",
				k = "<C-y>",
				J = "<C-d>",
				K = "<C-u>",
			},
			hint = true,
		})
		keyflow.mode.new({
			name = "Marco mode",
			vimmode = "n",
			trigger = "<leader>@",
			on_key = function(mode, key)
				if string.byte("a") <= string.byte(key) and string.byte(key) <= string.byte("z") then
					return "@" .. key
				end
			end,
			hint = { "Press any alphabet to process corresponding macro" },
			lazy = false,
		})
	end,
}
