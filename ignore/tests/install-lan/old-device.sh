#!/usr/bin/env bash
set -euo pipefail
# The shared volume contains public material only. It must be writable by tester.
chown tester:tester /exchange
chmod 700 /exchange
export HOME=/home/tester XDG_CONFIG_HOME=/home/tester/.config XDG_DATA_HOME=/home/tester/.local/share
export XDG_CACHE_HOME=/home/tester/.cache GNUPGHOME=/home/tester/.gnupg
export CHECKPOINT_DISABLE=1 GOPASS_CONFIG_NOSYSTEM=true
export GIT_AUTHOR_NAME='Old Fixture' GIT_COMMITTER_NAME='Old Fixture'
export GIT_AUTHOR_EMAIL=old-device@example.invalid GIT_COMMITTER_EMAIL=old-device@example.invalid

if [[ ${1:-} == authorize-ssh ]]; then
    install -o tester -g tester -m 600 /exchange/new-device.pub /home/tester/.ssh/authorized_keys
    touch /exchange/ssh-authorized
    exit 0
fi
if [[ ${1:-} == authorize-gpg ]]; then
    runuser -u tester -- gpg --import /exchange/device-public.asc
    old_fingerprint=$(runuser -u tester -- gpg --with-colons --list-secret-keys old-device@example.invalid | awk -F: '$1=="fpr" {print $10; exit}')
    fingerprint=$(cat /exchange/gpg-fingerprint)
    # Simulate the old operator's explicit fingerprint check and trust decision.
    runuser -u tester -- gpg --batch --yes --local-user "$old_fingerprint" --quick-sign-key "$fingerprint"
    mkdir -p /home/tester/fixture-bin
    cat > /home/tester/fixture-bin/gopass <<'WRAPPER'
#!/bin/sh
# Automate confirmations on this fake old device only.
exec /usr/bin/gopass --yes "$@"
WRAPPER
    chmod 755 /home/tester/fixture-bin/gopass
    runuser -u tester -- env PATH=/home/tester/fixture-bin:/usr/bin:/bin \
        bash /source/ignore/bin/add-device /exchange/device-public.asc "$fingerprint"
    runuser -u tester -- git -C /home/tester/.local/share/gopass/stores/root push origin HEAD
    touch /exchange/gpg-authorized
    exit 0
fi
if [[ ${1:-} == stop-temporary ]]; then
    kill -TERM "$(cat /run/temporary-proxy.pid)"
    # run.sh also probes the port from new; killing the process closes active tunnels.
    exit 0
fi

runuser -u tester -- bash -eu <<'SETUP'
mkdir -p "$GNUPGHOME" "$HOME/.ssh" "$HOME/repos"
chmod 700 "$GNUPGHOME" "$HOME/.ssh"
printf '[user]\nname = Old Fixture\nemail = old-device@example.invalid\n' > "$HOME/.gitconfig"
gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key \
    'Old Fixture <old-device@example.invalid>' future-default default 0
fingerprint=$(gpg --with-colons --list-secret-keys old-device@example.invalid | awk -F: '$1=="fpr" {print $10; exit}')
gopass --yes --nosync init "$fingerprint"
printf 'fixture-device-enrollment-ok\n' | gopass --yes --nosync insert --force --multiline chezmoi/bootstrap-check
printf 'http://%s:18082/subscription-fixture-token\n' "$OLD_IP" | gopass --yes --nosync insert --force --multiline chezmoi/ikuuu
printf 'http://%s:18082/subscription-fixture-token\n' "$OLD_IP" | gopass --yes --nosync insert --force --multiline chezmoi/wyyctc
git clone --bare "$HOME/.local/share/gopass/stores/root" "$HOME/repos/passwords.git"
git -C "$HOME/.local/share/gopass/stores/root" remote add origin "$HOME/repos/passwords.git"
: > "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
SETUP
# Verify SSH host trust through an out-of-band public key, never ssh-keyscan trust-on-first-use.
printf '[%s]:2222 ' "$OLD_IP" > /exchange/known_hosts
cat /etc/ssh/ssh_host_ed25519_key.pub >> /exchange/known_hosts
cat > /etc/ssh/sshd_config <<'SSHD'
Port 2222
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_ed25519_key
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
PermitRootLogin no
AllowUsers tester
# The fake GitHub endpoint supports Git over SSH, not arbitrary remote commands.
ForceCommand /usr/bin/git-shell -c "$SSH_ORIGINAL_COMMAND"
SSHD
# Docker's useradd can leave a locked account. Give it an unused fixture password
# while SSH password authentication remains disabled.
printf 'tester:fixture-password-not-used\n' | chpasswd
/usr/bin/sshd -D -e &
ssh_pid=$!
python3 /fixture/lan-services.py proxy 18080 temporary &
temporary_pid=$!
printf '%s\n' "$temporary_pid" > /run/temporary-proxy.pid
python3 /fixture/lan-services.py proxy 18081 permanent &
permanent_pid=$!
python3 /fixture/lan-services.py subscription 18082 &
subscription_pid=$!
trap 'kill "$ssh_pid" "$temporary_pid" "$permanent_pid" "$subscription_pid" 2>/dev/null || true' EXIT
python3 - <<'PY'
import socket
import time
for port in (2222, 18080, 18081, 18082):
    for attempt in range(100):
        try:
            socket.create_connection(('127.0.0.1', port), timeout=0.2).close()
            break
        except OSError:
            time.sleep(0.1)
    else:
        raise SystemExit(f'Service did not become ready: {port}')
PY
touch /exchange/old-ready
wait "$ssh_pid" "$permanent_pid" "$subscription_pid"
