#!/usr/bin/env bash
set -euo pipefail

tests_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo_dir=$(CDPATH='' cd -- "$tests_dir/../.." && pwd)
tmp_dir=${2:?missing isolated work directory}
export PYTHONPYCACHEPREFIX="$tmp_dir/pycache"
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

seed_home() {
    local profile=$1
    mkdir -p "$tmp_dir/home-$profile/.cache/rime-tiger/upstream"
    cp "$tests_dir/fixtures/rime-tiger/tiger.dict.yaml" "$tmp_dir/home-$profile/.cache/rime-tiger/upstream/"
    mkdir -p "$tmp_dir/home-$profile/.cache/rime-ice/upstream/opencc" "$tmp_dir/home-$profile/.cache/rime-tiger/upstream/opencc"
    cp "$tests_dir/fixtures/rime-ice/"*.yaml "$tmp_dir/home-$profile/.cache/rime-ice/upstream/"
    printf '笑\t笑 😄\n' > "$tmp_dir/home-$profile/.cache/rime-ice/upstream/opencc/emoji.txt"
    printf '虎\t虎 🐯\n' > "$tmp_dir/home-$profile/.cache/rime-tiger/upstream/opencc/emoji.txt"
}

managed_list() {
    local profile=$1 fixture
    fixture=${2:-$tests_dir/fixtures/$fixture_os-$profile.toml}
    seed_home "$profile"
    chezmoi \
        --source "$source_dir" \
        --destination "$tmp_dir/home-$profile" \
        --config "$fixture" \
        --cache "$tmp_dir/cache-$profile" \
        --persistent-state "$tmp_dir/state-$profile.boltdb" \
        --refresh-externals=never \
        managed --include files,scripts,symlinks --path-style relative
}

render_target() {
    local name=$1 fixture=$2 target=$3 output=$4
    mkdir -p "$tmp_dir/home-$name" "$(dirname -- "$output")"
    chezmoi \
        --source "$source_dir" \
        --destination "$tmp_dir/home-$name" \
        --config "$fixture" \
        --cache "$tmp_dir/cache-$name" \
        --persistent-state "$tmp_dir/state-$name.boltdb" \
        --refresh-externals=never \
        --no-tty \
        cat "$tmp_dir/home-$name/$target" >"$output"
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
    local profile=$1
    seed_home "$profile"
    mkdir -p "$tmp_dir/rendered-$profile"
    chezmoi \
        --source "$source_dir" \
        --destination "$tmp_dir/home-$profile" \
        --config "$tests_dir/fixtures/$fixture_os-$profile.toml" \
        --cache "$tmp_dir/cache-$profile" \
        --persistent-state "$tmp_dir/state-$profile.boltdb" \
        --refresh-externals=never --no-tty \
        archive --format tar \
        --output "$tmp_dir/$profile.tar"
    tar -xmf "$tmp_dir/$profile.tar" -C "$tmp_dir/rendered-$profile"
}


prepare_source() {
    require_command chezmoi
    # Render a disposable source copy with all external downloads disabled.
    source_dir="$tmp_dir/source"
    python3 - "$repo_dir" "$source_dir" <<'PYTHON'
import shutil
import sys
from pathlib import Path
shutil.copytree(sys.argv[1], sys.argv[2], ignore=shutil.ignore_patterns('.git', '.cache', '__pycache__'))
Path(sys.argv[2], '.chezmoiexternal.toml').write_text('')
PYTHON
}

prepare_lists() {
    desktop_list="$tmp_dir/managed-desktop.txt"
    headless_list="$tmp_dir/managed-headless.txt"
    skip_list="$tmp_dir/managed-skip.txt"
    managed_list desktop >"$desktop_list"
    managed_list headless >"$headless_list"
    managed_list skip >"$skip_list"
}
