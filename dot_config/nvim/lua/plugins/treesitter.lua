return {
	"nvim-treesitter/nvim-treesitter",
	event = "VeryLazy",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		-- "HiPhish/rainbow-delimiters.nvim",
	},
	main = "nvim-treesitter.configs",
	build = ":TSUpdate",
	opts = {
		-- ensure_installed = "all",
		highlight = {
			enable = true,
		},
		indent = {
			enable = true,
		},
		playground = {
			enable = true,
			disable = {},
			updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
			persist_queries = false, -- Whether the query persists across vim sessions
			keybindings = {
				toggle_query_editor = "o",
				toggle_hl_groups = "i",
				toggle_injected_languages = "t",
				toggle_anonymous_nodes = "a",
				toggle_language_display = "I",
				focus_language = "f",
				unfocus_language = "F",
				update = "R",
				goto_node = "<cr>",
				show_help = "?",
			},
		},
		textobjects = {
			select = {
				enable = true,

				-- Automatically jump forward to textobj, similar to targets.vim
				lookahead = true,

				keymaps = {
					-- You can use the capture groups defined in textobjects.scm
					-- ["ae"] = { query = "@block.outer", desc = "Select Environment Outer" },
					-- ["ie"] = { query = "@block.inner", desc = "Select Environment Inner" },
					["af"] = { query = "@function.outer", desc = "Select Function Outer" },
					["if"] = { query = "@function.inner", desc = "Select Function Inner" },
					["ac"] = { query = "@command.outer", desc = "Select Command Outer" },
					-- ["am"] = { query = "@tex.math.outer", desc = "Select Mathzone Outer" },
					-- ["im"] = { query = "@tex.math.inner", desc = "Select MathZone Inner" },
					-- You can optionally set descriptions to the mappings (used in the desc parameter of
					-- nvim_buf_set_keymap) which plugins like which-key display
					-- ["ic"] = { query = "@command.inner", desc = "Select Command Inner" },
					-- You can also use captures from other query groups like `locals.scm`
					["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
				},
				-- You can choose the select mode (default is charwise 'v')
				--
				-- Can also be a function which gets passed a table with the keys
				-- * query_string: eg '@function.inner'
				-- * method: eg 'v' or 'o'
				-- and should return the mode ('v', 'V', or '<c-v>') or a table
				-- mapping query_strings to modes.
				selection_modes = {
					["@parameter.outer"] = "v", -- charwise
					-- ['@function.outer'] = 'V',            -- linewise
					-- ['@class.outer'] = '<c-v>',           -- blockwise
					-- ['block.outer'] = 'V',
				},
				-- If you set this to `true` (default is `false`) then any textobject is
				-- extended to include preceding or succeeding whitespace. Succeeding
				-- whitespace has priority in order to act similarly to eg the built-in
				-- `ap`.
				--
				-- Can also be a function which gets passed a table with the keys
				-- * query_string: eg '@function.inner'
				-- * selection_mode: eg 'v'
				-- and should return true of false
				include_surrounding_whitespace = false,
			},
		},
	},
	config = function(_, opts)
		local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
		-- parser_config.latexconceal = {
		-- 	install_info = {
		-- 		url = "~/tree-sitter-latexconceal", -- local path or git repo
		-- 		files = { "src/parser.c" }, -- note that some parsers also require src/scanner.c or src/scanner.cc
		-- 		-- optional entries:
		-- 		branch = "main", -- default branch in case of git repo if different from master
		-- 		generate_requires_npm = false, -- if stand-alone parser without npm dependencies
		-- 		requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
		-- 	},
		-- filetype = "latexconceal", -- if filetype does not match the parser name
		-- }
		require("nvim-treesitter.configs").setup(opts)
		vim.keymap.set("n", "<leader>op", "<cmd>InspectTree<cr><cmd>EditQuery<cr>", { desc = "Open Playground" })
		vim.keymap.set("n", "<leader>ut", "<cmd>TSToggle<cr>", { desc = "Toggle Treesitter" })
	end,
}
