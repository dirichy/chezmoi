#!/usr/bin/env bash
# Sourced by run-group.sh; common.sh supplies fixture paths and helpers.
# shellcheck disable=SC2154
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

if [[ $fixture_os == macos ]]; then
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
else
    printf '# skip - macOS systemctl wrapper requires native plutil (macOS only)\n'
fi
