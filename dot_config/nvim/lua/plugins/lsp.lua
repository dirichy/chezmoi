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
		"mason-org/mason.nvim",
		cmd = "Mason",
		keys = {
			{ "<leader>om", "<cmd>Mason<cr>", desc = "Open Mason" },
		},
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"folke/neoconf.nvim",
			"barreiroleo/ltex_extra.nvim",
			{
				"j-hui/fidget.nvim",
				tag = "v1.4.5",
			},
			"nvimdev/lspsaga.nvim",
		},
		keys = {
			{
				"<leader>dd",
				function()
					local current = vim.diagnostic.config().virtual_lines
					vim.diagnostic.config({ virtual_lines = not current })
				end,
				desc = "Toggle diagnostic virtual lines",
			},
			{
				"<leader>tc",
				function()
					vim.lsp.enable("ltex")
					require("ltex_extra").setup({})
				end,
				desc = "Start LTeX",
			},
		},
		config = function()
			require("neoconf").setup({})

			require("fidget").setup({
				progress = {
					ignore = { "ltex" },
				},
			})

			require("lspsaga").setup({
				ui = {
					border = "rounded",
				},
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

			vim.diagnostic.config({
				virtual_text = true,
				virtual_lines = false,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = {
					border = "rounded",
					source = true,
				},
			})

			-- 所有 LSP attach 后都设置这些 buffer-local 快捷键
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
				callback = function(event)
					local bufnr = event.buf
					local client = vim.lsp.get_client_by_id(event.data.client_id)

					local nmap = function(keys, func, desc)
						vim.keymap.set("n", keys, func, {
							buffer = bufnr,
							desc = desc and ("LSP: " .. desc) or nil,
							silent = true,
						})
					end

					nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					nmap("gd", function()
						require("telescope.builtin").lsp_definitions()
					end, "[G]oto [D]efinition")

					nmap("gi", function()
						require("telescope.builtin").lsp_implementations()
					end, "[G]oto [I]mplementation")

					nmap("<leader>fr", function()
						require("telescope.builtin").lsp_references()
					end, "[F]ind [R]eferences")

					nmap("<leader>fd", function()
						require("telescope.builtin").diagnostics()
					end, "[F]ind [D]iagnostics")

					nmap("K", vim.lsp.buf.hover, "Hover Documentation")

					nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
					nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
					nmap("<leader>wl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, "[W]orkspace [L]ist Folders")

					nmap("<leader>rn", "<cmd>Lspsaga rename ++project<cr>", "[R]e[n]ame")
					nmap("<leader>ca", "<cmd>Lspsaga code_action<cr>", "[C]ode [A]ction")

					nmap("<leader>lf", function()
						vim.lsp.buf.format({ async = true })
					end, "[L]SP [F]ormat")

					-- 可以在这里做 server-specific 逻辑
					-- if client and client.name == "clangd" then
					-- clangd 专属设置可以放这里
					-- end
				end,
			})

			local servers = {
				texlab = {},
				lua_ls = {
					settings = {
						Lua = {
							runtime = {
								version = "LuaJIT",
							},
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
							telemetry = {
								enable = false,
							},
						},
					},
				},
				pyright = {},
				jsonls = {},
				marksman = {},
				dockerls = {},
				docker_compose_language_service = {},
				bashls = {},
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
					},
				},

				-- ltex 建议不要默认启动，手动 <leader>tc 再 enable
				ltex = {
					filetypes = {
						"bib",
						"gitcommit",
						"markdown",
						"org",
						"plaintex",
						"rst",
						"rnoweb",
						"tex",
						"pandoc",
					},
				},
			}

			if vim.uv.os_uname().release:match("android") then
				servers.texlab = nil
				servers.clangd = nil
				servers.lua_ls = nil
			end

			local ensure_installed = vim.tbl_keys(servers)

			-- 不让 ltex 自动启用
			local enabled_servers = vim.tbl_filter(function(server)
				return server ~= "ltex"
			end, ensure_installed)

			-- 每个 server 的额外配置
			for server, config in pairs(servers) do
				vim.lsp.config(server, config)
			end

			-- Mason 只负责安装，不负责自动 enable。
			-- 这样启动顺序更可控，不会再出现 clangd 绕过你配置的问题。
			-- require("mason-lspconfig").setup({
			-- 	ensure_installed = ensure_installed,
			-- 	automatic_enable = false,
			-- })

			vim.lsp.enable(enabled_servers)
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
