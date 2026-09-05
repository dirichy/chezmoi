return {
	{
		"folke/persistence.nvim",
		lazy = false,
		-- event = "ExitPre",
		keys = {
			{
				"<leader>qs",
				function()
					--HACK: Neo-tree will break nvim-lastplace
					if package.loaded["neo-tree"] then
						vim.cmd([[Neotree close]])
					end
					--HACK: If load session while oil is loading, will cause filetype of file buffer as Oil
					if package.loaded["oil"] then
						local buffer = vim.api.nvim_win_get_buf(0)
						if vim.bo[buffer].filetype == "oil" then
							local timer = vim.uv.new_timer()
							timer:start(400, 0, function()
								vim.schedule(function()
									vim.cmd([[lua require("persistence").load()]])
								end)
								timer:stop()
								timer:close()
							end)
						else
							vim.cmd([[lua require("persistence").load()]])
						end
					else
						vim.cmd([[lua require("persistence").load()]])
					end
				end,
				desc = "Load Session",
			},
			{ "<leader>ql", [[<cmd>lua require("persistence").load({ last = true})<cr>]], desc = "Load Last Session" },
			{
				"<leader>qd",
				[[<cmd>lua require("persistence").stop()<cr><cmd>qa<cr>]],
				desc = "Quit and not save this session",
			},
			{ "<leader>qS", [[<cmd>lua require("persistence").select()<cr>]], desc = "Select Load Session" },
		},
		config = true,
	},
	{
		"ethanholz/nvim-lastplace",
		event = { "BufRead" },
		config = true,
		init = function()
			if package.loaded["nvim-lastplace"] then
				return
			end
			local stats = vim.uv.fs_stat(vim.fn.argv(0))
			if stats and stats.type == "file" then
				require("nvim-lastplace").setup()
			end
		end,
	},
}
