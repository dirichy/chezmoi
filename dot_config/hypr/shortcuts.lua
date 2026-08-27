local M = {}

M.terminal_apps = {
	"kitty",
	"foot",
	"footclient",
	"alacritty",
	"Alacritty",
	"wezterm",
	"org.wezfurlong.wezterm",
	"ghostty",
	"Ghostty",
	"com.mitchellh.ghostty",
	"konsole",
	"gnome-terminal",
	"org.gnome.Console",
	"mate-terminal",
	"qterminal",
	"ptyxis",
	"xfce4-terminal",
	"xterm",
	"urxvt",
	"st",
	"terminator",
	"tilix",
	"rio",
	"tabby",
	"hyper",
}

function M.bind_primary(kmap, key, trigger_mod, target_key)
	target_key = target_key or key
	local in_terminal = kmap.condition.application(M.terminal_apps)
	kmap.bind(key, trigger_mod, { target_key, kmap.modifier.CTRL + kmap.modifier.SHIFT }, in_terminal)
	kmap.bind(key, trigger_mod, { target_key, kmap.modifier.CTRL }, nil, 1)
end

function M.bind_terminal_primary(kmap, key, trigger_mod, target_key)
	target_key = target_key or key
	local in_terminal = kmap.condition.application(M.terminal_apps)
	kmap.bind(key, trigger_mod, { target_key, kmap.modifier.CTRL + kmap.modifier.SHIFT }, in_terminal)
end

return M
