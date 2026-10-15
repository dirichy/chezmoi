#!/usr/bin/env bash
set -euo pipefail

tests_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$tests_dir/../.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT
export PATH="$tests_dir/mock-bin:$PATH"

case $(uname -s) in
    Linux) fixture_os=linux ;;
    Darwin) fixture_os=macos ;;
    *) printf 'Unsupported test platform\n' >&2; exit 1 ;;
esac


pass_count=0

pass() {
    pass_count=$((pass_count + 1))
    printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

managed_list() {
    local profile=$1
    mkdir -p "$tmp_dir/home-$profile"
    chezmoi \
        --source "$source_dir" \
        --destination "$tmp_dir/home-$profile" \
        --config "$tests_dir/fixtures/$fixture_os-$profile.toml" \
        --cache "$tmp_dir/cache-$profile" \
        --persistent-state "$tmp_dir/state-$profile.boltdb" \
        --refresh-externals=never \
        managed --include files,scripts,symlinks --path-style relative
}

assert_managed() {
    local list=$1 path=$2 description=$3
    grep -Fqx -- "$path" "$list" || fail "$description (missing $path)"
    pass "$description"
}

assert_ignored() {
    local list=$1 path=$2 description=$3
    if grep -Fqx -- "$path" "$list"; then
        fail "$description (unexpected $path)"
    fi
    pass "$description"
}

render_managed_templates() {
    local profile=$1 list=$2 target output
    while IFS= read -r target; do
        output="$tmp_dir/rendered-$profile/${target#/}"
        mkdir -p "$(dirname -- "$output")"
        chezmoi \
            --source "$source_dir" \
            --destination "$tmp_dir/home-$profile" \
            --config "$tests_dir/fixtures/$fixture_os-$profile.toml" \
            --cache "$tmp_dir/cache-$profile" \
            --persistent-state "$tmp_dir/state-$profile.boltdb" \
            --refresh-externals=never \
            --no-tty \
            cat "$tmp_dir/home-$profile/$target" >"$output"
    done <"$list"
}

syntax_checks() {
    local file

    while IFS= read -r -d '' file; do
        case "$file" in
            *.tmpl) continue ;;
        esac
        bash -n "$file" || fail "shell syntax: ${file#"$repo_dir/"}"
    done < <(find "$repo_dir" -type f \( -name '*.sh' -o -name '*.bash' \) -print0)
    pass 'non-template shell files parse with bash'

    if command -v luac >/dev/null 2>&1; then
        while IFS= read -r -d '' file; do
            luac -p "$file" || fail "Lua syntax: ${file#"$repo_dir/"}"
        done < <(find "$repo_dir/scripts/lua" "$repo_dir/dot_hammerspoon" \
            "$repo_dir/dot_config/yazi" -type f -name '*.lua' -print0 2>/dev/null)
        pass 'standalone Lua files parse with luac'
    else
        printf '# skip - luac is not installed\n'
    fi
}

require_command chezmoi
require_command python3
if [[ $fixture_os == macos ]]; then
    require_command zsh
fi

# Render a disposable source copy with all external downloads disabled.
source_dir="$tmp_dir/source"
python3 - "$repo_dir" "$source_dir" <<'PYTHON'
import shutil
import sys
from pathlib import Path
shutil.copytree(sys.argv[1], sys.argv[2], ignore=shutil.ignore_patterns('.git'))
Path(sys.argv[2], '.chezmoiexternal.toml').write_text('')
PYTHON


[[ $(chezmoi --source "$source_dir" \
    --destination "$tmp_dir/home-desktop" \
    --config "$tests_dir/fixtures/$fixture_os-desktop.toml" \
    --cache "$tmp_dir/cache-desktop" \
    --persistent-state "$tmp_dir/state-desktop.boltdb" \
    --refresh-externals=never execute-template \
    '{{ includeTemplate "isIPv4CIDR" "192.168.50.0/24" }}') == true ]] \
    || fail 'valid IPv4 CIDR must pass config sharing validation'
