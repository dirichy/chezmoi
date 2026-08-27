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

local function terminal_nvim()
	return function(win)
		return win
			and win.class == "kitty"
			and type(win.title) == "string"
			and win.title:match("^.* %- Nvim$") ~= nil
	end
end

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

function M.bind_navigation(kmap, wm)
	local in_nvim = terminal_nvim()
	for _, key in ipairs({ "h", "j", "k", "l" }) do
		local direction = key
		local send = { key, kmap.modifier.CTRL }
		kmap.bind(key, kmap.modifier.SUPER, send, in_nvim)
		kmap.bind(key, kmap.modifier.CTRL, send, in_nvim)
		kmap.bind(key, kmap.modifier.CTRL, wm.focus(direction), nil, 1)
	end

	local mouse_bindings = {
		{ "mouse:276", "zen-browser", { "o", kmap.modifier.CTRL } },
		{ "mouse:275", "zen-browser", { "i", kmap.modifier.CTRL } },
		{ "mouse:276", "mpv", { "left" } },
		{ "mouse:275", "mpv", { "right" } },
		{ "mouse:276", "sioyek", { "u", kmap.modifier.CTRL } },
		{ "mouse:275", "sioyek", { "d", kmap.modifier.CTRL } },
		{ "mouse:276", "steam_app_0", { "t" }, function(win)
			return win and win.title == "SecretFlasherManaka"
		end },
	}
	for _, binding in ipairs(mouse_bindings) do
		local condition = binding[4] or kmap.condition.application(binding[2])
		kmap.bind(binding[1], 0, binding[3], condition, nil, { mouse = true })
	end
end

return M
