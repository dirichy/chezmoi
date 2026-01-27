return {
	"saghen/blink.cmp",
	-- optional: provides snippets for the snippet source
	dependencies = { "L3MON4D3/LuaSnip", "MahanRahmati/blink-nerdfont.nvim" },

	event = { "InsertEnter", "CmdlineEnter" },
	-- use a release tag to download pre-built binaries
	version = "*",
	-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
	-- build = 'cargo build --release',
	-- If you use nix, you can build from source using latest nightly rust with:
	-- build = 'nix run .#build-plugin',

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		-- 'default' for mappings similar to built-in completion
		-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
		-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
		-- See the full "keymap" documentation for information on dependenciesfining your own keymap.
		keymap = {
			preset = "enter",
			["<enter>"] = {
				function()
					vim.schedule(function()
						require("luasnip").expand()
					end)
					return require("luasnip").expandable()
				end,
				"accept",
				"fallback_to_mappings",
			},
			["<tab>"] = {
				function()
					if require("luasnip").expandable() then
						vim.schedule(function()
							require("luasnip").expand()
						end)
					end
					if require("luasnip").jumpable(1) then
						vim.schedule(function()
							require("luasnip").jump(1)
						end)
						return true
					else
						return
					end
				end,
				"fallback_to_mappings",
			},
		},
		completion = {
			menu = {
				draw = {},
			},
		},
		cmdline = {
			keymap = {
				preset = "super-tab",
				["<Tab>"] = { "show_and_insert", "select_next" },
				["<S-Tab>"] = { "select_prev" },
			},
			completion = {
				menu = {
					auto_show = false,
				},
			},
		},

		appearance = {
			-- Sets the fallback highlight groups to nvim-cmp's highlight groups
			-- Useful for when your theme doesn't support blink.cmp
			-- Will be removed in a future release
			use_nvim_cmp_as_default = true,
			-- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
			-- Adjusts spacing to ensure icons are aligned
			nerd_font_variant = "mono",
		},

		-- Default list of enabled providers defined so that you can extend it
		-- elsewhere in your config, without redefining it, due to `opts_extend`(
		snippets = { preset = "luasnip" },
		sources = {
			default = { "lsp", "path", "snippets", "buffer", "nvimtex", "math" },
			providers = {
				-- nerdfont = {
				-- 	module = "blink-nerdfont",
				-- 	name = "Nerd Fonts",
				-- 	score_offset = , -- Tune by preference
				-- 	opts = { insert = true }, -- Insert nerdfont icon (default) or complete its name
				-- },
				nvimtex = {
					-- transform_items = function(ctx, items)
					-- 	for _, item in ipairs(items) do
					-- 		item.kind_icon = "E"
					-- 		item.kind_name = "Greek"
					-- 	end
					-- 	return items
					-- end,
					module = "nvimtex.latex.blink",
					name = "nvimtex",
					score_offset = 15, -- Tune by preference
					opts = { insert = true }, -- Insert nerdfont icon (default) or complete its name
				},
				math = {
					-- transform_items = function(ctx, items)
					-- 	for _, item in ipairs(items) do
					-- 		item.kind_icon = "E"
					-- 		item.kind_name = "Greek"
					-- 	end
					-- 	return items
					-- end,
					module = "nvimtex.snip.blink",
					name = "nvimtex_math",
					score_offset = 15, -- Tune by preference
					opts = { insert = true }, -- Insert nerdfont icon (default) or complete its name
				},
			},
		},
	},
	opts_extend = { "sources.default" },
}
