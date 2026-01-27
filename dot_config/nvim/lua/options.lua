local option = vim.opt
local buffer = vim.b
local global = vim.g
-- Globol Settings --
global.maplocalleader = ","
global.tex_flavor = "latex"
option.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,terminal"
option.foldmethod = "expr"
option.foldexpr = "nvim_treesitter#foldexpr()"
option.foldlevelstart = 99
option.showmode = false
option.backspace = { "indent", "eol", "start" }
option.tabstop = 2
option.shiftwidth = 2
option.expandtab = true
option.shiftround = true
option.autoindent = true
option.smartindent = true
option.number = true
option.relativenumber = true
option.wildmenu = true
option.hlsearch = false
option.confirm = true
option.ignorecase = true
option.smartcase = true
option.completeopt = { "menuone", "noselect" }
option.cursorline = true
option.termguicolors = true
option.signcolumn = "yes"
option.autoread = true
option.title = true
option.swapfile = true
option.backup = false
option.updatetime = 1000
option.mouse = "a"
option.undofile = true
option.undodir = vim.fn.expand("$HOME/.local/share/nvim/undo")
option.exrc = true
option.wrap = false
option.splitright = true
option.scrolloff = 5
option.sidescrolloff = 10
-- Buffer Settings --
buffer.fileenconding = "utf-8"

-- Global Settings --
global.mapleader = " "
local function my_paste(reg)
	return function(lines)
		--[ 返回 “” 寄存器的内容，用来作为 p 操作符的粘贴物 ]
		local content = vim.fn.getreg('"')
		return vim.split(content, "\n")
	end
end

if vim.env.SSH_TTY == nil then
	--[ 当前环境为本地环境，也包括 wsl ]
	option.clipboard:append("unnamedplus")
else
	option.clipboard:append("unnamedplus")
	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = require("vim.ui.clipboard.osc52").copy("+"),
			["*"] = require("vim.ui.clipboard.osc52").copy("*"),
		},
		paste = {
			--[ 小括号里面的内容可能是毫无意义的，但是保持原样可能看起来更好一点 ]
			["+"] = my_paste("+"),
			["*"] = my_paste("*"),
		},
	}
end
