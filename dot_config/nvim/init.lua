package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"
package.cpath = package.cpath .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";./?.so"
if vim.env.PROF then
	-- example for lazy.nvim
	-- change this to the correct path for your plugin manager
	local snacks = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
	vim.opt.rtp:append(snacks)
	require("snacks.profiler").startup({
		startup = {
			event = "VimEnter", -- stop profiler on this event. Defaults to `VimEnter`
			-- event = "UIEnter",
			-- event = "VeryLazy",
		},
	})
end
vim.loader.enable()
vim.g.tex_conceal = ""
require("options")
require("lazy_nvim")
require("keymaps")
require("autocmds")
require("hypr")

-- local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
-- parser_config.lilypond = {
-- 	install_info = {
-- 		url = "https://github.com/nwhetsell/tree-sitter-lilypond", -- local path or git repo
-- 		files = { "src/parser.c" }, -- note that some parsers also require src/scanner.c or src/scanner.cc
-- 		-- optional entries:
-- 		branch = "main", -- default branch in case of git repo if different from master
-- 		generate_requires_npm = false, -- if stand-alone parser without npm dependencies
-- 		requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
-- 	},
-- 	-- filetype = "zu", -- if filetype does not match the parser name
-- }
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float(nil, { focusable = false, source = "if_many" })
	end,
})
