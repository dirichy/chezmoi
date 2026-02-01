return {
	{ "mfussenegger/nvim-lint" },
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		-- priority = 1001, -- needs to be loaded in first
		config = function()
			require("tiny-inline-diagnostic").setup()
			vim.diagnostic.config({ virtual_text = false }) -- Only if needed in your configuration, if you already have native LSP diagnostics
		end,
	},
	{
		"neovim/nvim-lspconfig",
		keys = {
			{ "<leader>om", "<cmd>Mason<cr>", desc = "Open Mason(LSP install)" },
			{ "<leader>tc", "<cmd>LspStart ltex<cr>", desc = "Start Ltex to check document" },
			{
				"<leader>dd",
				function()
					vim.diagnostic.config({ virtual_lines = not vim.diagnostic.config().virtual_lines })
				end,
			},
		},
		cmd = { "Mason", "Neoconf" },
		event = { "BufReadPre" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig",
			"folke/neoconf.nvim",
			"barreiroleo/ltex_extra.nvim",
			{
				"j-hui/fidget.nvim",
				tag = "v1.4.5",
			},
			"nvimdev/lspsaga.nvim",
		},
		-- config = function()
		-- 	require("mason").setup()
		-- 	require("mason-lspconfig").setup()
		-- 	-- if vim.g.ssh then
		-- 	--   require("chinese.rime").setup_rime()
		-- 	-- end
		-- end,
		-- init = function() end,
		config = function()
			local on_attach = function(client, bufnr)
				-- Enable completion triggered by <c-x><c-o>
				local nmap = function(keys, func, desc)
					if desc then
						desc = "LSP: " .. desc
					end

					vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
				end

				nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
				nmap("gd", function()
					return require("telescope.builtin").lsp_definitions()
				end, "[G]oto [D]efinition")
				-- nmap("K", "<cmd>Lspsaga hover_doc<CR>", "Hover Documentation")
				nmap("gi", function()
					return require("telescope.builtin").lsp_implementations()
				end, "[G]oto [I]mplementation")
				-- nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
				nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
				nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
				nmap("<leader>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, "[W]orkspace [L]ist Folders")
				-- nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
				nmap("<leader>rn", "<cmd>Lspsaga rename ++project<cr>", "[R]e[n]ame")
				nmap("<leader>ca", "<cmd>Lspsaga code_action<CR>", "[C]ode [A]ction")
				nmap("<leader>fd", function()
					return require("telescope.builtin").diagnostics()
				end, "Find Diagnostics")
				nmap("<leader>fr", function()
					return require("telescope.builtin").lsp_references()
				end, "Find References")
				-- nmap('gr', vim.lsp.buf.references, '[G]oto [R]eferences')
			end
			vim.lsp.config("*", { on_attach = on_attach })
			local servers = {
				ltex = {},
				texlab = {},
				lua_ls = {},
				pyright = {},
				jsonls = {},
				marksman = {},
				dockerls = {},
				docker_compose_language_service = {},
				bashls = {},
				clangd = {},
			}
			if vim.uv.os_uname().release:match("android") then
				servers.texlab = nil
				servers.clangd = nil
				servers.lua_ls = nil
			end
			require("neoconf").setup()
			require("fidget").setup({
				progress = {
					ignore = { "ltex" },
				},
			})
			require("lspsaga").setup({
				ui = {
					border = "rounded",
				},
				-- Using barbecue for this instead.
				symbol_in_winbar = {
					enable = false,
				},
				lightbulb = {
					sign = false,
				},
				outline = {
					win_width = 50,
					keys = {
						toggle_or_jump = "<cr>",
					},
				},
			})
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(servers),
				autostart = true,
			})
		end,
	},
	{
		"folke/lazydev.nvim",
		dependencies = {
			{ "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
			{
				"DrKJeff16/wezterm-types",
				lazy = true,
				version = false, -- Get the latest version
			},
		},
		ft = "lua",
		priority = 1000,
		opts = {
			library = {
				"~/.luarocks/lib/lua/5.1/",
				"/opt/homebrew/lib/lua/5.4/",
				{ path = "wezterm-types", mods = { "wezterm" } },
				{ path = "~/Documents/.lib/LuaTeX_Lua-API/library/", words = { "tex" } },
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
				{ path = "~/.hammerspoon/Spoons/EmmyLua.spoon/annotations/", words = { "hs" } },
			},
			enabled = function(root_dir)
				return vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled
			end,
		},
	},
}