[[ $(chezmoi --source "$source_dir" \
    --destination "$tmp_dir/home-desktop" \
    --config "$tests_dir/fixtures/$fixture_os-desktop.toml" \
    --cache "$tmp_dir/cache-desktop" \
    --persistent-state "$tmp_dir/state-desktop.boltdb" \
    --refresh-externals=never execute-template \
    '{{ includeTemplate "isIPv4CIDR" "192.168.300.0/24" }}') == false ]] \
    || fail 'out-of-range IPv4 octet must fail config sharing validation'
[[ $(chezmoi --source "$source_dir" \
    --destination "$tmp_dir/home-desktop" \
    --config "$tests_dir/fixtures/$fixture_os-desktop.toml" \
    --cache "$tmp_dir/cache-desktop" \
    --persistent-state "$tmp_dir/state-desktop.boltdb" \
    --refresh-externals=never execute-template \
    '{{ includeTemplate "isIPv4CIDR" "192.168.50.0/33" }}') == false ]] \
    || fail 'out-of-range IPv4 prefix must fail config sharing validation'
pass 'config sharing CIDR validation accepts only IPv4 CIDR notation'

safe_stderr="$tmp_dir/hyprctl-safe.stderr"
fallback_output=$(PATH=/usr/bin:/bin \
    "$repo_dir/ignore/bin/hyprctl-safe" \
    '__dotfiles_test_invalid_command__' 'test fallback' \
    2>"$safe_stderr")
[[ ! -s $safe_stderr ]] || fail 'hyprctl-safe must suppress errors'
[[ $fallback_output == 'test fallback' ]] \
    || fail 'hyprctl-safe must print the requested fallback'
pass 'hyprctl-safe returns the requested fallback'

desktop_list="$tmp_dir/managed-desktop.txt"
headless_list="$tmp_dir/managed-headless.txt"
skip_list="$tmp_dir/managed-skip.txt"
managed_list desktop >"$desktop_list"
managed_list headless >"$headless_list"
managed_list skip >"$skip_list"
pass 'all fixture profiles evaluate .chezmoiignore'

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
    assert_managed "$desktop_list" 'install-packages-linux.sh' 'Linux includes Linux install script'
    assert_ignored "$desktop_list" 'install-packages-macos.sh' 'Linux excludes macOS install script'
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
    assert_managed "$desktop_list" 'install-packages-macos.sh' 'macOS includes macOS install script'
    for profile in desktop headless skip; do
        list="$tmp_dir/managed-$profile.txt"
        for path in .config/hypr/hyprland.lua .config/waybar/config.jsonc .config/systemd/user/later.path .local/bin/later .config/sunshine/sunshine.conf install-packages-linux.sh; do
            assert_ignored "$list" "$path" "macOS $profile excludes $path"
        done
    done
    assert_managed "$headless_list" '.config/nvim/init.lua' 'macOS headless retains Neovim'
    assert_managed "$headless_list" 'Library/LaunchAgents/config-share.plist' 'macOS headless enables custom sharing'
    assert_managed "$headless_list" '.local/share/config-share/surfingkeys/config.js' 'macOS headless shares selected config'
    assert_ignored "$headless_list" '.local/share/config-share/mihomo/config.yaml' 'macOS headless excludes unselected shared config'
    for profile in headless skip; do
        list="$tmp_dir/managed-$profile.txt"
        for path in .hammerspoon/init.lua .config/karabiner/karabiner.json .config/yabai/yabairc .config/aerospace/aerospace.toml Library/LaunchAgents/mihomo.plist Library/LaunchAgents/fdu-connect.plist .local/bin/fcitx5-remote; do
            assert_ignored "$list" "$path" "macOS $profile excludes $path"
        done
    done
    assert_ignored "$skip_list" '.config/nvim/init.lua' 'macOS skip excludes Neovim'
    assert_ignored "$skip_list" 'Library/LaunchAgents/config-share.plist' 'macOS skip disables sharing'
fi

render_managed_templates desktop "$desktop_list"
render_managed_templates headless "$headless_list"
render_managed_templates skip "$skip_list"
pass 'all managed files and templates render for every fixture profile'

