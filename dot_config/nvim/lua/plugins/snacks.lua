return {
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
				desc = "Profiler Scratch Buffer",
			},
			{
				"<leader>e",
				function()
					require("snacks").explorer()
				end,
				desc = "Open Explorer",
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
					size = 1 * 1024 * 1024, -- 1.5MB
					line_length = 10000,
					-- Enable or disable features when big file detected
					---@param ctx {buf: number, ft:string}
					setup = function(ctx)
						vim.g.latex_concealer_disabled = true
						vim.g.matchparen_disable = 1
						-- vim.cmd([[NoMatchParen]])
						vim.bo[ctx.buf].syntax = "off"
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
						if vim.env.SSH_TTY then
							return false
						end
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
}
