#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
prepare_source
prepare_lists
if [[ $fixture_os == linux ]]; then
    for list in "$desktop_list" "$headless_list" "$skip_list"; do
        assert_ignored "$list" '.local/bin/fcitx5-remote' 'Linux excludes the macOS Fcitx5.app symlink'
    done
fi
for list in "$desktop_list" "$headless_list" "$skip_list"; do
    assert_managed "$list" '.config/zsh/plugins.zsh' 'Zsh includes explicit plugin loading'
    assert_managed "$list" '.config/zsh/plugin-backend.zsh' 'Zsh includes the preferred download backend'
    assert_managed "$list" '.config/zsh/plugin-repos.txt' 'Zsh includes the shared plugin repository list'
    assert_managed "$list" '.config/zsh/plugin-manager.zsh' 'Zsh includes the optional plugin downloader'
    assert_ignored "$list" '.config/zsh/.zsh_plugins.txt' 'Zsh excludes the Antidote manifest'
done
for list in "$desktop_list" "$headless_list" "$skip_list"; do
    assert_ignored "$list" 'install.sh' 'standalone installer stays out of the destination'
    assert_ignored "$list" '.github/workflows/install-lan.yml' 'CI workflows stay out of the destination'
    for path in install-core-linux.sh install-core-macos.sh install-packages-linux.sh install-packages-macos.sh; do
        assert_ignored "$list" "$path" 'apply does not install packages'
    done
    for path in configure-chezmoi-git-hooks.sh reconcile-user-services.sh check-dependencies.sh prepare-app-resources.sh; do
        assert_managed "$list" "$path" 'apply manages routine maintenance'
    done
done
assert_managed "$headless_list" '.config/mihomo/config.yaml' 'headless includes the core proxy configuration'
pass 'all fixture profiles evaluate .chezmoiignore'

assert_ignored "$desktop_list" '.local/share/fcitx5/rime/lua/exe.lua' 'desktop excludes removed website launcher'
for path in lua/command_menu.lua lua/settings_menu.lua lua/quick_phrase_data.lua lua/quick_phrases.lua lua/quick_phrase_filter.lua lua/menu_selection.lua radical_pinyin.dict.yaml radical_pinyin.schema.yaml radical_pinyin_flypy.schema.yaml lua/tiger/repeat_last.lua lua/tiger/reverse_comment.lua lua/tiger/commit_guard.lua lua/symbol_menu.lua lua/date_commands.lua lua/menu_keys.lua; do
    assert_managed "$desktop_list" ".local/share/fcitx5/rime/$path" "desktop includes $path"
    assert_ignored "$headless_list" ".local/share/fcitx5/rime/$path" "headless excludes $path"
    assert_ignored "$skip_list" ".local/share/fcitx5/rime/$path" "skip excludes $path"
done
assert_managed "$desktop_list" '.local/share/fcitx5/rime/cn_dicts' 'desktop links upstream Ice dictionaries'
assert_managed "$desktop_list" '.local/share/fcitx5/rime/shared_emoji/emoji.txt' 'desktop manages shared Emoji mappings'
assert_managed "$desktop_list" '.local/share/fcitx5/rime/tiger_common.dict.yaml' 'desktop manages generated Tiger common dictionary'
assert_managed "$desktop_list" '.local/share/fcitx5/rime/lua/tiger/simp_table.lua' 'desktop manages generated Tiger shorthand table'
assert_ignored "$headless_list" '.local/share/fcitx5/rime/lua/tiger/simp_table.lua' 'headless excludes Tiger shorthand table'
assert_ignored "$skip_list" '.local/share/fcitx5/rime/lua/tiger/simp_table.lua' 'skip excludes Tiger shorthand table'
assert_managed "$desktop_list" '.local/share/fcitx5/rime/tiger_full.schema.yaml' 'desktop includes Tiger full-character schema'
assert_ignored "$headless_list" '.local/share/fcitx5/rime/tiger_full.schema.yaml' 'headless excludes Tiger schemas'
assert_ignored "$skip_list" '.local/share/fcitx5/rime/tiger_full.schema.yaml' 'skip excludes Tiger schemas'