if [[ $fixture_os == linux ]]; then
    grep -Fq '"height": 32' \
        "$tmp_dir/rendered-desktop/.config/waybar/generated.jsonc" \
        || fail 'Waybar uses the mocked focused monitor dimensions'
    pass 'Waybar uses the mocked focused monitor dimensions'

    grep -Fq 'IPAddressAllow=192.168.50.0/24' \
        "$tmp_dir/rendered-desktop/.config/systemd/user/config-share.service" \
        || fail 'config sharing service restricts clients to configured CIDR'
    pass 'config sharing service restricts clients to configured CIDR'
else
    python3 - "$tmp_dir" <<'PYTHON'
import json
import plistlib
import subprocess
import sys
from pathlib import Path
root = Path(sys.argv[1])
for profile in ('desktop', 'headless', 'skip'):
    rendered = root / f'rendered-{profile}'
    for path in rendered.rglob('*.plist'):
        with path.open('rb') as stream:
            data = plistlib.load(stream)
        assert data['Label'] == path.stem, path
        assert data['ProgramArguments'], path
        assert data['RunAtLoad'] is True, path
    install = rendered / 'install-packages-macos.sh'
    subprocess.run(['zsh', '-n', str(install)], check=True)
rendered = root / 'rendered-desktop'
with (rendered / '.config/karabiner/karabiner.json').open() as stream:
    assert json.load(stream)['profiles']
with (rendered / 'Library/LaunchAgents/config-share.plist').open('rb') as stream:
    args = plistlib.load(stream)['ProgramArguments']
assert args[args.index('--allowed-cidr') + 1] == '192.168.50.0/24'
assert args[args.index('--port') + 1] == '18080'
assert args[0].endswith('/.local/libexec/config-share-server')
PYTHON
    pass 'macOS plists, Karabiner JSON and rendered install scripts validate'
fi

service_calls="$tmp_dir/dotfiles-service-calls"
: >"$service_calls"
DOTFILES_OS=Linux \
DOTFILES_MIHOMO_ENABLED=true \
DOTFILES_SYSTEMCTL="$tests_dir/mock-bin/systemctl" \
DOTFILES_SERVICES_TEST=1 \
DOTFILES_SERVICE_CALLS="$service_calls" \
DOTFILES_CONFIG_SHARE_MODE=all \
DOTFILES_FDU_CONNECT=false \
DOTFILES_CLI_ENABLED=true \
    bash "$repo_dir/ignore/bin/dotfiles-services" --yes >/dev/null
grep -Fq 'systemctl <--user> <disable> <--now> <fdu-connect.service>' "$service_calls" \
    || fail 'service reconciler disables configured-off enabled services'
grep -Fq 'systemctl <--user> <enable> <--now> <later.path>' "$service_calls" \
    || fail 'service reconciler enables configured-on services'
grep -Fq 'systemctl <--user> <enable> <--now> <later.service>' "$service_calls" \
    || fail 'service reconciler enables configured-on oneshot services'
if grep -Fq '<config-share.service>' "$service_calls"; then
    fail 'service reconciler must not change services already in the expected state'
fi
pass 'service reconciler applies only required state changes'

mac_service_home="$tmp_dir/mac-service-home"
mkdir -p "$mac_service_home/Library/LaunchAgents"
: >"$mac_service_home/Library/LaunchAgents/config-share.plist"
: >"$mac_service_home/Library/LaunchAgents/fdu-connect.plist"
: >"$mac_service_home/Library/LaunchAgents/mihomo.plist"
: >"$service_calls"
DOTFILES_OS=Darwin \
DOTFILES_HOME="$mac_service_home" \
DOTFILES_LAUNCHCTL="$tests_dir/mock-bin/launchctl" \
DOTFILES_SERVICE_CALLS="$service_calls" \
DOTFILES_CONFIG_SHARE_MODE=all \
DOTFILES_FDU_CONNECT=false \
DOTFILES_CLI_ENABLED=true \
DOTFILES_MIHOMO_ENABLED=true \
    bash "$repo_dir/ignore/bin/dotfiles-services" --yes >/dev/null
