#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
prepare_source
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
