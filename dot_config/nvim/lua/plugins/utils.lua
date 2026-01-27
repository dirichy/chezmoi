-- local function preview_hydra()
-- 	local Hydra = require("hydra")
-- 	Hydra({
-- 		name = "Oil Preview",
-- 		mode = "n",
-- 		body = "<localleader>",
-- 		hint = "<localleader>(j|k)",
-- 		config = { buffer = true },
-- 		heads = {
-- 			{
-- 				"j",
-- 				function()
-- 					require("oil.actions").preview_scroll_down.callback()
-- 				end,
-- 				{ desc = "" },
-- 			},
-- 			{
-- 				"k",
-- 				function()
-- 					require("oil.actions").preview_scroll_up.callback()
-- 				end,
-- 				{ desc = "" },
-- 			},
-- 		},
-- 	})
-- end
return {
	{
		vim.fn.isdirectory(vim.env.HOME .. "/imselect.nvim/") == 0 and "dirichy/imselect.nvim",
		dir = vim.fn.isdirectory(vim.env.HOME .. "/imselect.nvim/") == 1 and vim.env.HOME .. "/imselect.nvim",
		config = true,
	},
	{
		"m4xshen/hardtime.nvim",
		lazy = false,
		dependencies = { "MunifTanjim/nui.nvim" },
		opts = {
			showmode = false,
			max_count = 4,
			disable_mouse = false,
			restriction_mode = "hint",
			disabled_keys = {
				["<Up>"] = false,
				["<Down>"] = false,
				["<Left>"] = false,
				["<Right>"] = false,
			},
		},
	},
	{
		"stevearc/oil.nvim",
		---@module 'oil'
		---@type oil.SetupOpts

		keys = {
			{
				"-",
				function()
					-- require("oil").open(nil, nil, preview_hydra)
					require("oil").open(nil, nil, nil)
				end,
				desc = "Open parent directory",
			},
		},
		-- Optional dependencies
		-- dependencies = { { "echasnovski/mini.icons", opts = {} } },
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
		-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
		lazy = false,
		config = function()
			require("oil").setup({
				-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
				-- Set to false if you want some other plugin (e.g. netrw) to open when you edit directories.
				default_file_explorer = true,
				-- Id is automatically added at the beginning, and name at the end
				-- See :help oil-columns
				columns = {
					"icon",
					-- "permissions",
					"size",
					"mtime",
				},
				-- Buffer-local options to use for oil buffers
				buf_options = {
					buflisted = false,
					bufhidden = "hide",
				},
				-- Window-local options to use for oil buffers
				win_options = {
					wrap = false,
					signcolumn = "no",
					cursorcolumn = false,
					foldcolumn = "0",
					spell = false,
					list = false,
					conceallevel = 3,
					concealcursor = "nvic",
				},
				-- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
				delete_to_trash = true,
				-- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
				skip_confirm_for_simple_edits = false,
				-- Selecting a new/moved/renamed file or directory will prompt you to save changes first
				-- (:help prompt_save_on_select_new_entry)
				prompt_save_on_select_new_entry = true,
				-- Oil will automatically delete hidden buffers after this delay
				-- You can set the delay to false to disable cleanup entirely
				-- Note that the cleanup process only starts when none of the oil buffers are currently displayed
				cleanup_delay_ms = 2000,
				lsp_file_methods = {
					-- Enable or disable LSP file operations
					enabled = true,
					-- Time to wait for LSP file operations to complete before skipping
					timeout_ms = 1000,
					-- Set to true to autosave buffers that are updated with LSP willRenameFiles
					-- Set to "unmodified" to only save unmodified buffers
					autosave_changes = false,
				},
				-- Constrain the cursor to the editable parts of the oil buffer
				-- Set to `false` to disable, or "name" to keep it on the file names
				constrain_cursor = "editable",
				-- Set to true to watch the filesystem for changes and reload oil
				watch_for_changes = false,
				-- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
				-- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
				-- Additionally, if it is a string that matches "actions.<name>",
				-- it will use the mapping at require("oil.actions").<name>
				-- Set to `false` to remove a keymap
				-- See :help oil-actions for a list of all available actions
				keymaps = {
					["<localleader>?"] = { "actions.show_help", mode = "n" },
					["<CR>"] = "actions.select",
					["<localleader>v"] = { "actions.select", opts = { vertical = true } },
					["<localleader>s"] = { "actions.select", opts = { horizontal = true } },
					["<localleader>t"] = { "actions.select", opts = { tab = true } },
					["<localleader>p"] = "actions.preview",
					["<localleader>q"] = { "actions.close", mode = "n" },
					["<localleader>r"] = "actions.refresh",
					["<F5>"] = "actions.refresh",
					["<C-c>"] = { "actions.close", mode = "n" },
					["-"] = { "actions.parent", mode = "n" },
					["<localleader>b"] = { "actions.parent", mode = "n" },
					["_"] = { "actions.open_cwd", mode = "n" },
					["<localleader>c"] = { "actions.open_cwd", mode = "n" },
					["`"] = { "actions.cd", mode = "n" },
					["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
					["S"] = { "actions.change_sort", mode = "n" },
					["gx"] = "actions.open_external",
					["<localleader>h"] = { "actions.toggle_hidden", mode = "n" },
					["g\\"] = { "actions.toggle_trash", mode = "n" },
					["<C-h>"] = false,
					["<C-l>"] = false,
				},
				-- Set to false to disable all of the above keymaps
				use_default_keymaps = true,
				view_options = {
					-- Show files and directories that start with "."
					show_hidden = false,
					-- This function defines what is considered a "hidden" file
					is_hidden_file = function(name, bufnr)
						if name == ".." then
							return false
						end
						local m = name:match("^%.")
						return m ~= nil
					end,
					-- This function defines what will never be shown, even when `show_hidden` is set
					is_always_hidden = function(name, bufnr)
						return name == ".DS_Store"
					end,
					-- Sort file names with numbers in a more intuitive order for humans.
					-- Can be "fast", true, or false. "fast" will turn it off for large directories.
					natural_order = "fast",
					-- Sort file and directory names case insensitive
					case_insensitive = false,
					sort = {
						-- sort order can be "asc" or "desc"
						-- see :help oil-columns to see which columns are sortable
						{ "type", "asc" },
						{ "name", "asc" },
					},
					-- Customize the highlight group for the file name
					highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
						return nil
					end,
				},
				-- Extra arguments to pass to SCP when moving/copying files over SSH
				extra_scp_args = {},
				-- EXPERIMENTAL support for performing file operations with git
				git = {
					-- Return true to automatically git add/mv/rm files
					add = function(path)
						return false
					end,
					mv = function(src_path, dest_path)
						return false
					end,
					rm = function(path)
						return false
					end,
				},
				-- Configuration for the floating window in oil.open_float
				float = {
					-- Padding around the floating window
					padding = 2,
					-- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
					max_width = 0,
					max_height = 0,
					border = "rounded",
					win_options = {
						winblend = 0,
					},
					-- optionally override the oil buffers window title with custom function: fun(winid: integer): string
					get_win_title = nil,
					-- preview_split: Split direction: "auto", "left", "right", "above", "below".
					preview_split = "auto",
					-- This is the config that will be passed to nvim_open_win.
					-- Change values here to customize the layout
					override = function(conf)
						return conf
					end,
				},
				-- Configuration for the file preview window
				preview_win = {
					-- Whether the preview window is automatically updated when the cursor is moved
					update_on_cursor_moved = true,
					-- How to open the preview window "load"|"scratch"|"fast_scratch"
					preview_method = "fast_scratch",
					-- A function that returns true to disable preview on a file e.g. to avoid lag
					disable_preview = function(filename)
						return false
					end,
					-- Window-local options to use for preview window buffers
					win_options = {},
				},
				-- Configuration for the floating action confirmation window
				confirmation = {
					-- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
					-- min_width and max_width can be a single value or a list of mixed integer/float types.
					-- max_width = {100, 0.8} means "the lesser of 100 columns or 80% of total"
					max_width = 0.9,
					-- min_width = {40, 0.4} means "the greater of 40 columns or 40% of total"
					min_width = { 40, 0.4 },
					-- optionally define an integer/float for the exact width of the preview window
					width = nil,
					-- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
					-- min_height and max_height can be a single value or a list of mixed integer/float types.
					-- max_height = {80, 0.9} means "the lesser of 80 columns or 90% of total"
					max_height = 0.9,
					-- min_height = {5, 0.1} means "the greater of 5 columns or 10% of total"
					min_height = { 5, 0.1 },
					-- optionally define an integer/float for the exact height of the preview window
					height = nil,
					border = "rounded",
					win_options = {
						winblend = 0,
					},
				},
				-- Configuration for the floating progress window
				progress = {
					max_width = 0.9,
					min_width = { 40, 0.4 },
					width = nil,
					max_height = { 10, 0.9 },
					min_height = { 5, 0.1 },
					height = nil,
					border = "rounded",
					minimized_border = "none",
					win_options = {
						winblend = 0,
					},
				},
				-- Configuration for the floating SSH window
				ssh = {
					border = "rounded",
				},
				-- Configuration for the floating keymaps help window
				keymaps_help = {
					border = "rounded",
				},
			})
		end,
	},
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		keys = {
			{
				"<leader>og",
				function()
					require("snacks").lazygit()
				end,
				desc = "Open LazyGit",
			},
			{
				"<leader>th",
				function()
					require("snacks").notifier.show_history()
				end,
				desc = "Notify History",
			},
			{
				"<leader>ps",
				function()
					require("snacks").profiler.scratch()
				end,
				desc = "Profiler Scratch Bufer",
			},
			{
				"<leader>e",
				function()
					require("snacks").explorer()
				end,
				desc = "Profiler Scratch Bufer",
			},
		},
		config = function()
			local dashboard_enabled = true
			local stats = vim.uv.fs_stat(vim.fn.argv(0))
			if stats and stats.type == "directory" then
				dashboard_enabled = false
			end
			local Snacks = require("snacks")
			Snacks.setup({
				dashboard = {
					enabled = dashboard_enabled,
					width = 60,
					row = nil, -- dashboard position. nil for center
					col = nil, -- dashboard position. nil for center
					pane_gap = 4, -- empty columns between vertical panes
					autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
					-- These settings are used by some built-in sections
					preset = {
						-- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
						---@type fun(cmd:string, opts:table)|nil
						pick = nil,
						-- Used by the `keys` section to show keymaps.
						-- Set your custom keymaps here.
						-- When using a function, the `items` argument are the default keymaps.
						---@type snacks.dashboard.Item[]
						keys = {
							{
								icon = " ",
								key = "f",
								desc = "Find File",
								action = ":lua Snacks.dashboard.pick('files')",
							},
							{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
							{
								icon = " ",
								key = "g",
								desc = "Find Text",
								action = ":lua Snacks.dashboard.pick('live_grep')",
							},
							{
								icon = " ",
								key = "r",
								desc = "Recent Files",
								action = ":lua Snacks.dashboard.pick('oldfiles')",
							},
							{
								icon = " ",
								key = "c",
								desc = "Config",
								action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
							},
							{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
							{ action = ":Leet", desc = "Leet Code", icon = "󰪚", key = "e" },
							{
								icon = "󰒲 ",
								key = "l",
								desc = "Lazy",
								action = ":Lazy",
								enabled = package.loaded.lazy ~= nil,
							},
							{
								icon = "C",
								key = ".",
								desc = "Current Dir",
								action = ":Oil",
							},
							{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
						},
						-- Used by the `header` section
						header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
					},
					-- item field formatters
					formats = {
						icon = function(item)
							if item.file and item.icon == "file" then
								local filename = item.file:gsub(".*/([^/]*)", "%1")
								local icon, hl = require("nvim-web-devicons").get_icon(filename)
								return { icon, width = 2, hl = hl }
							elseif item.icon == "directory" then
								return { " ", width = 2, hl = "Directory" }
							end
							return { item.icon, width = 2, hl = "icon" }
						end,
						footer = { "%s", align = "center" },
						header = { "%s", align = "center" },
						file = function(item, ctx)
							local fname = vim.fn.fnamemodify(item.file, ":~")
							fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
							if #fname > ctx.width then
								local dir = vim.fn.fnamemodify(fname, ":h")
								local file = vim.fn.fnamemodify(fname, ":t")
								if dir and file then
									file = file:sub(-(ctx.width - #dir - 2))
									fname = dir .. "/…" .. file
								end
							end
							local dir, file = fname:match("^(.*)/(.+)$")
							return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } }
								or { { fname, hl = "file" } }
						end,
					},
					sections = {
						{ section = "header" },
						{ icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
						{ icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
						{ icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
						{ section = "startup" },
					},
				},
				bigfile = {
					enabled = true,
					notify = true, -- show notification when big file detected
					size = 1.5 * 1024 * 1024, -- 1.5MB
					line_length = 10000,
					-- Enable or disable features when big file detected
					---@param ctx {buf: number, ft:string}
					setup = function(ctx)
						vim.g.latex_concealer_disabled = true
						vim.cmd([[NoMatchParen]])
						require("snacks").util.wo(0, { foldmethod = "manual", statuscolumn = "", conceallevel = 0 })
						vim.b.minianimate_disable = true
						vim.schedule(function()
							vim.bo[ctx.buf].syntax = ctx.ft
						end)
					end,
				},
				notifier = { enabled = true },
				quickfile = { enabled = true },
				statuscolumn = { enabled = true },
				words = { enabled = true },
				blame_line = {
					enabled = true,
					width = 0.6,
					height = 0.6,
					border = "rounded",
					title = " Git Blame ",
					title_pos = "center",
					ft = "git",
				},
				---@class snacks.indent.Config
				---@field enabled? boolean
				indent = {
					indent = {
						priority = 1,
						enabled = true, -- enable indent guides
						char = "│",
						only_scope = false, -- only show indent guides of the scope
						only_current = false, -- only show indent guides in the current window
						-- can be a list of hl groups to cycle through
						hl = {
							"SnacksIndent1",
							"SnacksIndent2",
							"SnacksIndent3",
							"SnacksIndent4",
							"SnacksIndent5",
							"SnacksIndent6",
							"SnacksIndent7",
							"SnacksIndent8",
						},
					},
					-- animate scopes. Enabled by default for Neovim >= 0.10
					-- Works on older versions but has to trigger redraws during animation.
					---@class snacks.indent.animate: snacks.animate.Config
					---@field enabled? boolean
					--- * out: animate outwards from the cursor
					--- * up: animate upwards from the cursor
					--- * down: animate downwards from the cursor
					--- * up_down: animate up or down based on the cursor position
					---@field style? "out"|"up_down"|"down"|"up"
					animate = {
						enabled = vim.fn.has("nvim-0.10") == 1,
						style = "out",
						easing = "linear",
						duration = {
							step = 20, -- ms per step
							total = 500, -- maximum duration
						},
					},
					scope = {
						enabled = true, -- enable highlighting the current scope
						priority = 200,
						char = "│",
						underline = false, -- underline the start of the scope
						only_current = false, -- only show scope in the current window
						hl = "SnacksIndentScope", ---@type string|string[] hl group for scopes
					},
					chunk = {
						-- when enabled, scopes will be rendered as chunks, except for the
						-- top-level scope which will be rendered as a scope.
						enabled = false,
						-- only show chunk scopes in the current window
						only_current = false,
						priority = 200,
						hl = "SnacksIndentChunk", ---@type string|string[] hl group for chunk scopes
						char = {
							corner_top = "┌",
							corner_bottom = "└",
							-- corner_top = "╭",
							-- corner_bottom = "╰",
							horizontal = "─",
							vertical = "│",
							arrow = ">",
						},
					},
					-- filter for buffers to enable indent guides
					filter = function(buf)
						return vim.g.snacks_indent ~= false
							and vim.b[buf].snacks_indent ~= false
							and vim.bo[buf].buftype == ""
					end,
				},
				input = {},
				styles = {
					input = {
						backdrop = false,
						position = "float",
						border = "rounded",
						title_pos = "center",
						height = 1,
						width = 60,
						relative = "editor",
						noautocmd = true,
						row = 2,
						-- relative = "cursor",
						-- row = -3,
						-- col = 0,
						wo = {
							winhighlight = "NormalFloat:SnacksInputNormal,FloatBorder:SnacksInputBorder,FloatTitle:SnacksInputTitle",
							cursorline = false,
						},
						bo = {
							filetype = "snacks_input",
							buftype = "prompt",
						},
						--- buffer local variables
						b = {
							completion = false, -- disable blink completions in input
						},
						keys = {
							n_esc = { "<esc>", { "cmp_close", "cancel" }, mode = "n", expr = true },
							i_esc = { "<esc>", { "cmp_close", "stopinsert" }, mode = "i", expr = true },
							i_cr = { "<cr>", { "cmp_accept", "confirm" }, mode = "i", expr = true },
							i_tab = { "<tab>", { "cmp_select_next", "cmp" }, mode = "i", expr = true },
							i_ctrl_w = { "<c-w>", "<c-s-w>", mode = "i", expr = true },
							i_up = { "<up>", { "hist_up" }, mode = { "i", "n" } },
							i_down = { "<down>", { "hist_down" }, mode = { "i", "n" } },
							q = "cancel",
						},
					},
				},
				scroll = {
					animate = {
						duration = { step = 15, total = 250 },
						easing = "linear",
					},
					-- faster animation when repeating scroll after delay
					animate_repeat = {
						delay = 100, -- delay in ms before using the repeat animation
						duration = { step = 5, total = 50 },
						easing = "linear",
					},
					-- what buffers to animate
					filter = function(buf)
						return vim.g.snacks_scroll ~= false
							and vim.b[buf].snacks_scroll ~= false
							and vim.bo[buf].buftype ~= "terminal"
					end,
				},
				picker = {
					prompt = " ",
					sources = { explorer = {
						auto_close = true,
					} },
					focus = "input",
					layout = {
						cycle = true,
						--- Use the default layout or vertical if the window is too narrow
						preset = function()
							return vim.o.columns >= 120 and "default" or "vertical"
						end,
					},
					---@class snacks.picker.matcher.Config
					matcher = {
						fuzzy = true, -- use fuzzy matching
						smartcase = true, -- use smartcase
						ignorecase = true, -- use ignorecase
						sort_empty = false, -- sort results when the search string is empty
						filename_bonus = true, -- give bonus for matching file names (last part of the path)
						file_pos = true, -- support patterns like `file:line:col` and `file:line`
						-- the bonusses below, possibly require string concatenation and path normalization,
						-- so this can have a performance impact for large lists and increase memory usage
						cwd_bonus = false, -- give bonus for matching files in the cwd
						frecency = false, -- frecency bonus
						history_bonus = false, -- give more weight to chronological order
					},
					sort = {
						-- default sort is by score, text length and index
						fields = { "score:desc", "#text", "idx" },
					},
					ui_select = true, -- replace `vim.ui.select` with the snacks picker
					---@class snacks.picker.formatters.Config
					formatters = {
						text = {
							ft = nil, ---@type string? filetype for highlighting
						},
						file = {
							filename_first = false, -- display filename before the file path
							truncate = 40, -- truncate the file path to (roughly) this length
							filename_only = false, -- only show the filename
							icon_width = 2, -- width of the icon (in characters)
							git_status_hl = true, -- use the git status highlight group for the filename
						},
						selected = {
							show_always = false, -- only show the selected column when there are multiple selections
							unselected = true, -- use the unselected icon for unselected items
						},
						severity = {
							icons = true, -- show severity icons
							level = false, -- show severity level
							---@type "left"|"right"
							pos = "left", -- position of the diagnostics
						},
					},
					---@class snacks.picker.previewers.Config
					previewers = {
						diff = {
							builtin = true, -- use Neovim for previewing diffs (true) or use an external tool (false)
							cmd = { "delta" }, -- example to show a diff with delta
						},
						git = {
							builtin = true, -- use Neovim for previewing git output (true) or use git (false)
							args = {}, -- additional arguments passed to the git command. Useful to set pager options usin `-c ...`
						},
						file = {
							max_size = 1024 * 1024, -- 1MB
							max_line_length = 500, -- max line length
							ft = nil, ---@type string? filetype for highlighting. Use `nil` for auto detect
						},
						man_pager = nil, ---@type string? MANPAGER env to use for `man` preview
					},
					---@class snacks.picker.jump.Config
					jump = {
						jumplist = true, -- save the current position in the jumplist
						tagstack = false, -- save the current position in the tagstack
						reuse_win = false, -- reuse an existing window if the buffer is already open
						close = true, -- close the picker when jumping/editing to a location (defaults to true)
						match = false, -- jump to the first match position. (useful for `lines`)
					},
					toggles = {
						follow = "f",
						hidden = "h",
						ignored = "i",
						modified = "m",
						regex = { icon = "R", value = false },
					},
					win = {
						-- input window
						input = {
							keys = {
								-- to close the picker on ESC instead of going to normal mode,
								-- add the following keymap to your config
								-- ["<Esc>"] = { "close", mode = { "n", "i" } },
								["<a-s>"] = { "flash", mode = { "n", "i" } },
								["s"] = { "flash" },
								["/"] = "toggle_focus",
								["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
								["<C-Up>"] = { "history_back", mode = { "i", "n" } },
								["<C-c>"] = { "cancel", mode = "i" },
								["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
								["<CR>"] = { "confirm", mode = { "n", "i" } },
								["<Down>"] = { "list_down", mode = { "i", "n" } },
								-- ["<Esc>"] = "cancel",
								["<leader>e"] = "cancel",
								["<S-CR>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
								["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
								["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
								["<Up>"] = { "list_up", mode = { "i", "n" } },
								["<a-d>"] = { "inspect", mode = { "n", "i" } },
								["<a-f>"] = { "toggle_follow", mode = { "i", "n" } },
								["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },
								["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
								["<a-m>"] = { "toggle_maximize", mode = { "i", "n" } },
								["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
								["<a-w>"] = { "cycle_win", mode = { "i", "n" } },
								["<c-a>"] = { "select_all", mode = { "n", "i" } },
								["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
								["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
								["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
								["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
								["<c-j>"] = { "list_down", mode = { "i", "n" } },
								["<c-k>"] = { "list_up", mode = { "i", "n" } },
								["<c-n>"] = { "list_down", mode = { "i", "n" } },
								["<c-p>"] = { "list_up", mode = { "i", "n" } },
								["<c-q>"] = { "qflist", mode = { "i", "n" } },
								["<c-s>"] = { "edit_split", mode = { "i", "n" } },
								["<c-t>"] = { "tab", mode = { "n", "i" } },
								["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
								["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
								["<c-r>#"] = { "insert_alt", mode = "i" },
								["<c-r>%"] = { "insert_filename", mode = "i" },
								["<c-r><c-a>"] = { "insert_cWORD", mode = "i" },
								["<c-r><c-f>"] = { "insert_file", mode = "i" },
								["<c-r><c-l>"] = { "insert_line", mode = "i" },
								["<c-r><c-p>"] = { "insert_file_full", mode = "i" },
								["<c-r><c-w>"] = { "insert_cword", mode = "i" },
								["<c-w>H"] = "layout_left",
								["<c-w>J"] = "layout_bottom",
								["<c-w>K"] = "layout_top",
								["<c-w>L"] = "layout_right",
								["?"] = "toggle_help_input",
								["G"] = "list_bottom",
								["gg"] = "list_top",
								["j"] = "list_down",
								["k"] = "list_up",
								["q"] = "close",
							},
							b = {
								minipairs_disable = true,
							},
						},
						-- result list window
						list = {
							keys = {
								["<a-s>"] = { "flash", mode = { "n", "i" } },
								["s"] = { "flash" },
								["/"] = "toggle_focus",
								["<2-LeftMouse>"] = "confirm",
								["<CR>"] = "confirm",
								["<Down>"] = "list_down",
								["<leader>e"] = "cancel",
								["<S-CR>"] = { { "pick_win", "jump" } },
								["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },
								["<Tab>"] = { "select_and_next", mode = { "n", "x" } },
								["<Up>"] = "list_up",
								["<a-d>"] = "inspect",
								["<a-f>"] = "toggle_follow",
								["<a-h>"] = "toggle_hidden",
								["<a-i>"] = "toggle_ignored",
								["<a-m>"] = "toggle_maximize",
								["<a-p>"] = "toggle_preview",
								["<a-w>"] = "cycle_win",
								["<c-a>"] = "select_all",
								["<c-b>"] = "preview_scroll_up",
								["<c-d>"] = "list_scroll_down",
								["<c-f>"] = "preview_scroll_down",
								["<c-j>"] = "list_down",
								["<c-k>"] = "list_up",
								["<c-n>"] = "list_down",
								["<c-p>"] = "list_up",
								["<c-q>"] = "qflist",
								["<c-s>"] = "edit_split",
								["<c-t>"] = "tab",
								["<c-u>"] = "list_scroll_up",
								["<c-v>"] = "edit_vsplit",
								["<c-w>H"] = "layout_left",
								["<c-w>J"] = "layout_bottom",
								["<c-w>K"] = "layout_top",
								["<c-w>L"] = "layout_right",
								["?"] = "toggle_help_list",
								["G"] = "list_bottom",
								["gg"] = "list_top",
								["i"] = "focus_input",
								["j"] = "list_down",
								["k"] = "list_up",
								["q"] = "close",
								["zb"] = "list_scroll_bottom",
								["zt"] = "list_scroll_top",
								["zz"] = "list_scroll_center",
							},
							wo = {
								conceallevel = 2,
								concealcursor = "nvc",
							},
						},
						-- preview window
						preview = {
							keys = {
								["<Esc>"] = "cancel",
								["q"] = "close",
								["i"] = "focus_input",
								["<a-w>"] = "cycle_win",
							},
						},
					},
					actions = {
						flash = function(picker)
							require("flash").jump({
								pattern = "^",
								label = { after = { 0, 0 } },
								search = {
									mode = "search",
									exclude = {
										function(win)
											return vim.bo[vim.api.nvim_win_get_buf(win)].filetype
												~= "snacks_picker_list"
										end,
									},
								},
								action = function(match)
									local idx = picker.list:row2idx(match.pos[1])
									picker.list:_move(idx, true, true)
								end,
							})
						end,
					},
					---@class snacks.picker.icons
					icons = {
						files = {
							enabled = true, -- show file icons
							dir = "󰉋 ",
							dir_open = "󰝰 ",
							file = "󰈔 ",
						},
						keymaps = {
							nowait = "󰓅 ",
						},
						tree = {
							vertical = "│ ",
							middle = "├╴",
							last = "└╴",
						},
						undo = {
							saved = " ",
						},
						ui = {
							live = "󰐰 ",
							hidden = "h",
							ignored = "i",
							follow = "f",
							selected = "● ",
							unselected = "○ ",
							-- selected = " ",
						},
						git = {
							enabled = true, -- show git icons
							commit = "󰜘 ", -- used by git log
							staged = "●", -- staged changes. always overrides the type icons
							added = "",
							deleted = "",
							ignored = " ",
							modified = "○",
							renamed = "",
							unmerged = " ",
							untracked = "?",
						},
						diagnostics = {
							Error = " ",
							Warn = " ",
							Hint = " ",
							Info = " ",
						},
						lsp = {
							unavailable = "",
							enabled = " ",
							disabled = " ",
							attached = "󰖩 ",
						},
						kinds = {
							Array = " ",
							Boolean = "󰨙 ",
							Class = " ",
							Color = " ",
							Control = " ",
							Collapsed = " ",
							Constant = "󰏿 ",
							Constructor = " ",
							Copilot = " ",
							Enum = " ",
							EnumMember = " ",
							Event = " ",
							Field = " ",
							File = " ",
							Folder = " ",
							Function = "󰊕 ",
							Interface = " ",
							Key = " ",
							Keyword = " ",
							Method = "󰊕 ",
							Module = " ",
							Namespace = "󰦮 ",
							Null = " ",
							Number = "󰎠 ",
							Object = " ",
							Operator = " ",
							Package = " ",
							Property = " ",
							Reference = " ",
							Snippet = "󱄽 ",
							String = " ",
							Struct = "󰆼 ",
							Text = " ",
							TypeParameter = " ",
							Unit = " ",
							Unknown = " ",
							Value = " ",
							Variable = "󰀫 ",
						},
					},
					---@class snacks.picker.db.Config
					db = {
						-- path to the sqlite3 library
						-- If not set, it will try to load the library by name.
						-- On Windows it will download the library from the internet.
						sqlite3_path = nil, ---@type string?
					},
					---@class snacks.picker.debug
					debug = {
						scores = false, -- show scores in the list
						leaks = false, -- show when pickers don't get garbage collected
						explorer = false, -- show explorer debug info
						files = false, -- show file debug info
						grep = false, -- show file debug info
						proc = false, -- show proc debug info
						extmarks = false, -- show extmarks errors
					},
				},
				explorer = {
					-- replace_netrw = true,
				},
				---@class snacks.image.Config
				-- image = {
				-- 	formats = {
				-- 		"png",
				-- 		"jpg",
				-- 		"jpeg",
				-- 		"gif",
				-- 		"bmp",
				-- 		"webp",
				-- 		"tiff",
				-- 		"heic",
				-- 		"avif",
				-- 		"mp4",
				-- 		"mov",
				-- 		"avi",
				-- 		"mkv",
				-- 		"webm",
				-- 		"pdf",
				-- 	},
				-- 	force = false, -- try displaying the image, even if the terminal does not support it
				-- 	doc = {
				-- 		-- enable image viewer for documents
				-- 		-- a treesitter parser must be available for the enabled languages.
				-- 		enabled = true,
				-- 		-- render the image inline in the buffer
				-- 		-- if your env doesn't support unicode placeholders, this will be disabled
				-- 		-- takes precedence over `opts.float` on supported terminals
				-- 		inline = true,
				-- 		-- render the image in a floating window
				-- 		-- only used if `opts.inline` is disabled
				-- 		float = true,
				-- 		max_width = 80,
				-- 		max_height = 40,
				-- 		-- Set to `true`, to conceal the image text when rendering inline.
				-- 		-- (experimental)
				-- 		---@param lang string tree-sitter language
				-- 		---@param type snacks.image.Type image type
				-- 		conceal = function(lang, type)
				-- 			-- only conceal math expressions
				-- 			return type == "math"
				-- 			-- return false
				-- 		end,
				-- 	},
				-- 	img_dirs = { "img", "images", "assets", "static", "public", "media", "attachments" },
				-- 	-- window options applied to windows displaying image buffers
				-- 	-- an image buffer is a buffer with `filetype=image`
				-- 	wo = {
				-- 		wrap = false,
				-- 		number = false,
				-- 		relativenumber = false,
				-- 		cursorcolumn = false,
				-- 		signcolumn = "no",
				-- 		foldcolumn = "0",
				-- 		list = false,
				-- 		spell = false,
				-- 		statuscolumn = "",
				-- 	},
				-- 	cache = vim.fn.stdpath("cache") .. "/snacks/image",
				-- 	debug = {
				-- 		request = false,
				-- 		convert = false,
				-- 		placement = false,
				-- 	},
				-- 	env = {},
				-- 	-- icons used to show where an inline image is located that is
				-- 	-- rendered below the text.
				-- 	icons = {
				-- 		math = "󰪚 ",
				-- 		chart = "󰄧 ",
				-- 		image = " ",
				-- 	},
				-- 	---@class snacks.image.convert.Config
				-- 	convert = {
				-- 		notify = true, -- show a notification on error
				-- 		---@type snacks.image.args
				-- 		mermaid = function()
				-- 			local theme = vim.o.background == "light" and "neutral" or "dark"
				-- 			return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", theme, "-s", "{scale}" }
				-- 		end,
				-- 		---@type table<string,snacks.image.args>
				-- 		magick = {
				-- 			default = { "{src}[0]", "-scale", "1920x1080>" }, -- default for raster images
				-- 			vector = { "-density", 192, "{src}[0]" }, -- used by vector images like svg
				-- 			math = { "-density", 192, "{src}[0]", "-trim" },
				-- 			pdf = { "-density", 192, "{src}[0]", "-background", "white", "-alpha", "remove", "-trim" },
				-- 		},
				-- 	},
				-- 	math = {
				-- 		enabled = true, -- enable math expression rendering
				-- 		-- in the templates below, `${header}` comes from any section in your document,
				-- 		-- between a start/end header comment. Comment syntax is language-specific.
				-- 		-- * start comment: `// snacks: header start`
				-- 		-- * end comment:   `// snacks: header end`
				-- 		typst = {
				-- 			tpl = [[
				-- 	   #set page(width: auto, height: auto, margin: (x: 2pt, y: 2pt))
				-- 	   #show math.equation.where(block: false): set text(top-edge: "bounds", bottom-edge: "bounds")
				-- 	   #set text(size: 12pt, fill: rgb("${color}"))
				-- 	   ${header}
				-- 	   ${content}]],
				-- 		},
				-- 		latex = {
				-- 			font_size = "Large", -- see https://www.sascha-frank.com/latex-font-size.html
				-- 			-- for latex documents, the doc packages are included automatically,
				-- 			-- but you can add more packages here. Useful for markdown documents.
				-- 			packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools", "fixdif" },
				-- 			tpl = [[
				-- 	   \documentclass[preview,border=0pt,varwidth,12pt]{standalone}
				-- 	   \usepackage{${packages}}
				-- 	   \begin{document}
				-- 	   ${header}
				-- 	   { \${font_size} \selectfont
				-- 	     \color[HTML]{${color}}
				-- 	   ${content}}
				-- 	   \end{document}]],
				-- 		},
				-- 	},
				-- },
			})
			Snacks.toggle.profiler():map("<leader>pp")
			-- Toggle the profiler highlights
			Snacks.toggle.profiler_highlights():map("<leader>ph")
		end,
	},
	{
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		lazy = true,
		config = function()
			require("nvim-web-devicons").setup({
				override_by_extension = {
					["neo-tree"] = {
						icon = "󱏒",
						color = "#bd19e6",
						name = "Neo-tree",
					},
					["log"] = {
						icon = "",
						color = "#81e043",
						name = "log",
					},
					["sty"] = {
						icon = "",
						color = "#006400",
						name = "sty",
					},
					["m"] = {
						icon = "ℳ",
						color = "#ff8000",
						name = "Matlab",
					},
					["fig"] = {
						icon = "",
						color = "#ff8000",
						name = "MatlabFig",
					},
					["aux"] = {
						icon = "",
						color = "#006400",
						name = "aux",
					},
					["norg"] = {
						icon = "",
						color = "#b34fee",
						name = "norg",
					},
					["lazy"] = {
						icon = "󰒲",
						color = "#0d69f2",
						name = "Lazy",
					},
					["tex"] = {
						icon = "",
						color = "#2c8217",
						name = "TeX",
					},
				},
			})
			require("nvim-web-devicons").set_icon_by_filetype({ ["neo-tree"] = "neo-tree", lazy = "lazy" })
		end,
	},
	{
		"monaqa/dial.nvim",
		keys = {
			{ "<c-a>", "<Plug>(dial-increment)" },
			{ "<c-x>", "<Plug>(dial-decrement)" },
		},
		config = function()
			local augend = require("dial.augend")
			require("dial.config").augends:register_group({
				default = {
					augend.integer.alias.decimal_int,
					augend.integer.alias.hex,
					augend.integer.alias.octal,
					augend.integer.alias.binary,
					augend.date.alias["%Y/%m/%d"],
					augend.date.alias["%Y-%m-%d"],
					augend.date.alias["%m/%d"],
					augend.date.alias["%H:%M"],
					augend.date.alias["%Y年%-m月%-d日"],
					augend.constant.new({
						elements = { "and", "or" },
						word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
						cyclic = true, -- "or" is incremented into "and" .
					}),
					augend.constant.new({
						elements = { "Sun", "Mon", "Tue", "Wed", "Tur", "Fri", "Sat" },
						word = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" },
						sord = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
						sord = true,
						cyclic = true,
					}),
					augend.constant.new({
						elements = {
							"星期一",
							"星期二",
							"星期三",
							"星期四",
							"星期五",
							"星期六",
							"星期日",
						},
						sord = true,
						cyclic = true,
					}),
					augend.constant.alias.bool,
					augend.constant.alias.alpha,
					augend.constant.alias.Alpha,
					augend.constant.new({
						elements = { "<", "\\leq", "=", "\\geq", ">", "\\neq" },
						sord = true,
						word = false,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "\\wedge", "\\vee" },
						sord = true,
						word = false,
						cyclic = true,
					}),
					augend.constant.new({
						elements = { "\\forall", "\\exists" },
						sord = true,
						word = false,
						cyclic = true,
					}),
				},
			})
		end,
	},
	{
		"nvimtools/hydra.nvim",
		keys = { "z" },
		config = function()
			local Hydra = require("hydra")
			Hydra.setup({
				debug = false,
				exit = false,
				foreign_keys = nil,
				color = "red",
				timeout = false,
				invoke_on_body = false,
				hint = {
					show_name = true,
					position = { "bottom" },
					offset = 0,
					float_opts = {},
				},
				on_enter = nil,
				on_exit = nil,
				on_key = nil,
			})
			Hydra({
				name = "Move Screen",
				mode = "n",
				body = "z",
				hint = "z(l|h|L|H)",
				config = {},
				heads = {
					{ "l", "zl", { desc = "" } },
					{ "h", "zh", { desc = "" } },
					{ "L", "zL", { desc = "󰜴" } },
					{ "H", "zH", { desc = "󰜱" } },
					{ "j", "<c-e>", { desc = "" } },
					{ "k", "<c-y>", { desc = "" } },
					{ "J", "<c-d>", { desc = "󰜮" } },
					{ "K", "<c-u>", { desc = "󰜷" } },
				},
			})
		end,
	},
	{
		"gbprod/yanky.nvim",
		event = "VeryLazy",
		opts = {
			ring = {
				history_length = 100,
				storage = "shada",
				storage_path = vim.fn.stdpath("data") .. "/databases/yanky.db", -- Only for sqlite storage
				sync_with_numbered_registers = true,
				cancel_event = "update",
				ignore_registers = { "_" },
				update_register_on_cycle = false,
				permanent_wrapper = nil,
			},
			picker = {
				select = {
					action = nil, -- nil to use default put action
				},
				telescope = {
					use_default_mappings = true, -- if default mappings should be used
					mappings = nil, -- nil to use default mappings or no mappings (see `use_default_mappings`)
				},
			},
			system_clipboard = {
				sync_with_ring = true,
				clipboard_register = nil,
			},
			highlight = {
				on_put = true,
				on_yank = true,
				timer = 500,
			},
			preserve_cursor_position = {
				enabled = true,
			},
			textobj = {
				enabled = true,
			},
		},
		keys = {
			{
				"<leader>fy",
				function()
					require("telescope").extensions.yank_history.yank_history({})
				end,
				mode = { "n", "x" },
				desc = "Open Yank History",
			},
        -- stylua: ignore
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
			{ "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Text After Cursor" },
			{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Cursor" },
			{ "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put Text After Selection" },
			{ "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Selection" },
			{ "[y", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
			{ "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },
			{ "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
			{ "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
			{ "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
			{ "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
			{ ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and Indent Right" },
			{ "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and Indent Left" },
			{ ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put Before and Indent Right" },
			{ "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put Before and Indent Left" },
			{ "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put After Applying a Filter" },
			{ "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put Before Applying a Filter" },
		},
	},
	-- {
	-- 	"rainbowhxch/accelerated-jk.nvim",
	-- 	keys = { "j", "k", "h", "l" },
	-- 	config = function()
	-- 		require("accelerated-jk").setup({
	-- 			mode = "time_driven",
	-- 			enable_deceleration = false,
	-- 			acceleration_motions = { "j", "k", "l", "h" },
	-- 			acceleration_limit = 300,
	-- 			acceleration_table = { 7, 10, 13, 15, 17, 18, 19, 20 },
	-- 			-- when 'enable_deceleration = true', 'deceleration_table = { {200, 3}, {300, 7}, {450, 11}, {600, 15}, {750, 21}, {900, 9999} }'
	-- 			deceleration_table = { { 1000, 9999 } },
	-- 		})
	-- 	end,
	-- },
	{
		"folke/persistence.nvim",
		lazy = false,
		-- event = "ExitPre",
		keys = {
			{
				"<leader>qs",
				function()
					--HACK:Nrotree will break nvim-lastplace
					if package.loaded["neo-tree"] then
						vim.cmd([[Neotree close]])
					end
					--HACK: If load session while oil is loading, will cause filetype of file buffer as Oil
					if package.loaded["oil.loading"] then
						local oil_loading = require("oil.loading")
						local buffer = vim.api.nvim_win_get_buf(0)
						local timer = vim.uv.new_timer()
						timer:start(0, 50, function()
							if not oil_loading.is_loading(buffer) then
								vim.schedule(function()
									vim.cmd([[lua require("persistence").load()]])
								end)
								timer:stop()
								timer:close()
							end
						end)
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
	-- {
	-- 	"windwp/nvim-autopairs",
	-- 	event = "InsertEnter",
	-- 	keys = {
	-- 		{
	-- 			"<leader>ua",
	-- 			function()
	-- 				require("nvim-autopairs").toggle()
	-- 			end,
	-- 			desc = "Toggle Autopairs",
	-- 		},
	-- 	},
	-- 	config = function()
	-- 		local npairs = require("nvim-autopairs")
	-- 		local Rule = require("nvim-autopairs.rule")
	-- 		npairs.setup({
	-- 			disable_filetype = { "tex", "latex" },
	-- 			check_ts = true,
	-- 			ts_config = {
	-- 				tex = { "inline_formula", "math_environment", "displayed_equation" },
	-- 				latex = { "inline_formula", "math_environment", "displayed_equation" },
	-- 			},
	-- 		})
	-- 		-- npairs.add_rules({
	-- 		-- 	Rule("``", "''", { "tex", "latex" }),
	-- 		-- })
	-- 	end,
	-- },
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
	{
		"folke/which-key.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({
				icons = {
					rules = {
						{ plugin = "lazygit.nvim", icon = "󰊢", color = "orange" },
						{ plugin = "ccc.nvim", icon = "", color = "yellow" },
						{ plugin = "yazi.nvim", icon = "󰇥", color = "blue" },
						{ plugin = "latex.nvim", cat = "filetype", name = "tex" },
						{ pattern = "mason", icon = "", color = "green" },
						{ pattern = "playground", icon = "󰙨", color = "red" },
					},
				},
				win = {
					no_overlap = false,
				},
			})
			wk.add({
				{ "<leader>n", group = "Noice" },
				{ "<leader>o", group = "Open window" },
				{ "<leader>b", group = "Buffer" },
				{ "<leader>t", group = "LaTeX", icon = { cat = "filetype", name = "tex" } },
				{ "<leader>f", group = "Find", icon = { icon = "", color = "blue" } },
				{ "<leader>q", group = "Session" },
				{ "g", group = "Goto" },
				{ "<leader>u", group = "Toggle" },
				{ "<leader>ot", "<cmd>terminal<cr>", desc = "Open Terminal" },
				{ "<leader>ol", "<cmd>Lazy<cr>", desc = "Open Lazy" },
				-- { "<leader>om", "<cmd>Mason<cr>", desc = "Open Mason(for LSP install)", icon = "" },
			})
			wk.add(require("mapper").which_key_spec)
		end,
	},
	{
		"echasnovski/mini.ai",
		event = { "BufNewFile", "BufRead" },
		config = function()
			local ai = require("mini.ai")
			ai.setup({
				custom_textobjects = require("nvimtex.textobject"),
			})
			vim.g.TEST = function()
				vim.api.nvim_feedkeys("v", "n", true)
				vim.api.nvim_win_set_cursor(0, { 2, 2 })
			end
		end,
	},
	{
		"numToStr/Comment.nvim",
		-- event = "VeryLazy",
		keys = {
			{
				"gcc",
				function()
					return vim.v.count == 0 and "<Plug>(comment_toggle_linewise_current)"
						or "<Plug>(comment_toggle_linewise_count)"
				end,
				expr = true,
				desc = "Comment a line",
			},
			{ "gc", mode = "n", "<Plug>(comment_toggle_linewise)" },
			{ "gc", mode = "x", "<Plug>(comment_toggle_linewise_visual)" },
		},
		config = function()
			require("Comment").setup()
			local ft = require("Comment.ft")
			ft.tex = { "%%s", "\\iffalse\n%s\n\\fi" }
			ft.ly = { "%%s", "%%{ %s %%}" }
		end,
	},
	{
		"s1n7ax/nvim-window-picker",
		opts = {
			hint = "floating-big-letter",
			filter_rules = {
				include_current_win = true,
				bo = {
					filetype = { "fidget", "neo-tree" },
				},
			},
		},
		keys = {
			{
				"<leader>S",
				function()
					local window_number = require("window-picker").pick_window()
					if window_number then
						vim.api.nvim_set_current_win(window_number)
					end
				end,
				desc = "Pick Window",
			},
		},
	},
	{
		"aserowy/tmux.nvim",
		keys = {
			-- { "<C-h>", [[<cmd>lua require("tmux").move_left()<cr>]], desc = "Move Left" },
			-- { "<C-j>", [[<cmd>lua require("tmux").move_bottom()<cr>]] },
			-- { "<C-k>", [[<cmd>lua require("tmux").move_top()<cr>]] },
			-- { "<C-l>", [[<cmd>lua require("tmux").move_right()<cr>]] },
		},
		opts = {
			copy_sync = {
				-- enables copy sync. by default, all registers are synchronized.
				-- to control which registers are synced, see the `sync_*` options.
				enable = true,

				-- ignore specific tmux buffers e.g. buffer0 = true to ignore the
				-- first buffer or named_buffer_name = true to ignore a named tmux
				-- buffer with name named_buffer_name :)
				ignore_buffers = { empty = false },

				-- TMUX >= 3.2: all yanks (and deletes) will get redirected to system
				-- clipboard by tmux
				redirect_to_clipboard = false,

				-- offset controls where register sync starts
				-- e.g. offset 2 lets registers 0 and 1 untouched
				register_offset = 0,

				-- overwrites vim.g.clipboard to redirect * and + to the system
				-- clipboard using tmux. If you sync your system clipboard without tmux,
				-- disable this option!
				sync_clipboard = true,

				-- synchronizes registers *, +, unnamed, and 0 till 9 with tmux buffers.
				sync_registers = true,

				-- syncs deletes with tmux clipboard as well, it is adviced to
				-- do so. Nvim does not allow syncing registers 0 and 1 without
				-- overwriting the unnamed register. Thus, ddp would not be possible.
				sync_deletes = true,

				-- syncs the unnamed register with the first buffer entry from tmux.
				sync_unnamed = true,
			},
			navigation = {
				-- cycles to opposite pane while navigating into the border
				cycle_navigation = true,

				-- enables default keybindings (C-hjkl) for normal mode
				enable_default_keybindings = true,

				-- prevents unzoom tmux when navigating beyond vim border
				persist_zoom = false,
			},
			resize = {
				-- enables default keybindings (A-hjkl) for normal mode
				enable_default_keybindings = true,

				-- sets resize steps for x axis
				resize_step_x = 1,

				-- sets resize steps for y axis
				resize_step_y = 1,
			},
		},
		config = true,
	},
	{
		"kkharji/sqlite.lua",
		lazy = true,
		config = false,
	},
	{
		"ve5li/better-goto-file.nvim",
		config = true,
		---@module "better-goto-file"
		---@type better-goto-file.Options
		opts = {},
		keys = {
			{
				"gf",
				mode = { "n" },
				function()
					require("better-goto-file").goto_file()
				end,
				silent = true,
				desc = "Better go to file under cursor",
			},
			{
				"gf",
				mode = { "v" },
				'<Esc>:lua require("better-goto-file").goto_file_range()<cr>',
				silent = true,
				desc = "Better go to file in selection",
			},
			-- Open in new split.
			{
				"gF",
				mode = { "n" },
				function()
					require("better-goto-file").goto_file({ gf_command = "<C-w>f" })
				end,
				silent = true,
				desc = "Better go to file under cursor in new split",
			},
			{
				"gF",
				mode = { "v" },
				'<Esc>:lua require("better-goto-file").goto_file_range({ gf_command = "<C-w>f" })<cr>',
				silent = true,
				desc = "Better go to file in selection in new split",
			},
			-- -- Open in new tab.
			-- {
			-- 	"<C-w><leader>F",
			-- 	mode = { "n" },
			-- 	function()
			-- 		require("better-goto-file").goto_file({ gf_command = "<C-w>gf" })
			-- 	end,
			-- 	silent = true,
			-- 	desc = "Better go to file under cursor in new tab",
			-- },
			-- {
			-- 	"<C-w><leader>F",
			-- 	mode = { "v" },
			-- 	'<Esc>:lua require("better-goto-file").goto_file_range({ gf_command = "<C-w>gf" })<cr>',
			-- 	silent = true,
			-- 	desc = "Better go to file in selection in new tab",
			-- },
		},
	},
	-- lazy.nvim --
	{ "ngynkvn/gotmpl.nvim", opts = {} },
}
