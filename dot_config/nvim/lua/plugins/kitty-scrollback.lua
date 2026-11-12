return {
	{
		"mikesmithgh/kitty-scrollback.nvim",
		enabled = true,
		lazy = true,
		cmd = {
			"KittyScrollbackGenerateKittens",
			"KittyScrollbackCheckHealth",
			"KittyScrollbackGenerateCommandLineEditing",
		},
		event = { "User KittyScrollbackLaunch" },
		config = function()
			require("kitty-scrollback").setup({
				{
					keymaps_enabled = false,
					callbacks = {
						after_setup = function()
							local group = vim.api.nvim_create_augroup("KittyScrollbackCopyOnQuit", { clear = true })
							local writing, quitting = false, false
							-- Register before the plugin's BufWriteCmd so :w keeps its paste-and-quit behavior.
							vim.api.nvim_create_autocmd("BufWriteCmd", {
								group = group,
								pattern = "*.ksb_pastebuf",
								callback = function()
									writing = true
								end,
							})
							vim.api.nvim_create_autocmd("QuitPre", {
								group = group,
								pattern = "*.ksb_pastebuf",
								callback = function(event)
									if writing or quitting then
										return
									end
									local lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)
									vim.fn.setreg("+", lines, "v")
									quitting = true
									vim.bo[event.buf].modified = false
									-- Give clipboard providers such as xclip time to take ownership before exiting.
									vim.defer_fn(function()
										require("kitty-scrollback.api").quit_all()
									end, 200)
								end,
							})
						end,
					},
				},
			})
		end,
	},
}
