#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
prepare_source
mihomo_only_fixture="$tests_dir/fixtures/proxy-mihomo-only.toml"
mihomo_external_fixture="$tests_dir/fixtures/proxy-mihomo-and-external.toml"
external_only_fixture="$tests_dir/fixtures/proxy-external-only.toml"

mihomo_only_list="$tmp_dir/managed-mihomo-only.txt"
mihomo_external_list="$tmp_dir/managed-mihomo-and-external.txt"
external_only_list="$tmp_dir/managed-external-only.txt"
managed_list mihomo-only "$mihomo_only_fixture" >"$mihomo_only_list"
managed_list mihomo-and-external "$mihomo_external_fixture" >"$mihomo_external_list"
managed_list external-only "$external_only_fixture" >"$external_only_list"

assert_managed "$mihomo_only_list" '.config/mihomo/config.yaml' 'Mihomo can be enabled without client proxy settings'
assert_managed "$mihomo_external_list" '.config/mihomo/config.yaml' 'Mihomo can coexist with an external client proxy'
assert_ignored "$external_only_list" '.config/mihomo/config.yaml' 'external client proxy does not require Mihomo'

render_target mihomo-only "$mihomo_only_fixture" '.config/zsh/.zshenv' "$tmp_dir/mihomo-only.zshenv"
render_target mihomo-only "$mihomo_only_fixture" '.config/mihomo/config.yaml' "$tmp_dir/mihomo-only.yaml"
render_target mihomo-and-external "$mihomo_external_fixture" '.config/zsh/.zshenv' "$tmp_dir/mihomo-and-external.zshenv"
render_target mihomo-and-external "$mihomo_external_fixture" '.config/mihomo/config.yaml' "$tmp_dir/mihomo-and-external.yaml"
render_target external-only "$external_only_fixture" '.config/zsh/.zshenv' "$tmp_dir/external-only.zshenv"

# Inspect daily proxy exports in a clean environment.
assert_proxy_environment() {
    local rendered=$1 expected=$2 output
    # shellcheck disable=SC2016 # The child Zsh expands this script.
    output=$(env -i HOME="$tmp_dir/proxy-home" ZDOTDIR="$tmp_dir/proxy-home/.config/zsh" \
        PATH="$PATH" TERM=xterm-256color \
        zsh -dfc '
            source "$1" || exit
            for key in http_proxy https_proxy; do
                if [[ -n $2 ]]; then
                    [[ ${parameters[$key]-} == *export* && ${(P)key} == "$2" ]] || exit 1
                else
                    (( ! ${+parameters[$key]} )) || exit 1
                fi
            done
            for key in all_proxy ALL_PROXY HTTP_PROXY HTTPS_PROXY; do
                (( ! ${+parameters[$key]} )) || exit 1
            done
        ' zsh "$rendered" "$expected" 2>&1) \
        || fail "client proxy environment: ${rendered##*/} (expected '$expected'): $output"
}
mkdir -p "$tmp_dir/proxy-home"
assert_proxy_environment "$tmp_dir/mihomo-only.zshenv" ''
assert_proxy_environment "$tmp_dir/mihomo-and-external.zshenv" 'http://10.20.30.40:1080'
assert_proxy_environment "$tmp_dir/external-only.zshenv" 'http://10.20.30.40:1080'
# The maintenance Zsh must ignore both existing and partially deployed startup files.
mkdir -p "$tmp_dir/proxy-home/.config/zsh"
printf 'exit 91\n' >"$tmp_dir/proxy-home/.zshenv"
printf 'exit 92\n' >"$tmp_dir/proxy-home/.config/zsh/.zshenv"
printf 'exit 93\n' >"$tmp_dir/proxy-home/.config/zsh/.zshrc"
# shellcheck disable=SC2016 # Child Zsh evaluates this script.
env -i HOME="$tmp_dir/proxy-home" ZDOTDIR="$tmp_dir/proxy-home/.config/zsh" PATH="$PATH" \
    http_proxy=http://proxy.example:7890 https_proxy=http://proxy.example:7890 \
    zsh -dfc '[[ $http_proxy == http://proxy.example:7890 && $https_proxy == http://proxy.example:7890 ]]' \
    || fail 'maintenance Zsh ignores user configuration and inherits proxy settings'
grep -Fq 'mixed-port: 7890' "$tmp_dir/mihomo-only.yaml" \
    || fail 'Mihomo-only setup keeps the Mihomo listen port'
grep -Fq 'mixed-port: 7890' "$tmp_dir/mihomo-and-external.yaml" \
    || fail 'external proxy port must not change the Mihomo listen port'
pass 'Mihomo lifecycle and client proxy routing are independent'
