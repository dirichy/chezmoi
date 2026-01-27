-- Example for configuring Neovim to load user-installed installed Lua rocks:
return {
	{
		"tanvirtin/vgit.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
		-- Lazy loading on 'VimEnter' event is necessary.
		keys = {
			{
				"]h",
				function()
					require("vgit").hunk_up()
				end,
				desc = "prev hunk",
				mode = { "n" },
			},
			{
				"[h",
				mode = { "n" },
				function()
					require("vgit").hunk_down()
				end,
				desc = "Go down in the direction of the hunk",
			},
		},
		config = function()
			require("vgit").setup({
				keymaps = {
					["n <leader>gs"] = function()
						require("vgit").buffer_hunk_stage()
					end,
					["n <leader>gr"] = function()
						require("vgit").buffer_hunk_reset()
					end,
					["n <leader>gp"] = function()
						require("vgit").buffer_hunk_preview()
					end,
					["n <leader>gb"] = "buffer_blame_preview",
					["n <leader>gf"] = function()
						require("vgit").buffer_diff_preview()
					end,
					["n <leader>gh"] = function()
						require("vgit").buffer_history_preview()
					end,
					["n <leader>gu"] = function()
						require("vgit").buffer_reset()
					end,
					["n <leader>gd"] = function()
						require("vgit").project_diff_preview()
					end,
					["n <leader>gx"] = function()
						require("vgit").toggle_diff_preference()
					end,
				},
				settings = {
					-- You can either allow corresponding mapping for existing hl, or re-define them yourself entirely.
					hls = {
						GitCount = "Keyword",
						GitSymbol = "CursorLineNr",
						GitTitle = "Directory",
						GitSelected = "QuickfixLine",
						GitBackground = "Normal",
						GitAppBar = "StatusLine",
						GitHeader = "NormalFloat",
						GitFooter = "NormalFloat",
						GitBorder = "LineNr",
						GitLineNr = "LineNr",
						GitComment = "Comment",
						GitSignsAdd = {
							gui = nil,
							fg = "#d7ffaf",
							bg = nil,
							sp = nil,
							override = false,
						},
						GitSignsChange = {
							gui = nil,
							fg = "#7AA6DA",
							bg = nil,
							sp = nil,
							override = false,
						},
						GitSignsDelete = {
							gui = nil,
							fg = "#e95678",
							bg = nil,
							sp = nil,
							override = false,
						},
						GitSignsAddLn = "DiffAdd",
						GitSignsDeleteLn = "DiffDelete",
						GitWordAdd = {
							gui = nil,
							fg = nil,
							bg = "#5d7a22",
							sp = nil,
							override = false,
						},
						GitWordDelete = {
							gui = nil,
							fg = nil,
							bg = "#960f3d",
							sp = nil,
							override = false,
						},
						GitConflictCurrentMark = "DiffAdd",
						GitConflictAncestorMark = "Visual",
						GitConflictIncomingMark = "DiffChange",
						GitConflictCurrent = "DiffAdd",
						GitConflictAncestor = "Visual",
						GitConflictMiddle = "Visual",
						GitConflictIncoming = "DiffChange",
					},
					live_blame = {
						enabled = true,
						format = function(blame, git_config)
							local config_author = git_config["user.name"]
							local author = blame.author
							if config_author == author then
								author = "You"
							end
							local time = os.difftime(os.time(), blame.author_time) / (60 * 60 * 24 * 30 * 12)
							local time_divisions = {
								{ 1, "years" },
								{ 12, "months" },
								{ 30, "days" },
								{ 24, "hours" },
								{ 60, "minutes" },
								{ 60, "seconds" },
							}
							local counter = 1
							local time_division = time_divisions[counter]
							local time_boundary = time_division[1]
							local time_postfix = time_division[2]
							while time < 1 and counter ~= #time_divisions do
								time_division = time_divisions[counter]
								time_boundary = time_division[1]
								time_postfix = time_division[2]
								time = time * time_boundary
								counter = counter + 1
							end
							local commit_message = blame.commit_message
							if not blame.committed then
								author = "You"
								commit_message = "Uncommitted changes"
								return string.format(" %s • %s", author, commit_message)
							end
							local max_commit_message_length = 255
							if #commit_message > max_commit_message_length then
								commit_message = commit_message:sub(1, max_commit_message_length) .. "..."
							end
							return string.format(
								" %s, %s • %s",
								author,
								string.format(
									"%s %s ago",
									time >= 0 and math.floor(time + 0.5) or math.ceil(time - 0.5),
									time_postfix
								),
								commit_message
							)
						end,
					},
					live_gutter = {
						enabled = true,
						edge_navigation = true, -- This allows users to navigate within a hunk
					},
					scene = {
						diff_preference = "unified", -- unified or split
						keymaps = {
							quit = "q",
						},
					},
					diff_preview = {
						keymaps = {
							reset = "r",
							buffer_stage = "S",
							buffer_unstage = "U",
							buffer_hunk_stage = "s",
							buffer_hunk_unstage = "u",
							toggle_view = "t",
						},
					},
					project_diff_preview = {
						keymaps = {
							commit = "C",
							buffer_stage = "s",
							buffer_unstage = "u",
							buffer_hunk_stage = "gs",
							buffer_hunk_unstage = "gu",
							buffer_reset = "r",
							stage_all = "S",
							unstage_all = "U",
							reset_all = "R",
						},
					},
					project_stash_preview = {
						keymaps = {
							add = "A",
							apply = "a",
							pop = "p",
							drop = "d",
							clear = "C",
						},
					},
					project_logs_preview = {
						keymaps = {
							previous = "-",
							next = "=",
						},
					},
					project_commit_preview = {
						keymaps = {
							save = "S",
						},
					},
					signs = {
						priority = 10,
						definitions = {
							-- The sign definitions you provide will automatically be instantiated for you.
							GitConflictCurrentMark = {
								linehl = "GitConflictCurrentMark",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitConflictAncestorMark = {
								linehl = "GitConflictAncestorMark",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitConflictIncomingMark = {
								linehl = "GitConflictIncomingMark",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitConflictCurrent = {
								linehl = "GitConflictCurrent",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitConflictAncestor = {
								linehl = "GitConflictAncestor",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitConflictMiddle = {
								linehl = "GitConflictMiddle",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitConflictIncoming = {
								linehl = "GitConflictIncoming",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitSignsAddLn = {
								linehl = "GitSignsAddLn",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitSignsDeleteLn = {
								linehl = "GitSignsDeleteLn",
								texthl = nil,
								numhl = nil,
								icon = nil,
								text = "",
							},
							GitSignsAdd = {
								texthl = "GitSignsAdd",
								numhl = nil,
								icon = nil,
								linehl = nil,
								text = "┃",
							},
							GitSignsDelete = {
								texthl = "GitSignsDelete",
								numhl = nil,
								icon = nil,
								linehl = nil,
								text = "┃",
							},
							GitSignsChange = {
								texthl = "GitSignsChange",
								numhl = nil,
								icon = nil,
								linehl = nil,
								text = "┃",
							},
						},
						usage = {
							-- Please ensure these signs are defined.
							screen = {
								add = "GitSignsAddLn",
								remove = "GitSignsDeleteLn",
								conflict_current_mark = "GitConflictCurrentMark",
								conflict_current = "GitConflictCurrent",
								conflict_middle = "GitConflictMiddle",
								conflict_incoming_mark = "GitConflictIncomingMark",
								conflict_incoming = "GitConflictIncoming",
								conflict_ancestor_mark = "GitConflictAncestorMark",
								conflict_ancestor = "GitConflictAncestor",
							},
							main = {
								add = "GitSignsAdd",
								remove = "GitSignsDelete",
								change = "GitSignsChange",
							},
						},
					},
					symbols = {
						void = "⣿",
						open = "",
						close = "",
					},
				},
			})
		end,
	},
	{
		"HakonHarnes/img-clip.nvim",
		opts = {
			-- add options here
			-- or leave it empty to use the default settings
		},
		keys = {
			-- suggested keymap
			{
				"<leader>p",
				function()
					local name = os.time()
					require("img-clip").paste_image({ use_absolute_path = false, file_name = tonumber(name) .. ".png" })
				end,
				desc = "Paste image from system clipboard",
			},
		},
		enabled = not vim.uv.os_uname().release:match("android"),
	},
	{
		"3rd/image.nvim",
		enabled = not vim.env.SSH_TTY and not vim.uv.os_uname().release:match("android"),
		lazy = true,
		config = function()
			-- default config
			-- package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
			-- package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"
			require("image").setup({
				backend = "kitty",
				integrations = {
					markdown = {
						enabled = true,
						clear_in_insert_mode = false,
						download_remote_images = true,
						only_render_image_at_cursor = false,
						filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
					},
					neorg = {
						enabled = true,
						clear_in_insert_mode = false,
						download_remote_images = true,
						only_render_image_at_cursor = false,
						filetypes = { "norg" },
					},
					html = {
						enabled = false,
					},
					css = {
						enabled = false,
					},
				},
				max_width = nil,
				max_height = nil,
				max_width_window_percentage = nil,
				max_height_window_percentage = 50,
				window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
				window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
				editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
				tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
				hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
			})
		end,
	},
}
