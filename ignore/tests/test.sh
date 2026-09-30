#!/usr/bin/env bash
set -euo pipefail

tests_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$tests_dir/../.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT
export PATH="$tests_dir/mock-bin:$PATH"

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
        --source "$repo_dir" \
        --destination "$tmp_dir/home-$profile" \
        --config "$tests_dir/fixtures/linux-$profile.toml" \
        --cache "$tmp_dir/cache-$profile" \
        --persistent-state "$tmp_dir/state-$profile.boltdb" \
        --refresh-externals=never \
        managed --include files,scripts --path-style relative
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
            --source "$repo_dir" \
            --destination "$tmp_dir/home-$profile" \
            --config "$tests_dir/fixtures/linux-$profile.toml" \
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

assert_managed "$desktop_list" '.config/waybar/config.jsonc' 'desktop includes Waybar'
assert_managed "$desktop_list" '.config/hypr/hyprland.lua' 'desktop includes Hyprland'
assert_managed "$desktop_list" '.config/fcitx5/profile' 'desktop includes input method files'
assert_managed "$desktop_list" '.local/bin/copy' 'desktop includes clipboard helper'
assert_managed "$desktop_list" '.local/bin/osc1337-im' 'desktop includes OSC 1337 input method helper'
assert_managed "$desktop_list" '.local/bin/later' 'desktop includes one-off task runner'
assert_managed "$desktop_list" '.config/systemd/user/later.path' 'desktop includes one-off task watcher'
assert_managed "$desktop_list" '.config/systemd/user/later.service' 'desktop includes one-off task service'
assert_managed "$desktop_list" 'create-later-tasks.sh' 'desktop includes one-off task initializer'
assert_ignored "$desktop_list" '.hammerspoon/init.lua' 'Linux excludes Hammerspoon'
assert_ignored "$desktop_list" '.config/fdu-connect/config.toml' 'disabled fdu-connect is excluded'

assert_managed "$headless_list" '.config/nvim/init.lua' 'headless retains Neovim'
assert_managed "$headless_list" '.local/bin/later' 'headless includes one-off task runner'
assert_managed "$headless_list" '.config/systemd/user/later.path' 'headless includes one-off task watcher'
assert_managed "$headless_list" '.config/systemd/user/later.service' 'headless includes one-off task service'
assert_managed "$headless_list" 'create-later-tasks.sh' 'headless includes one-off task initializer'
assert_ignored "$headless_list" '.config/waybar/config.jsonc' 'headless excludes Waybar'
assert_ignored "$headless_list" '.config/hypr/hyprland.lua' 'headless excludes Hyprland'
assert_ignored "$headless_list" '.config/fcitx5/profile' 'headless excludes input method files'
assert_ignored "$headless_list" '.local/bin/osc1337-im' 'headless excludes OSC 1337 input method helper'

assert_ignored "$skip_list" '.config/nvim/init.lua' 'skip excludes Neovim'
assert_ignored "$skip_list" '.config/mihomo/config.yaml' 'skip excludes mihomo'
assert_ignored "$skip_list" '.config/kitty/kitty.conf' 'skip excludes desktop applications'
assert_ignored "$skip_list" '.local/bin/later' 'skip excludes one-off task runner'
assert_ignored "$skip_list" '.config/systemd/user/later.path' 'skip excludes one-off task watcher'
assert_ignored "$skip_list" 'create-later-tasks.sh' 'skip excludes one-off task initializer'

render_managed_templates desktop "$desktop_list"
render_managed_templates headless "$headless_list"
render_managed_templates skip "$skip_list"
pass 'all managed files and templates render for every fixture profile'

grep -Fq '"height": 32' \
    "$tmp_dir/rendered-desktop/.config/waybar/generated.jsonc" \
    || fail 'Waybar uses the mocked focused monitor dimensions'
pass 'Waybar uses the mocked focused monitor dimensions'

later_state="$tmp_dir/later-init-state"
XDG_STATE_HOME=$later_state \
    bash "$tmp_dir/rendered-desktop/create-later-tasks.sh"
grep -Fq '# One-off tasks.' "$later_state/later/tasks" \
    || fail 'later initializer creates the documented task file'
printf '%s\n' '# preserve me' >>"$later_state/later/tasks"
XDG_STATE_HOME=$later_state \
    bash "$tmp_dir/rendered-desktop/create-later-tasks.sh"
grep -Fq '# preserve me' "$later_state/later/tasks" \
    || fail 'later initializer must not overwrite existing state'
pass 'later initializer creates state once without overwriting it'

syntax_checks

PYTHONPYCACHEPREFIX="$tmp_dir/pycache" \
    python3 -m py_compile "$repo_dir/dot_local/bin/executable_later"
pass 'later Python source compiles'

"$tests_dir/test-later.sh" "$repo_dir" "$tmp_dir"
pass 'later behavior'

printf '1..%d\n' "$pass_count"
