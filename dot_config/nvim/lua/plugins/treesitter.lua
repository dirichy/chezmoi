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
			-- require("nvim-treesitter").install(parsers)

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
				callback = function(event)
					local ok = pcall(vim.treesitter.start, event.buf)
					if not ok then
						return
					end

					vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
					vim.wo.foldmethod = "expr"
					vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})

			vim.keymap.set("n", "<leader>op", "<cmd>InspectTree<cr><cmd>EditQuery<cr>", { desc = "Open Playground" })
		end,
	},
}
