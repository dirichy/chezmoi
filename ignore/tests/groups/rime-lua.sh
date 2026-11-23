#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
if command -v lua >/dev/null 2>&1; then
    lua "$tests_dir/test-rime-tools.lua" "$repo_dir"
    pass 'Rime schemes share tools while preserving their trigger prefixes'
    mkdir -p "$tmp_dir/simp-stats"
    lua "$tests_dir/test-rime-simp.lua" "$repo_dir" "$tmp_dir/simp-stats"
    pass 'Tiger shorthand reminders and statistics are independent and persist locally'
else
    printf '# skip - Rime tool behavior requires lua\n'
fi