grep -Fq 'launchctl <bootstrap>' "$service_calls" \
    || fail 'macOS service reconciler bootstraps configured-on LaunchAgents'
grep -Fq 'config-share.plist>' "$service_calls" \
    || fail 'macOS service reconciler bootstraps config sharing'
grep -Fq 'launchctl <bootout>' "$service_calls" \
    || fail 'macOS service reconciler boots out configured-off LaunchAgents'
grep -Fq 'launchctl <disable>' "$service_calls" \
    || fail 'macOS service reconciler disables configured-off LaunchAgents'
if grep -Fq '/mihomo>' "$service_calls"; then
    fail 'macOS service reconciler must not change loaded desired LaunchAgents'
fi
pass 'macOS service reconciler uses native launchctl lifecycle operations'

systemctl_plists="$tmp_dir/systemctl-macos-plists"
mkdir -p "$systemctl_plists"
for plist in test disabled stopped; do
    printf '<plist><dict><key>Label</key><string>%s</string></dict></plist>\n' "$plist" \
        >"$systemctl_plists/$plist.plist"
done
: >"$service_calls"
systemctl_macos=(
    env
    SYSTEMCTL_MACOS_TEST=1
    SYSTEMCTL_MACOS_UID=501
    SYSTEMCTL_MACOS_SEARCH_DIRS="$systemctl_plists"
    SYSTEMCTL_MACOS_LAUNCHCTL="$tests_dir/mock-bin/launchctl"
    DOTFILES_SERVICE_CALLS="$service_calls"
    "$repo_dir/ignore/bin/systemctl-macos"
    --user
)
[[ $("${systemctl_macos[@]}" is-active test.service) == active ]] \
    || fail 'macOS systemctl wrapper reports running launchd jobs as active'
[[ $("${systemctl_macos[@]}" is-enabled test.service) == enabled ]] \
    || fail 'macOS systemctl wrapper reports available jobs as enabled'
disabled_output=$("${systemctl_macos[@]}" is-enabled disabled.service 2>/dev/null || true)
[[ $disabled_output == disabled ]] \
    || fail 'macOS systemctl wrapper detects launchd disabled overrides'
"${systemctl_macos[@]}" enable --now stopped.service
"${systemctl_macos[@]}" disable --now test.service
"${systemctl_macos[@]}" restart test.service
grep -Fq 'launchctl <enable> <gui/501/stopped>' "$service_calls" \
    || fail 'macOS systemctl enable clears the launchd disabled override'
[[ $(tail -n 2 "$service_calls" | head -n 1) == 'launchctl <bootout> <gui/501/test>' ]] \
    || fail 'macOS systemctl restart boots out the loaded job first'
[[ $(tail -n 1 "$service_calls") == "launchctl <bootstrap> <gui/501> <$systemctl_plists/test.plist>" ]] \
    || fail 'macOS systemctl enable --now bootstraps unloaded jobs'
grep -Fq 'launchctl <bootout> <gui/501/test>' "$service_calls" \
    || fail 'macOS systemctl disable --now boots out loaded jobs'
grep -Fq 'launchctl <disable> <gui/501/test>' "$service_calls" \
    || fail 'macOS systemctl disable sets the launchd disabled override'
grep -Fq 'launchctl <bootstrap> <gui/501>' "$service_calls" \
    || fail 'macOS systemctl restart bootstraps the plist after bootout'
pass 'macOS systemctl wrapper maps common service lifecycle commands'

PYTHONPYCACHEPREFIX="$tmp_dir/config-share-pycache" \
    python3 "$tests_dir/test-config-share-server.py" \
    "$repo_dir/dot_local/libexec/executable_config-share-server"
pass 'config sharing server always allows loopback and filters other clients by CIDR'

syntax_checks

PYTHONPYCACHEPREFIX="$tmp_dir/pycache" \
    python3 -m py_compile "$repo_dir/dot_local/bin/executable_later"
pass 'later Python source compiles'

"$tests_dir/test-later.sh" "$repo_dir" "$tmp_dir"
pass 'later behavior'

printf '1..%d\n' "$pass_count"
