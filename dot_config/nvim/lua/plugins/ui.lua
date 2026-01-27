return {
	{
		"akinsho/bufferline.nvim",
		lazy = false,
		keys = {
			{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
			{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
			{ "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
			{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
			{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
			{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
			{ "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
			{ "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete Buffer" },
		},
		event = "VeryLazy",
		config = function()
			local bufferline = require("bufferline")
			bufferline.setup({
				options = {
					mode = "buffers", -- set to "tabs" to only show tabpages instead
					style_preset = bufferline.style_preset.default, -- or bufferline.style_preset.minimal,
					themable = true, -- allows highlight groups to be overriden i.e. sets highlights as default
					numbers = "buffer_id", --| "both" |"none" | "ordinal" |  function({ ordinal, id, lower, raise }): string,
					close_command = "bdelete! %d", -- can be a string | function, | false see "Mouse actions"
					right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
					left_mouse_command = "buffer d", -- can be a string | function, | false see "Mouse actions"
					middle_mouse_command = nil, -- can be a string | function, | false see "Mouse actions"
					indicator = {
						icon = "▎", -- this should be omitted if indicator style is not 'icon'
						style = "icon", --| 'underline' | 'none',
					},
					buffer_close_icon = "󰅖",
					modified_icon = "●",
					close_icon = "",
					left_trunc_marker = "",
					right_trunc_marker = "",
					--- name_formatter can be used to change the buffer's label in the bufferline.
					--- Please note some names can/will break the
					--- bufferline so use this at your discretion knowing that it has
					--- some limitations that will *NOT* be fixed.
					-- name_formatter = function(buf) -- buf contains:
					--   -- vim.print(buf)
					--   -- name                | str        | the basename of the active file
					--   -- path                | str        | the full path of the active file
					--   -- bufnr (buffer only) | int        | the number of the active buffer
					--   -- buffers (tabs only) | table(int) | the numbers of the buffers in the tab
					--   -- tabnr (tabs only)   | int        | the "handle" of the tab, can be converted to its ordinal number using: `vim.api.nvim_tabpage_get_number(buf.tabnr)`
					-- end,
					max_name_length = 18,
					max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
					truncate_names = true, -- whether or not tab names should be truncated
					tab_size = 18,
					diagnostics = "nvim_lsp", --| "coc"|false,
					diagnostics_update_in_insert = false, -- only applies to coc
					diagnostics_update_on_event = true, -- use nvim's diagnostic handler
					-- The diagnostics indicator can be set to nil to keep the buffer name highlight but delete the highlighting
					diagnostics_indicator = function(count, level, diagnostics_dict, context)
						return "(" .. count .. ")"
					end,
					-- NOTE: this will be called a lot so don't do any heavy processing here
					-- custom_filter = function(buf_number, buf_numbers)
					--     -- filter out filetypes you don't want to see
					--     if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
					--         return true
					--     end
					--     -- filter out by buffer name
					--     if vim.fn.bufname(buf_number) ~= "<buffer-name-I-dont-want>" then
					--         return true
					--     end
					--     -- filter out based on arbitrary rules
					--     -- e.g. filter out vim wiki buffer from tabline in your work repo
					--     if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
					--         return true
					--     end
					--     -- filter out by it's index number in list (don't show first buffer)
					--     if buf_numbers[1] ~= buf_number then
					--         return true
					--     end
					-- end,
					offsets = {
						{
							filetype = "neo-tree",
							text = "neo-tree",
							text_align = "left", -- | "center" | "right"
							highlight = "Directory",
							-- separator = true,
						},
					},
					color_icons = true, --| false, -- whether or not to add the filetype icon highlights
					-- get_element_icon = function(element)
					--   -- element consists of {filetype: string, path: string, extension: string, directory: string}
					--   -- This can be used to change how bufferline fetches the icon
					--   -- for an element e.g. a buffer or a tab.
					--   -- e.g.
					--   local icon, hl = require('nvim-web-devicons').get_icon_by_filetype(element.filetype, { default = false })
					--   return icon, hl
					--   -- or
					--   local custom_map = {my_thing_ft: {icon = "my_thing_icon", hl}}
					--   return custom_map[element.filetype]
					-- end,
					show_buffer_icons = true, --| false, -- disable filetype icons for buffers
					show_buffer_close_icons = true, --| false,
					show_close_icon = true, -- | false,
					show_tab_indicators = true, -- | false,
					show_duplicate_prefix = true, -- | false,   -- whether to show duplicate buffer prefix
					duplicates_across_groups = true, -- whether to consider duplicate paths in different groups as duplicates
					persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
					move_wraps_at_ends = false, -- whether or not the move command "wraps" at the first or last position
					-- can also be a table containing 2 custom separators
					-- [focused and unfocused]. eg: { '|', '|' }
					separator_style = "slope", --"slant" | "slope" | "thick" | "thin" | { 'any', 'any' },
					enforce_regular_tabs = false, --| true,
					always_show_bufferline = true, -- | false,
					auto_toggle_bufferline = true, -- | false,
					hover = {
						enabled = true,
						delay = 200,
						reveal = { "close" },
					},
					sort_by = "insert_after_current", --|'insert_at_end' | 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(
					--     buffer_a, buffer_b)
					--   -- add custom logic
					--   return buffer_a.modified > buffer_b.modified
					-- end
				},
			})
		end,
	},
	-- { "echasnovski/mini.indentscope", version = false, config = true },
	-- {
	-- 	"lukas-reineke/indent-blankline.nvim",
	-- 	-- dependencies = {
	-- 	-- 	"TheGLander/indent-rainbowline.nvim",
	-- 	-- },
	-- 	event = "VeryLazy",
	-- 	main = "ibl",
	-- 	opts = {
	-- 		indent = {
	-- 			char = "│",
	-- 			tab_char = "│",
	-- 		},
	-- 		scope = { show_start = false, show_end = false },
	-- 		exclude = {
	-- 			filetypes = {
	-- 				"help",
	-- 				"alpha",
	-- 				"dashboard",
	-- 				"neo-tree",
	-- 				"Trouble",
	-- 				"trouble",
	-- 				"lazy",
	-- 				"mason",
	-- 				"notify",
	-- 				"toggleterm",
	-- 				"lazyterm",
	-- 			},
	-- 		},
	-- 	},
	-- 	config = function(_, opts)
	-- 		require("ibl").setup(require("indent-rainbowline").make_opts(opts, {
	-- 			color_transparency = 0.3,
	-- 			colors = { 0xff0000, 0x00ff00, 0x8b00ff, 0xffff00, 0x0000ff, 0xffa500, 0x007fff },
	-- 		}))
	-- 	end,
	-- },
	{
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
		config = true,
	},
	-- {
	-- 	"rcarriga/nvim-notify",
	-- 	lazy = true,
	-- 	-- keys = {
	-- 	--   "<leader>un",
	-- 	--   function()
	-- 	--     require("notify").dismiss({ silent = true, pending = true })
	-- 	--   end,
	-- 	--   desc = "Dismiss All Notifications",
	-- 	-- },
	-- 	opts = {
	-- 		background_colour = "NotifyBackground",
	-- 		max_height = function()
	-- 			return math.floor(vim.o.lines * 0.75)
	-- 		end,
	-- 		max_width = function()
	-- 			return math.floor(vim.o.columns * 0.75)
	-- 		end,
	-- 		on_open = function(win)
	-- 			vim.api.nvim_win_set_config(win, { zindex = 100 })
	-- 		end,
	-- 		fps = 30,
	-- 		icons = {
	-- 			DEBUG = "",
	-- 			ERROR = "",
	-- 			INFO = "",
	-- 			TRACE = "✎",
	-- 			WARN = "",
	-- 		},
	-- 		level = 2,
	-- 		minimum_width = 50,
	-- 		render = "compact",
	-- 		stages = "static",
	-- 		time_formats = {
	-- 			notification = "%T",
	-- 			notification_history = "%FT%T",
	-- 		},
	-- 		timeout = 3000,
	-- 		top_down = true,
	-- 	},
	-- 	init = function()
	-- 		-- when noice is not enabled, install notify on VeryLazy
	-- 		vim.api.nvim_create_autocmd("User", {
	-- 			pattern = "VeryLazy",
	-- 			callback = function()
	-- 				vim.notify = require("notify")
	-- 			end,
	-- 			desc = "Use nvim-Notify as default",
	-- 		})
	-- 	end,
	-- },
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			cmdline = {
				enabled = true,
				view = "cmdline",
				format = {
					-- mytest = { pattern = "^:test%s+", icon = "T" },
					input = { view = "cmdline" },
				},
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
				progress = {
					enabled = false,
				},
			},
			routes = {
				{
					filter = {
						event = "msg_show",
						any = {
							{ find = "%d+L, %d+B" },
							{ find = "; after #%d+" },
							{ find = "; before #%d+" },
						},
					},
					view = "mini",
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
		},
    -- stylua: ignore
    keys = {
      -- { "<leader>sn",  "",                                                                            desc = "+noice" },
      { "<S-Enter>",   function() require("noice").redirect(vim.fn.getcmdline()) end,                 mode = "c",                              desc = "Redirect Cmdline" },
      { "<leader>nl", function() require("noice").cmd("last") end,                                   desc = "Noice Last Message" },
      { "<leader>nh", function() require("noice").cmd("history") end,                                desc = "Noice History" },
      { "<leader>na", function() require("noice").cmd("all") end,                                    desc = "Noice All" },
      { "<leader>nd", function() require("noice").cmd("dismiss") end,                                desc = "Dismiss All" },
      { "<leader>nt", function() require("noice").cmd("pick") end,                                   desc = "Noice Picker (Telescope/FzfLua)" },
      { "<c-b>",       function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end,  silent = true,                           expr = true,              desc = "Scroll Forward",  mode = { "i", "n", "s" } },
      { "<c-u>",       function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true,                           expr = true,              desc = "Scroll Backward", mode = { "i", "n", "s" } },
    },
		config = function(_, opts)
			-- HACK: noice shows messages from before it was enabled,
			-- but this is not ideal when Lazy is installing plugins,
			-- so clear the messages in this case.
			if vim.o.filetype == "lazy" then
				vim.cmd([[messages clear]])
			end
			require("noice").setup(opts)
		end,
	},
}
