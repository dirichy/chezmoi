#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
python3 -m py_compile "$repo_dir/dot_local/bin/executable_later"
pass 'later Python source compiles'

"$tests_dir/test-later.sh" "$repo_dir" "$tmp_dir"
pass 'later behavior'
