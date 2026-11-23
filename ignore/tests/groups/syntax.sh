#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
while IFS= read -r -d '' file; do
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
