local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
local leader_disabled = false
local pane_im_states = {}

local PERM_ASCII = "perm_ascii"
local TEMP_ASCII = "temp_ascii"
local NON_ASCII = "non_ascii"
local IM_SETTLE_MS = 150

local function current_cwd(pane)
	local uri = pane:get_current_working_dir()
	if not uri then
		return nil
	end
	if type(uri) == "string" then
		return uri:gsub("^file://", "")
	end
	return uri.file_path
end

local function is_nvim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local function home_dir()
	return os.getenv("HOME") or ""
end

local function wezterm_config_dir()
	return home_dir() .. "/.config/wezterm"
end

local function pane_key(pane)
	return pane:pane_id()
end

local function run_command(cmd)
	local ok = pcall(wezterm.run_child_process, cmd)
	return ok
end

local function read_command(cmd)
	local ok, success, stdout = pcall(wezterm.run_child_process, cmd)
	if not ok or not success then
		return nil
	end
	return (stdout or ""):gsub("%s+", "")
end

local function is_im_active()
	wezterm.sleep_ms(IM_SETTLE_MS)
	local output = read_command({ "fcitx5-remote" })
	if output == nil then
		return nil
	end
	return output == "2"
end

local function initialize_im_state(pane)
	local key = pane_key(pane)
	if pane_im_states[key] then
		return pane_im_states[key]
	end

	local active = is_im_active()
	if active == nil then
		return nil
	end

	pane_im_states[key] = active and NON_ASCII or PERM_ASCII
	return pane_im_states[key]
end

local function sync_user_im_change(pane)
	local key = pane_key(pane)
	local state = initialize_im_state(pane)
	local active = is_im_active()
	if state == nil or active == nil then
		return
	end
	local expected_active = state == NON_ASCII

	if active ~= expected_active then
		pane_im_states[key] = active and NON_ASCII or PERM_ASCII
	end
end

local function update_im_state(pane, new_state)
	local key = pane_key(pane)
	if initialize_im_state(pane) == nil then
		return
	end
	sync_user_im_change(pane)

	if new_state == false and pane_im_states[key] == NON_ASCII then
		run_command({ "fcitx5-remote", "-c" })
		pane_im_states[key] = TEMP_ASCII
	elseif new_state == true and pane_im_states[key] == TEMP_ASCII then
		run_command({ "fcitx5-remote", "-o" })
		pane_im_states[key] = NON_ASCII
	end
end

local function handle_im(pane, value)
	if value == "temp_ascii" then
		update_im_state(pane, false)
	elseif value == "restore" then
		update_im_state(pane, true)
	elseif value == "reset" then
		pane_im_states[pane_key(pane)] = nil
	end
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
	LeftArrow = "Left",
	DownArrow = "Down",
	UpArrow = "Up",
	RightArrow = "Right",
}

local function set_tab_bar(window, visible)
	local overrides = window:get_config_overrides() or {}
	overrides.enable_tab_bar = visible
	window:set_config_overrides(overrides)
end

local function toggle_leader_disabled(window)
	leader_disabled = not leader_disabled
	set_tab_bar(window, false)
end

local function is_leader_disabled()
	return leader_disabled
end

local function run_and_hide(action)
	return wezterm.action_callback(function(window, pane)
		window:perform_action(action, pane)
		set_tab_bar(window, false)
	end)
end

local function spawn_command_tab(args, cwd)
	return wezterm.action_callback(function(window, pane)
		window:perform_action(act.SpawnCommandInNewTab({ args = args, cwd = cwd or current_cwd(pane) }), pane)
		set_tab_bar(window, false)
	end)
end

local function with_nvim_passthrough(key, mods, fallback)
	return wezterm.action_callback(function(window, pane)
		if is_nvim(pane) then
			window:perform_action(act.SendKey({ key = key, mods = mods }), pane)
		else
			window:perform_action(fallback, pane)
		end
		set_tab_bar(window, false)
	end)
end

local function spawn_tab_with_cwd()
	return wezterm.action_callback(function(window, pane)
		window:perform_action(act.SpawnCommandInNewTab({ cwd = current_cwd(pane) }), pane)
		set_tab_bar(window, false)
	end)
end

local function activate_tab_or_spawn(target)
	return wezterm.action_callback(function(window, pane)
		local tabs = window:mux_window():tabs()
		if #tabs >= target then
			window:perform_action(act.ActivateTab(target - 1), pane)
		else
			window:perform_action(act.SpawnCommandInNewTab({ cwd = current_cwd(pane) }), pane)
		end
		set_tab_bar(window, false)
	end)
end

local function rename_tab()
	return run_and_hide(act.PromptInputLine({
		description = "Rename tab",
		action = wezterm.action_callback(function(window, _, line)
			if line then
				window:active_tab():set_title(line)
			end
		end),
	}))
