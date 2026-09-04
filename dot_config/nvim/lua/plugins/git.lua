return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },

		opts = {
			-- 左侧 sign column 的符号
			signs = {
				add = { text = "┃" },
				change = { text = "┃" },
				delete = { text = "▁" },
				topdelete = { text = "▔" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},

			-- 已经 stage 的修改使用独立 signs。
			-- 对学习 Git 很有帮助：你可以直观看出哪些改动已经进入 index。
			signs_staged_enable = true,

			-- 不默认显示 blame，避免界面太乱
			current_line_blame = false,

			on_attach = function(bufnr)
				local gs = require("gitsigns")

				local function map(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, {
						buffer = bufnr,
						silent = true,
						desc = desc,
					})
				end

				----------------------------------------------------------------
				-- 1. 在修改之间移动
				----------------------------------------------------------------

				map("n", "]h", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gs.nav_hunk("next")
					end
				end, "Git: next hunk")

				map("n", "[h", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gs.nav_hunk("prev")
					end
				end, "Git: previous hunk")

				----------------------------------------------------------------
				-- 2. 看当前修改
				----------------------------------------------------------------

				map("n", "<leader>hp", gs.preview_hunk, "Git: preview hunk")

				map("n", "<leader>hi", gs.preview_hunk_inline, "Git: preview hunk inline")

				----------------------------------------------------------------
				-- 3. Stage
				----------------------------------------------------------------

				-- stage 当前整个 hunk
				map("n", "<leader>hs", gs.stage_hunk, "Git: stage hunk")

				-- visual mode：只 stage 选中的几行
				map("v", "<leader>hs", function()
					gs.stage_hunk({
						vim.fn.line("."),
						vim.fn.line("v"),
					})
				end, "Git: stage selected lines")

				-- stage 当前整个文件
				map("n", "<leader>hS", gs.stage_buffer, "Git: stage buffer")

				----------------------------------------------------------------
				-- 4. Reset
				--
				-- 注意：
				-- reset_hunk 会丢掉 working tree 中的修改！
				----------------------------------------------------------------

				map("n", "<leader>hr", gs.reset_hunk, "Git: RESET hunk")

				map("v", "<leader>hr", function()
					gs.reset_hunk({
						vim.fn.line("."),
						vim.fn.line("v"),
					})
				end, "Git: RESET selected lines")

				----------------------------------------------------------------
				-- 5. Diff
				----------------------------------------------------------------

				-- 当前 working tree 和 index 比较
				-- = “哪些东西还没有 stage？”
				map("n", "<leader>hd", gs.diffthis, "Git: diff unstaged changes")

				-- 当前文件和 HEAD 比较
				-- = “从上一次 commit 到现在总共改了什么？”
				map("n", "<leader>hD", function()
					gs.diffthis("@")
				end, "Git: diff against HEAD")

				----------------------------------------------------------------
				-- 6. Blame
				----------------------------------------------------------------

				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, "Git: blame line")

				map("n", "<leader>hB", gs.toggle_current_line_blame, "Git: toggle line blame")

				----------------------------------------------------------------
				-- 7. 把当前 hunk 当作 text object
				----------------------------------------------------------------

				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git: select hunk")
			end,
		},
	},
	{
		"pwntester/octo.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			-- OR 'ibhagwan/fzf-lua',
			"nvim-tree/nvim-web-devicons",
		},
		cmd = "Octo",
		config = function()
			require("octo").setup()
		end,
	},
	---@type LazySpec
}
