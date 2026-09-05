return {
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
