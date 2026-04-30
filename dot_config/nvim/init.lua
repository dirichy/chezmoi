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

local function copy_diagnostics()
	local buf = vim.api.nvim_get_current_buf()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local diagnostics = vim.diagnostic.get(buf, {
		lnum = lnum - 1, -- need 0-based index
		-- this will select only `ERROR` or `WARN`,
		-- i.e. `INFO` or `HINT` will be ignored
		severity = { min = vim.diagnostic.severity.WARN },
	})

	if vim.tbl_isempty(diagnostics) then
		vim.notify(string.format("Line %d has no diagnostics.", lnum))
		return
	end

	table.sort(diagnostics, function(a, b)
		return a.severity < b.severity
	end)

	-- so which diagnostic to choose
	local result

	-- 1. take wharever appears first
	result = vim.trim(diagnostics[1].message)

	-- 2. just concatenate everything
	result = vim.iter(diagnostics)
		:map(function(diag)
			return vim.trim(diag.message)
			-- you may want to prefix with severity
			-- local prefix = diag.severity == vim.diagnostic.severity.ERROR and 'ERROR: ' or 'WARNING: '
			-- return prefix .. vim.trim(diag.message)
		end)
		:join("\r\n")

	-- 3. use vim.ui.select
	vim.ui.select(diagnostics, {
		prompt = "Select diagnostic:",
		format_item = function(diag)
			local severity = diag.severity == vim.diagnostic.severity.ERROR and "ERROR" or "WARNING"
			return string.format("%s: [%s] %s (%s)", severity, diag.code, vim.trim(diag.message), diag.source)
		end,
	}, function(choice)
		if choice then
			result = vim.trim(choice.message)
		end
	end)

	if result then
		vim.fn.setreg(vim.v.register, result)
		vim.notify(string.format("Yank diagnostic to register `%s`: %s", vim.v.register, result))
	end
end
vim.keymap.set("n", "dy", copy_diagnostics, { desc = "Yank diagnostic" })
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
-- vim.api.nvim_create_autocmd("CursorHold", {
-- 	callback = function()
-- 		vim.diagnostic.open_float(nil, { focusable = true, source = "if_many" })
-- 	end,
-- })