if [[ $fixture_os == linux ]]; then
    assert_managed "$desktop_list" '.config/waybar/config.jsonc' 'desktop includes Waybar'
    assert_managed "$desktop_list" '.config/hypr/hyprland.lua' 'desktop includes Hyprland'
    assert_managed "$desktop_list" '.local/share/fcitx5/rime/rime_ice_full.schema.yaml' 'desktop includes Rime full-pinyin schema'
    assert_managed "$desktop_list" '.local/bin/copy' 'desktop includes clipboard helper'
    assert_managed "$desktop_list" '.local/bin/osc1337-im' 'desktop includes OSC 1337 input method helper'
    assert_managed "$desktop_list" '.local/bin/later' 'desktop includes one-off task runner'
    assert_managed "$desktop_list" '.config/systemd/user/later.path' 'desktop includes one-off task watcher'
    assert_managed "$desktop_list" '.config/systemd/user/later.service' 'desktop includes one-off task service'
    assert_managed "$desktop_list" '.config/systemd/user/config-share.service' 'desktop includes config sharing service'
    assert_managed "$desktop_list" '.local/share/config-share/mihomo/config.yaml' 'desktop shares Mihomo config'
    assert_managed "$desktop_list" '.local/share/config-share/surfingkeys/config.js' 'desktop shares Surfingkeys config'
    assert_ignored "$desktop_list" '.local/bin/dotfiles-services' 'repository helpers stay out of the deployed bin directory'
    assert_ignored "$desktop_list" '.hammerspoon/init.lua' 'Linux excludes Hammerspoon'
    assert_ignored "$desktop_list" '.config/fdu-connect/config.toml' 'disabled fdu-connect is excluded'

    assert_managed "$headless_list" '.config/nvim/init.lua' 'headless retains Neovim'
    assert_managed "$headless_list" '.local/bin/later' 'headless includes one-off task runner'
    assert_managed "$headless_list" '.config/systemd/user/later.path' 'headless includes one-off task watcher'
    assert_managed "$headless_list" '.config/systemd/user/later.service' 'headless includes one-off task service'
    assert_ignored "$headless_list" '.config/waybar/config.jsonc' 'headless excludes Waybar'
    assert_ignored "$headless_list" '.config/hypr/hyprland.lua' 'headless excludes Hyprland'
    assert_ignored "$headless_list" '.local/bin/osc1337-im' 'headless excludes OSC 1337 input method helper'
    assert_managed "$headless_list" '.config/systemd/user/config-share.service' 'custom sharing includes config sharing service'
    assert_managed "$headless_list" '.local/share/config-share/surfingkeys/config.js' 'custom sharing includes selected config'
    assert_ignored "$headless_list" '.local/share/config-share/mihomo/config.yaml' 'custom sharing excludes unselected config'

    assert_ignored "$skip_list" '.config/nvim/init.lua' 'skip excludes Neovim'
    assert_ignored "$skip_list" '.config/mihomo/config.yaml' 'skip excludes mihomo'
    assert_ignored "$skip_list" '.config/kitty/kitty.conf' 'skip excludes desktop applications'
    assert_ignored "$skip_list" '.local/bin/later' 'skip excludes one-off task runner'
    assert_ignored "$skip_list" '.config/systemd/user/later.path' 'skip excludes one-off task watcher'
    assert_ignored "$skip_list" '.config/systemd/user/config-share.service' 'skip fixture disables config sharing service'
else
    for path in .hammerspoon/init.lua .config/karabiner/karabiner.json .config/yabai/yabairc .config/aerospace/aerospace.toml Library/LaunchAgents/mihomo.plist Library/LaunchAgents/config-share.plist Library/LaunchAgents/fdu-connect.plist .config/fdu-connect/config.toml .local/bin/fcitx5-remote; do
        assert_managed "$desktop_list" "$path" "macOS desktop includes $path"
    done
    for profile in desktop headless skip; do
        list="$tmp_dir/managed-$profile.txt"
        for path in .config/hypr/hyprland.lua .config/waybar/config.jsonc .config/systemd/user/later.path .local/bin/later .config/sunshine/sunshine.conf install-packages-linux.sh install-core-linux.sh; do
            assert_ignored "$list" "$path" "macOS $profile excludes $path"
        done
    done
    assert_managed "$headless_list" '.config/nvim/init.lua' 'macOS headless retains Neovim'
    assert_managed "$headless_list" 'Library/LaunchAgents/config-share.plist' 'macOS headless enables custom sharing'
    assert_managed "$headless_list" '.local/share/config-share/surfingkeys/config.js' 'macOS headless shares selected config'
    assert_ignored "$headless_list" '.local/share/config-share/mihomo/config.yaml' 'macOS headless excludes unselected shared config'
    assert_managed "$headless_list" 'Library/LaunchAgents/mihomo.plist' 'macOS headless includes the core proxy LaunchAgent'
    for profile in headless skip; do
        list="$tmp_dir/managed-$profile.txt"
        for path in .hammerspoon/init.lua .config/karabiner/karabiner.json .config/yabai/yabairc .config/aerospace/aerospace.toml Library/LaunchAgents/fdu-connect.plist .local/bin/fcitx5-remote; do
            assert_ignored "$list" "$path" "macOS $profile excludes $path"
        done
    done
    assert_ignored "$skip_list" '.config/nvim/init.lua' 'macOS skip excludes Neovim'
    assert_ignored "$skip_list" 'Library/LaunchAgents/mihomo.plist' 'macOS skip excludes the proxy LaunchAgent'
    assert_ignored "$skip_list" 'Library/LaunchAgents/config-share.plist' 'macOS skip disables sharing'
fi