end

local function close_other_panes()
	return wezterm.action_callback(function(window, pane)
		local tab = pane:tab()
		if tab == nil then
			set_tab_bar(window, false)
			return
		end

		local active_pane_id = pane:pane_id()
		for _, item in ipairs(tab:panes_with_info()) do
			local item_pane = item.pane
			local item_pane_id = item.pane_id
			if item_pane_id == nil and item_pane ~= nil then
				item_pane_id = item_pane:pane_id()
			end
			if item_pane_id ~= nil and item_pane_id ~= active_pane_id then
				run_command({ "wezterm", "cli", "kill-pane", "--pane-id", tostring(item_pane_id) })
			end
		end
		set_tab_bar(window, false)
	end)
end

local function quick_select(patterns)
	return run_and_hide(act.QuickSelectArgs({
		patterns = patterns,
		scope_lines = 20000,
	}))
end

local hacky_user_commands = {
	["open-tab"] = function(window, pane, cmd_context)
		window:perform_action(act.SwitchToWorkspace({ name = cmd_context.title }), pane)
		wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), cmd_context.title)
	end,
}

wezterm.on("update-right-status", function(window)
	window:set_right_status(window:active_workspace())
end)

wezterm.on("format-tab-title", function(tab)
	local title = tab.tab_title
	if title == "" then
		title = tab.active_pane.title
	end
	local activity = tab.is_active and "" or " "
	return string.format(" %s%d | %s ", activity, tab.tab_index + 1, title)
end)

wezterm.on("user-var-changed", function(window, pane, name, value)
	if name == "hacky-user-command" then
		local cmd_context = wezterm.json_parse(value)
		local handler = hacky_user_commands[cmd_context.cmd]
		if handler then
			handler(window, pane, cmd_context)
		end
		return
	end

	if name == "im" then
		handle_im(pane, value)
		return
	end

	if name == "IME" then
		local overrides = window:get_config_overrides() or {}
		if value == "off" then
			overrides.use_ime = false
		elseif value == "on" then
			overrides.use_ime = true
		end
		window:set_config_overrides(overrides)
	end
end)

config.font = wezterm.font("monospace")
if wezterm.target_triple:find("darwin") then
	config.font_size = 17.0
else
	config.font_size = 15.0
end

config.audible_bell = "Disabled"
config.use_ime = true
config.scrollback_lines = 20000
config.exit_behavior = "Close"
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "SteadyBlock"
config.force_reverse_video_cursor = true
config.bold_brightens_ansi_colors = true
config.inactive_pane_hsb = { saturation = 1.0, brightness = 0.85 }
config.window_background_opacity = 0.85
config.text_background_opacity = 1.0
config.window_padding = {
	left = 2,
	right = 2,
	top = 1,
	bottom = 1,
}

config.enable_tab_bar = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32
config.colors = {
	foreground = "#dddddd",
	background = "#000000",
	cursor_bg = "#ffffff",
	cursor_border = "#ffffff",
	cursor_fg = "#000000",
	selection_bg = "#3b4261",
	selection_fg = "#ffffff",
	split = "#3b4261",
	ansi = {
		"#000000",
		"#cc0403",
		"#19cb00",
		"#cecb00",
		"#0d73cc",
		"#cb1ed1",
		"#0dcdcd",
		"#dddddd",
	},
	brights = {
		"#767676",
		"#f2201f",
		"#23fd00",
		"#fffd00",
		"#1a8fff",
		"#fd28ff",
		"#14ffff",
		"#ffffff",
	},
	tab_bar = {
		background = "#1f2335",
		active_tab = {
			bg_color = "#7aa2f7",
			fg_color = "#1d202f",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#1f2335",
			fg_color = "#a9b1d6",
		},
	},
}

config.disable_default_key_bindings = true
config.keys = {
	{
		key = "f",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			if is_leader_disabled() then
				window:perform_action(act.SendKey({ key = "f", mods = "CTRL" }), pane)
				return
			end
			set_tab_bar(window, true)
			window:perform_action(act.ActivateKeyTable({
				name = "leader",
				one_shot = true,
				timeout_milliseconds = 1000,
			}), pane)
		end),
	},
	{
		key = "F",
		mods = "CTRL|ALT|SHIFT",
		action = wezterm.action_callback(function(window)
			toggle_leader_disabled(window)
		end),
	},
}

