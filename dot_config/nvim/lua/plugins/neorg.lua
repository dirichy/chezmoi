return {
	-- {
	-- 	"nvim-neorg/neorg",
	-- 	ft = "norg",
	-- 	cmd = "Neorg",
	-- 	keys = {
	-- 		{ "<leader>gj", "<cmd>Neorg journal today<cr>", desc = "Goto Journal" },
	-- 		{ "<localleader>im", "<cmd>Neorg inject-metadata<cr>", desc = "Inject Metadata" },
	-- 		{ "<localleader>is", "<cmd>Neorg generate-workspace-summary<cr>", desc = "Inject Summary" },
	-- 	},
	-- 	version = "*",
	-- 	config = function()
	-- 		require("neorg").setup({
	-- 			load = {
	-- 				["core.defaults"] = {},
	-- 				["core.summary"] = {
	-- 					config = {
	-- 						strategy = "default",
	-- 					},
	-- 				},
	-- 				["core.completion"] = {
	-- 					config = {
	-- 						engine = "nvim-cmp",
	-- 					},
	-- 				},
	-- 				["core.concealer"] = {
	-- 					config = {
	-- 						icons = {
	-- 							heading = {
	-- 								icons = {
	-- 									"☘",
	-- 									"󰄛",
	-- 									"✿",
	-- 									"",
	-- 									"󱁕",
	-- 									"󰧱",
	-- 								},
	-- 							},
	-- 							ordered = {
	-- 								icons = {
	-- 									"1.",
	-- 									"1)",
	-- 									"A.",
	-- 									"A)",
	-- 									"a.",
	-- 									"a)",
	-- 								},
	-- 							},
	-- 						},
	-- 					},
	-- 				},
	-- 				["core.dirman"] = {
	-- 					config = {
	-- 						workspaces = {
	-- 							notes = "~/notes",
	-- 						},
	-- 						default_workspace = "notes",
	-- 					},
	-- 				},
	-- 				["core.qol.todo_items"] = {
	-- 					config = {
	-- 						create_todo_items = true,
	-- 						create_todo_parents = true,
	-- 					},
	-- 				},
	-- 				["core.integrations.image"] = {},
	-- 				["core.export"] = {},
	-- 				["core.export.markdown"] = {},
	-- 			},
	-- 		})
	-- 		vim.wo.foldlevel = 99
	-- 		vim.wo.conceallevel = 2
	-- 		vim.wo.concealcursor = "n"
	-- 	end,
	-- },
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && yarn install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
}
