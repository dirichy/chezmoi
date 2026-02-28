-- TODO: aaa
return {
	{
		vim.fn.isdirectory(vim.env.HOME .. "/nvimtex.nvim/") == 0 and "dirichy/nvimtex.nvim",
		dir = vim.fn.isdirectory(vim.env.HOME .. "/nvimtex.nvim/") == 1 and vim.env.HOME .. "/nvimtex.nvim",
		ft = { "tex", "latex" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"m00qek/baleia.nvim",
		},
		keys = {
			{
				"<leader>tv",
				function()
					require("nvimtex.view").view()
				end,
				desc = "View Pdf",
			},
			{
				"<leader>ts",
				function()
					require("nvimtex.view").sync()
				end,
				desc = "sync position via synctex",
			},
			{
				"<leader>tb",
				function()
					vim.cmd.wall()
					require("nvimtex.compile").default()
				end,
				desc = "Compile LaTeX File",
			},
			{
				"<leader>tl",
				function()
					require("nvimtex.compile").showlog()
				end,
				desc = "Show log file",
			},
		},
		config = function()
			require("nvimtex").setup()
			require("luasnip.loaders.from_lua").load({})
			-- 在你的 Neovim 配置文件中（例如 init.lua）
			-- require("nvimtex.latex.telescope")
			-- local telescope = require("telescope")
			--
			-- -- 加载自定义扩展
			-- require("telescope.formula_extension").setup()

			-- our picker function: colors
			local pickers = require("telescope.pickers")
			local finders = require("telescope.finders")
			local conf = require("telescope.config").values
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")
			local colors = function(opts)
				opts = opts or {}
				pickers
					.new(opts, {
						attach_mappings = function(prompt_bufnr, map)
							actions.select_default:replace(function()
								actions.close(prompt_bufnr)
								local selection = action_state.get_selected_entry()
								vim.api.nvim_put({ selection.value }, "", false, true)
							end)
							return true
						end,
						prompt_title = "colors",
						finder = finders.new_table({
							results = require("nvimtex.latex.items"),
							entry_maker = function(entry)
								return {
									value = entry.tex,
									display = entry.alias .. "\t" .. entry.tex,
									ordinal = entry.tex,
								}
							end,
						}),
						sorter = conf.generic_sorter(opts),
					})
					:find()
			end

			-- to execute the function
			-- 配置一个快捷键来调用自定义的扩展
			vim.keymap.set("i", "<C-f>", function()
				colors()
			end, { noremap = true, silent = true, desc = "find snip" })
			vim.keymap.set("n", "<leader>tf", function()
				colors()
			end, { noremap = true, silent = true, desc = "find snip" })
		end,
	},
	{
		enabled = false,
		vim.fn.isdirectory(vim.env.HOME .. "/latex_concealer.nvim/") == 0 and "dirichy/latex_concealer.nvim",
		dir = vim.fn.isdirectory(vim.env.HOME .. "/latex_concealer.nvim/") == 1
			and vim.env.HOME .. "/latex_concealer.nvim",
		ft = { "tex", "latex" },
		keys = {
			{
				"<leader>tc",
				function()
					require("latex_concealer").toggle()
				end,
				desc = "Toggle LaTeX concealer",
			},
			{
				"<leader>ul",
				function()
					require("latex_concealer").toggle()
				end,
				desc = "Toggle LaTeX concealer",
			},
		},
		opts = {},
		config = true,
	},
	{
		"DanielMSussman/motleyLatex.nvim",
		config = true,
	},
	-- {
	-- 	"lervag/vimtex",
	-- 	lazy = false,
	-- },
	-- {
	--   "bamonroe/rnoweb-nvim",
	--   lazy=false,
	--   enabled=false,
	--   dependencies={
	--     "nvim-lua/plenary.nvim"
	--   },
	--   config=true,
	-- }
}
