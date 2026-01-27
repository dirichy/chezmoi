local flag = vim.env.XDG_CURRENT_DESKTOP == "Hyprland"
local M = {}
function M.is_border(direction)
	return vim.fn.winnr() == vim.fn.winnr(direction)
end
local direction_table = {
	h = "l",
	l = "r",
	j = "d",
	k = "u",
}
function M.move_to(direction)
	if M.is_border(direction) and flag then
		vim.system({ "hyprlua", 'hypr.window.moveFocusCross("' .. direction .. '")' })
	else
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>" .. direction, true, false, true), "n", false)
	end
end

vim.keymap.set("n", "<C-j>", function()
	M.move_to("j")
end, { desc = "focus in neovim and hyprland" })
vim.keymap.set("n", "<C-k>", function()
	M.move_to("k")
end, { desc = "focus in neovim and hyprland" })
vim.keymap.set("n", "<C-l>", function()
	M.move_to("l")
end, { desc = "focus in neovim and hyprland" })
vim.keymap.set("n", "<C-h>", function()
	M.move_to("h")
end, { desc = "focus in neovim and hyprland" })
return M
