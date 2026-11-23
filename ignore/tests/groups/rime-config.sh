#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
if [[ $fixture_os != linux ]]; then
    printf '# skip - Fcitx switching configuration applies to Linux only\n'
    return 0
fi
prepare_source
render_target desktop "$tests_dir/fixtures/$fixture_os-desktop.toml" '.config/fcitx5/conf/rime.conf' "$tmp_dir/rime-switch.conf"
grep -Fqx 'SwitchInputMethodBehavior="Commit raw input"' "$tmp_dir/rime-switch.conf" \
    || fail 'Rime switching must commit raw input instead of the candidate preview'
pass 'Rime commits raw input when switching input methods'
