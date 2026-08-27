return {
	{
		"nvimtools/hydra.nvim",
		keys = { "z" },
		config = function()
			local Hydra = require("hydra")
			Hydra.setup({
				debug = false,
				exit = false,
				foreign_keys = nil,
				color = "red",
				timeout = false,
				invoke_on_body = false,
				hint = {
					show_name = true,
					position = { "bottom" },
					offset = 0,
					float_opts = {},
				},
				on_enter = nil,
				on_exit = nil,
				on_key = nil,
			})
			Hydra({
				name = "Move Screen",
				mode = "n",
				body = "z",
				hint = "z(l|h|L|H)",
				config = {},
				heads = {
					{ "l", "zl", { desc = "" } },
					{ "h", "zh", { desc = "" } },
					{ "L", "zL", { desc = "󰜴" } },
					{ "H", "zH", { desc = "󰜱" } },
					{ "j", "<c-e>", { desc = "" } },
					{ "k", "<c-y>", { desc = "" } },
					{ "J", "<c-d>", { desc = "󰜮" } },
					{ "K", "<c-u>", { desc = "󰜷" } },
				},
			})
		end,
	},
	{
		"folke/flash.nvim",
		lazy = true,
		-- event = "VeryLazy",
		dependencies = { "rainzm/flash-zh.nvim" },
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash-zh").jump({ chinese_only = false })
					-- require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
			{
				"<c-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
		config = function()
			require("flash").setup()
			-- local map = vim.keymap.set
			-- for _, key in ipairs(keys) do
			-- 	map(key.mode, key[1], key[2], { desc = key.desc })
			-- end
		end,
	},
}
