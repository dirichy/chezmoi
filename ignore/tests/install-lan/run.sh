#!/usr/bin/env bash
# Local/Actions entry: two Docker environments, no host package installs or credentials.
set -euo pipefail
fixture_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export COMPOSE_PROJECT_NAME="dotfiles-install-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}"
compose=(docker compose --file "$fixture_dir/compose.yaml")
artifacts=$fixture_dir/artifacts
mkdir -p "$artifacts"
command -v docker >/dev/null 2>&1 || { printf 'Docker with the Compose plugin is required.\n' >&2; exit 1; }
docker compose version

install_pid=""
cleanup() {
    local result=$?
    trap - EXIT
    if [[ -n $install_pid ]]; then
        kill "$install_pid" 2>/dev/null || true
        wait "$install_pid" 2>/dev/null || true
    fi
    "${compose[@]}" logs --no-color old >"$artifacts/old-device.log" 2>&1 || true
    "${compose[@]}" exec -T new cat /home/tester/mihomo.log >"$artifacts/mihomo.log" 2>&1 || true
    # Never export HOME, private keys, .gnupg, the encrypted store or Docker volumes.
    "${compose[@]}" down --volumes --remove-orphans >"$artifacts/cleanup.log" 2>&1 || true
    exit "$result"
}
trap cleanup EXIT

wait_marker() {
    local marker=$1 timeout_seconds=$2 deadline
    deadline=$((SECONDS + timeout_seconds))
    while ! "${compose[@]}" exec -T old test -f "/exchange/$marker"; do
        if [[ -n $install_pid ]] && ! kill -0 "$install_pid" 2>/dev/null; then
            wait "$install_pid" || true
            tail -n 80 "$artifacts/new-device.log" >&2
            printf 'New device exited before %s\n' "$marker" >&2
            return 1
        fi
        if ((SECONDS >= deadline)); then
            printf 'Timed out waiting for %s\n' "$marker" >&2
            return 1
        fi
        sleep 3
    done
}

"${compose[@]}" build --pull 2>&1 | tee "$artifacts/build.log"
"${compose[@]}" up --detach --wait
"${compose[@]}" exec -T new python3 /fixture/new-device.py install 2>&1 | tee "$artifacts/new-device.log" &
install_pid=$!
# This includes actual Rust compilation and AUR/core package installation.
wait_marker awaiting-ssh-authorization 4200
"${compose[@]}" exec -T old bash /fixture/old-device.sh authorize-ssh 2>&1 | tee "$artifacts/authorize-ssh.log"
wait_marker awaiting-gpg-authorization 180
"${compose[@]}" exec -T old bash /fixture/old-device.sh authorize-gpg 2>&1 | tee "$artifacts/authorize-gpg.log"
wait "$install_pid"
install_pid=""
"${compose[@]}" exec -T new python3 /fixture/new-device.py handover 2>&1 | tee "$artifacts/handover.log"
"${compose[@]}" exec -T old bash /fixture/old-device.sh stop-temporary
"${compose[@]}" exec -T new python3 /fixture/new-device.py verify 2>&1 | tee "$artifacts/verify.log"
"${compose[@]}" logs --no-color old >"$artifacts/old-device.log"
grep -Eq 'temporary: .*GET http://172\.30\.247\.2:18082/subscription-fixture-token' "$artifacts/old-device.log"
grep -Eq 'temporary: .*CONNECT 172\.30\.247\.2:2222' "$artifacts/old-device.log"
grep -Eq 'permanent: .*CONNECT example\.com:443' "$artifacts/old-device.log"
printf 'PASS: real Arch installation, two-device authorization and proxy handover\n' | tee "$artifacts/result.log"
