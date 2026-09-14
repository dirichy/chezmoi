--Close some buffer by `q`
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"oil",
		"PlenaryTestPopup",
		"grug-far",
		"help",
		"lspinfo",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"neotest-output",
		"checkhealth",
		"neotest-summary",
		"neotest-output-panel",
		"dbout",
		"gitsigns.blame",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", {
			buffer = event.buf,
			silent = true,
			desc = "Quit buffer",
		})
	end,
})
--Create dir autometically when write.
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

local delayed_clipboard_group = vim.api.nvim_create_augroup("DelayedClipboardSync", { clear = true })
local pending_clipboard = nil

vim.api.nvim_create_autocmd("TextYankPost", {
	group = delayed_clipboard_group,
	callback = function()
		if not vim.g.delayed_clipboard_sync then
			return
		end

		local event = vim.v.event
		if event.operator ~= "y" or event.regname == "_" then
			return
		end

		pending_clipboard = {
			contents = event.regcontents,
			regtype = event.regtype,
		}
	end,
})

vim.api.nvim_create_autocmd("FocusLost", {
	group = delayed_clipboard_group,
	callback = function()
		if not vim.g.delayed_clipboard_sync then
			return
		end

		if not pending_clipboard then
			return
		end

		vim.fn.setreg("+", pending_clipboard.contents, pending_clipboard.regtype)
		pending_clipboard = nil
	end,
})
