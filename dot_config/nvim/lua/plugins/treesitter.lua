local parsers = {
	"bash",
	"c",
	"cpp",
	"css",
	"dockerfile",
	"go",
	"html",
	"javascript",
	"json",
	"latex",
	"lua",
	"luadoc",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"rust",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		branch = "main",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup()
			local installing = {}

			local function start_parser(buf, filetype)
				local ok = pcall(vim.treesitter.start, buf)
				if ok then
					return true
				end

				if installing[filetype] then
					return false
				end

				installing[filetype] = true
				local ok_install = pcall(require("nvim-treesitter").install, { filetype })
				if not ok_install then
					installing[filetype] = nil
					return false
				end

				local attempts = 0
				local function retry()
					attempts = attempts + 1
					if not vim.api.nvim_buf_is_valid(buf) then
						installing[filetype] = nil
						return
					end
					if pcall(vim.treesitter.start, buf) or attempts >= 2 then
						installing[filetype] = nil
						return
					end
					vim.defer_fn(retry, 100)
				end
				vim.defer_fn(retry, 100)
				return false
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
				callback = function(event)
					if vim.bo[event.buf].filetype == "bigfile" or vim.b[event.buf].bigfile then
						return
					end

					if not start_parser(event.buf, vim.bo[event.buf].filetype) then
						return
					end

					vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
					vim.wo.foldmethod = "expr"
					vim.wo.foldlevel = 99
					vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})

			vim.keymap.set("n", "<leader>op", "<cmd>InspectTree<cr><cmd>EditQuery<cr>", { desc = "Open Playground" })
		end,
	},
}
