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
			local treesitter = require("nvim-treesitter")
			treesitter.setup()
			local available = {}
			for _, language in ipairs(treesitter.get_available()) do
				available[language] = true
			end
			local installing = {}

			local function enable_parser(buf, language)
				if not vim.api.nvim_buf_is_loaded(buf)
					or vim.bo[buf].filetype == "bigfile"
					or vim.b[buf].bigfile
					or vim.treesitter.language.get_lang(vim.bo[buf].filetype) ~= language
				then
					return false
				end
				if not pcall(vim.treesitter.start, buf, language) then
					return false
				end
				for _, win in ipairs(vim.fn.win_findbuf(buf)) do
					vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
					vim.wo[win].foldmethod = "expr"
					vim.wo[win].foldlevel = 99
				end
				vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				return true
			end

			local function start_parser(buf, filetype)
				local language = vim.treesitter.language.get_lang(filetype)
				if not language or enable_parser(buf, language) or not available[language] then
					return
				end

				if installing[language] then
					installing[language][buf] = true
					return
				end

				installing[language] = { [buf] = true }
				-- Leave FileType immediately; await registers a nonblocking completion callback.
				vim.schedule(function()
					local ok, task = pcall(treesitter.install, { language })
					if not ok then
						installing[language] = nil
						return
					end
					task:await(vim.schedule_wrap(function(err, success)
						local buffers = installing[language]
						installing[language] = nil
						if err or not success then
							return
						end
						for pending_buf in pairs(buffers) do
							enable_parser(pending_buf, language)
						end
					end))
				end)
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
				callback = function(event)
					if vim.bo[event.buf].filetype == "bigfile" or vim.b[event.buf].bigfile then
						return
					end

					start_parser(event.buf, vim.bo[event.buf].filetype)
				end,
			})

			vim.keymap.set("n", "<leader>op", "<cmd>InspectTree<cr><cmd>EditQuery<cr>", { desc = "Open Playground" })
		end,
	},
}