config.key_tables = {
	leader = {
		{ key = "g", mods = "CTRL", action = run_and_hide(act.PopKeyTable) },
		{ key = "f", mods = "CTRL", action = run_and_hide(act.SendKey({ key = "f", mods = "CTRL" })) },
		{ key = "?", action = run_and_hide(act.ShowLauncherArgs({ flags = "KEY_ASSIGNMENTS" })) },
		{ key = "s", action = run_and_hide(act.ShowLauncherArgs({ flags = "WORKSPACES" })) },
		{ key = "d", action = run_and_hide(act.DetachDomain("CurrentPaneDomain")) },

		{ key = "i", action = spawn_command_tab({ "btm", "-b" }) },
		{ key = "e", mods = "CTRL", action = spawn_command_tab({ "nvim", wezterm_config_dir() .. "/wezterm.lua" }, wezterm_config_dir()) },
		{ key = "r", mods = "CTRL", action = run_and_hide(act.ReloadConfiguration) },

		{ key = "t", action = spawn_tab_with_cwd() },
		{ key = "r", action = rename_tab() },
		{ key = "n", action = run_and_hide(act.ActivateTabRelative(1)) },
		{ key = "N", action = run_and_hide(act.ActivateTabRelative(-1)) },
		{ key = "b", action = run_and_hide(act.ActivateTabRelative(-1)) },
		{ key = "[", action = run_and_hide(act.ActivateTabRelative(-1)) },
		{ key = "]", action = run_and_hide(act.ActivateTabRelative(1)) },
		{ key = "Tab", action = run_and_hide(act.ActivateLastTab) },
		{ key = "b", mods = "CTRL", action = run_and_hide(act.MoveTabRelative(-1)) },
		{ key = "n", mods = "CTRL", action = run_and_hide(act.MoveTabRelative(1)) },

		{ key = "\\", action = run_and_hide(act.SplitHorizontal({ domain = "CurrentPaneDomain" })) },
		{ key = "_", action = run_and_hide(act.SplitVertical({ domain = "CurrentPaneDomain" })) },
		{ key = "f", action = run_and_hide(act.TogglePaneZoomState) },
		{ key = "S", action = run_and_hide(act.PaneSelect({ mode = "SwapWithActive" })) },
		{ key = "m", action = run_and_hide(act.PaneSelect({ mode = "MoveToNewTab" })) },
		{ key = "q", action = run_and_hide(act.CloseCurrentPane({ confirm = true })) },
		{ key = "Q", action = run_and_hide(act.CloseCurrentTab({ confirm = true })) },
		{ key = "q", mods = "CTRL", action = close_other_panes() },

		{ key = "h", action = with_nvim_passthrough("h", "CTRL", act.ActivatePaneDirection("Left")) },
		{ key = "j", action = with_nvim_passthrough("j", "CTRL", act.ActivatePaneDirection("Down")) },
		{ key = "k", action = with_nvim_passthrough("k", "CTRL", act.ActivatePaneDirection("Up")) },
		{ key = "l", action = with_nvim_passthrough("l", "CTRL", act.ActivatePaneDirection("Right")) },
		{ key = "UpArrow", action = run_and_hide(act.AdjustPaneSize({ direction_keys.UpArrow, 1 })) },
		{ key = "DownArrow", action = run_and_hide(act.AdjustPaneSize({ direction_keys.DownArrow, 1 })) },
		{ key = "LeftArrow", action = run_and_hide(act.AdjustPaneSize({ direction_keys.LeftArrow, 1 })) },
		{ key = "RightArrow", action = run_and_hide(act.AdjustPaneSize({ direction_keys.RightArrow, 1 })) },

		{ key = "Escape", action = run_and_hide(act.ActivateCopyMode) },
		{ key = "y", action = quick_select({ "[^\\r\\n]+" }) },
		{ key = "Y", action = quick_select({ "[^\\r\\n]+" }) },
		{ key = "w", action = quick_select({ "\\S+" }) },
		{ key = "p", action = quick_select({ "(?:~|\\.|/)?(?:[A-Za-z0-9._-]+/)+[A-Za-z0-9._-]+" }) },
		{ key = "u", action = quick_select({ "https?://\\S+" }) },
		{ key = "g", action = quick_select({ "[0-9a-fA-F]{7,40}" }) },
		{ key = "/", action = quick_select({ "[^\\r\\n]+" }) },

		{ key = "1", action = activate_tab_or_spawn(1) },
		{ key = "2", action = activate_tab_or_spawn(2) },
		{ key = "3", action = activate_tab_or_spawn(3) },
		{ key = "4", action = activate_tab_or_spawn(4) },
		{ key = "5", action = activate_tab_or_spawn(5) },
		{ key = "6", action = activate_tab_or_spawn(6) },
		{ key = "7", action = activate_tab_or_spawn(7) },
		{ key = "8", action = activate_tab_or_spawn(8) },
		{ key = "9", action = activate_tab_or_spawn(9) },
		{ key = "0", action = activate_tab_or_spawn(10) },
	},
}

return config
