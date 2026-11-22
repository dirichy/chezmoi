#!/usr/bin/env python3
"""Manual offline integration test: real SSH, GPG, add-device, gopass and Mihomo.

Run inside a disposable Linux namespace/container as a non-root user:
  python3 ignore/tests/test-enrollment.py REPO EMPTY_WORKDIR
No GitHub account, external resources or real user directories are used.
"""

import hashlib
import http.client
import http.server
import os
from pathlib import Path
import select
import signal
import shutil
import socket
import socketserver
import subprocess
import sys
import threading
import time

repo, root = map(lambda value: Path(value).resolve(), sys.argv[1:])
root.mkdir(parents=True, exist_ok=False)
for tool in ("ssh", "sshd", "ssh-keygen", "gpg", "gpgconf", "gopass", "git", "mihomo", "chezmoi"):
    if not shutil.which(tool):
        raise SystemExit(f"Missing integration dependency: {tool}")
if os.geteuid() == 0:
    raise SystemExit("Run this fixture as a non-root user (sshd on high loopback ports).")


def run(args, env, expected=0, input=None):
    process = subprocess.Popen(list(map(str, args)), env=env, stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, start_new_session=True)
    try:
        stdout, stderr = process.communicate(input, timeout=40)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        stdout, stderr = process.communicate(timeout=5)
        raise AssertionError(("Timed out", args, stdout, stderr))
    result = subprocess.CompletedProcess(args, process.returncode, stdout, stderr)
    assert result.returncode == expected, (args, result.returncode, result.stdout, result.stderr)
    return result


def environment(home):
    home.mkdir()
    env = {key: value for key, value in os.environ.items()
           if key in ("PATH", "LANG", "LC_ALL", "TERM")}
    env.update(HOME=str(home), GNUPGHOME=str(home / ".gnupg"),
               XDG_CONFIG_HOME=str(home / ".config"), XDG_DATA_HOME=str(home / ".local/share"),
               XDG_CACHE_HOME=str(home / ".cache"), XDG_STATE_HOME=str(home / ".local/state"),
               GOPASS_CONFIG_NOSYSTEM="true", GOPASS_NO_NOTIFY="true", CHECKPOINT_DISABLE="1",
               GIT_CONFIG_NOSYSTEM="1", GIT_AUTHOR_NAME="Fixture", GIT_COMMITTER_NAME="Fixture",
               GIT_AUTHOR_EMAIL="fixture@example.invalid", GIT_COMMITTER_EMAIL="fixture@example.invalid")
    (home / ".gnupg").mkdir(mode=0o700)
    (home / ".gitconfig").write_text('[user]\nname = Fixture\nemail = fixture@example.invalid\n')
    return env


def port():
    with socket.socket() as connection:
        connection.bind(("127.0.0.1", 0))
        return connection.getsockname()[1]


def wait_port(number, process):
    for _ in range(100):
        assert process.poll() is None, f"Service exited: {process.returncode}"
        try:
            with socket.create_connection(("127.0.0.1", number), timeout=0.1):
                return
        except OSError:
            time.sleep(0.05)
    raise AssertionError(f"No listener on port {number}")


old = environment(root / "old-device")
new = environment(root / "new-device")
fixture_bin = root / "bin"
fixture_bin.mkdir()
# Automate only passphrase/confirmation UIs; all cryptography uses the real programs.
pinentry = fixture_bin / "pinentry"
pinentry.write_text(f'''#!{sys.executable}
import sys
print("OK fixture pinentry", flush=True)
for line in sys.stdin:
    command = line.split()[0]
    if command == "GETPIN": print("D fixture-device-passphrase", flush=True)
    elif command == "GETINFO": print("D 0", flush=True)
    print("OK", flush=True)
    if command == "BYE": break
''')
pinentry.chmod(0o755)
askpass = fixture_bin / "askpass"
askpass.write_text('#!/bin/sh\nprintf "fixture-device-passphrase\\n"\n')
askpass.chmod(0o755)
for env in (old, new):
    Path(env["GNUPGHOME"], "gpg-agent.conf").write_text(f"pinentry-program {pinentry}\n")
    env.update(SSH_ASKPASS=str(askpass), SSH_ASKPASS_REQUIRE="force", DISPLAY="fixture:0")
helper = repo / "ignore/bin/dotfiles-identity"
prepare = ["bash", helper, "--prepare", "--name", "New Device", "--email", "new-device@example.invalid"]
processes = []
servers = []
logs = []
try:
    run(prepare, new)
    state = Path(new["XDG_DATA_HOME"], "dotfiles")
    fingerprint = (state / "gpg-fingerprint").read_text().strip()
    public_key = state / "device-public.asc"
    ssh_key = Path(new["HOME"], ".ssh/id_ed25519")
    before = hashlib.sha256(ssh_key.read_bytes()).hexdigest()
    run(prepare, new)
    assert hashlib.sha256(ssh_key.read_bytes()).hexdigest() == before
    assert (state / "gpg-fingerprint").read_text().strip() == fingerprint
    assert "PRIVATE KEY" not in public_key.read_text()
    rejected = subprocess.run(["bash", str(helper), "--import-private-key", "never-read"], env=new, capture_output=True, text=True)
    assert rejected.returncode == 2
    print("PASS: real device keys generated locally, reused, public-only export; private import rejected", flush=True)

    run(["gpg", "--batch", "--pinentry-mode", "loopback", "--passphrase", "", "--quick-generate-key",
         "Old Device <old-device@example.invalid>", "future-default", "default", "0"], old)
    listing = run(["gpg", "--with-colons", "--list-secret-keys"], old).stdout
    old_fingerprint = next(line.split(":")[9] for line in listing.splitlines() if line.startswith("fpr:"))
    old_store = Path(old["XDG_DATA_HOME"], "gopass/stores/root")
    run(["gopass", "--yes", "--nosync", "init", old_fingerprint], old)
    expected = "fixture-device-enrollment-ok"
    run(["gopass", "--yes", "--nosync", "insert", "--force", "--multiline", "chezmoi/bootstrap-check"], old, input=expected + "\n")
    bare = root / "passwords.git"
    run(["git", "clone", "--bare", old_store, bare], old)
    run(["git", "-C", old_store, "remote", "add", "origin", bare], old)

    host_key = root / "ssh-host-key"
    run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", host_key], old)
    authorized = root / "authorized_keys"
    authorized.write_text("")
    ssh_port = port()
    import pwd
    username = pwd.getpwuid(os.getuid()).pw_name
    config = root / "sshd_config"
    config.write_text(f'''Port {ssh_port}
ListenAddress 127.0.0.1
HostKey {host_key}
PidFile {root / 'sshd.pid'}
AuthorizedKeysFile {authorized}
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
PermitRootLogin no
AllowUsers {username}
LogLevel ERROR
''')
    ssh_log = (root / "sshd.log").open("w")
    logs.append(ssh_log)
    sshd = subprocess.Popen([shutil.which("sshd"), "-D", "-e", "-f", str(config)], env=old, stdout=ssh_log, stderr=ssh_log)
    processes.append(sshd)
    wait_port(ssh_port, sshd)
    ssh_home = Path(new["HOME"], ".ssh")
    host_public = host_key.with_suffix(".pub").read_text()
    (ssh_home / "known_hosts").write_text(f"[127.0.0.1]:{ssh_port} " + host_public)
    (ssh_home / "config").write_text(f"Host 127.0.0.1\n  StrictHostKeyChecking yes\n  UserKnownHostsFile {ssh_home / 'known_hosts'}\n  BatchMode no\n  ConnectTimeout 5\n")

    connections = []

    class Proxy(socketserver.StreamRequestHandler):
        def handle(self):
            first = self.rfile.readline().decode().strip().split()
            if not first:
                return
            while self.rfile.readline() not in (b"\r\n", b"\n", b""):
                pass
            assert first[0] == "CONNECT", first
            target_host, target_port = first[1].rsplit(":", 1)
            assert target_host == "127.0.0.1" and int(target_port) == ssh_port
            connections.append(first[1])
            with socket.create_connection((target_host, int(target_port))) as remote:
                self.wfile.write(b"HTTP/1.1 200 Connection established\r\n\r\n")
                self.wfile.flush()
                while True:
                    ready = select.select([self.connection, remote], [], [], 20)[0]
                    if not ready:
                        return
                    for incoming in ready:
                        data = incoming.recv(65536)
                        if not data:
                            return
                        (remote if incoming is self.connection else self.connection).sendall(data)

    class Server(socketserver.ThreadingTCPServer):
        allow_reuse_address = True
        daemon_threads = True

    proxy = Server(("127.0.0.1", 0), Proxy)
    servers.append(proxy)
    threading.Thread(target=proxy.serve_forever, daemon=True).start()
    new["BOOTSTRAP_PROXY"] = f"http://127.0.0.1:{proxy.server_address[1]}"
    url = f"ssh://{username}@127.0.0.1:{ssh_port}{bare}"
    enroll = ["bash", helper, "--name", "New Device", "--email", "new-device@example.invalid", "--store", url, "--yes"]
    run(enroll, new, expected=1)  # SSH public key has not been added yet.
    authorized.write_text(ssh_key.with_suffix(".pub").read_text())
    run(enroll, new, expected=1)  # Can clone over SSH, cannot decrypt before old-device authorization.
    new_store = Path(new["XDG_DATA_HOME"], "gopass/stores/root")
    assert (new_store / ".git").exists() and fingerprint[-16:] not in (new_store / ".gpg-id").read_text()
    assert run(["bash", repo / "ignore/bin/gopass-safe", "bootstrap-check", "not-authorized"], new).stdout == "not-authorized"
    assert not run(["git", "-C", new_store, "status", "--porcelain"], new).stdout, "Unauthorized check dirtied the store"
    assert connections, "SSH bypassed the bootstrap HTTP proxy"
    print("PASS: SSH access requires public-key authorization; cloned store remains unreadable before GPG authorization", flush=True)

    # The old operator certifies the checked public key, then runs the real add-device.
    run(["gpg", "--import", public_key], old)
    run(["gpg", "--batch", "--yes", "--local-user", old_fingerprint, "--quick-sign-key", fingerprint], old)
    old_bin = root / "old-bin"
    old_bin.mkdir()
    native_gopass = shutil.which("gopass")
    wrapper = old_bin / "gopass"
    wrapper.write_text(f'#!/bin/sh\nexec "{native_gopass}" --yes "$@"\n')
    wrapper.chmod(0o755)
    old["PATH"] = f"{old_bin}:{old['PATH']}"
    run(["bash", repo / "ignore/bin/add-device", public_key, fingerprint], old)
    run(["git", "-C", old_store, "push", "origin", "HEAD"], old)
    run(enroll, new)
    actual = run(["gopass", "show", "--password", "--nofuzzysearch", "--nosync", "chezmoi/bootstrap-check"], new).stdout.strip()
    assert actual == expected
    assert fingerprint[-16:] in (new_store / ".gpg-id").read_text()
    commits = run(["git", "-C", new_store, "rev-parse", "HEAD"], new).stdout
    run(enroll, new)
    assert run(["git", "-C", new_store, "rev-parse", "HEAD"], new).stdout == commits
    print("PASS: add-device re-encrypts the fake store; new device pulls/decrypts the expected field; rerun preserves keys and history", flush=True)

    # Verify a native chezmoi secret can now be rendered, without any externals.
    render_source = root / "render-source"
    render_source.mkdir()
    (render_source / "private_dot_enrollment-check.tmpl").write_text('{{ secret "bootstrap-check" "not-authorized" }}')
    cm_config = root / "chezmoi.toml"
    cm_config.write_text(f'[secret]\ncommand = "{repo / "ignore/bin/gopass-safe"}"\n')
    run(["chezmoi", "--source", render_source, "--destination", new["HOME"], "--config", cm_config,
         "--cache", root / "cm-cache", "--persistent-state", root / "cm-state", "--refresh-externals=never", "apply"], new)
    assert Path(new["HOME"], ".enrollment-check").read_text() == expected

    # Run the actual installer against the now-authorized fixture device and source.
    # Copy the source and disable all externals according to the repository test policy.
    install_source = root / "install-source"
    shutil.copytree(repo, install_source, ignore=shutil.ignore_patterns(".git", "__pycache__"))
    (install_source / ".chezmoiexternal.toml").write_text("")
    install_config = root / "install.toml"
    fixture = (repo / "ignore/tests/fixtures/linux-headless.toml").read_text()
    fixture = fixture.replace('profile = "headless"', 'profile = "custom"').replace('modules = ""', 'modules = "core"')
    fixture = fixture.replace('command = "true"', 'command = "pacman -S --needed --noconfirm"')
    fixture = fixture.replace('[data.configShare]\nmode = "custom"', '[data.configShare]\nmode = "none"')
    install_config.write_text(fixture + '\n[data.downloads]\npreferChezmoi = true\ngithubMirror = "direct"\ngithubMirrorPrefix = ""\n')
    install_args = ["bash", install_source / "install.sh", "--source", install_source,
                    "--config", install_config, "--destination", new["HOME"],
                    "--cache", root / "install-cache", "--state", root / "install-state",
                    "--store", url, "--yes", "--skip-plugins", "--skip-services", "--skip-hooks"]
    installed = run(install_args, new)
    assert "Installation completed." in installed.stdout
    run(["chezmoi", "--source", install_source, "--config", install_config, "--destination", new["HOME"],
         "--cache", root / "install-cache", "--persistent-state", root / "install-state", "--refresh-externals=never",
         "apply", "--keep-going"], dict(new, DOTFILES_SKIP_APP_INIT="1", DOTFILES_SKIP_SERVICES="1", DOTFILES_SKIP_HOOKS="1"))
    print("PASS: actual install.sh reuses core dependencies and authorized device keys/store; subsequent apply succeeds", flush=True)

    class HTTP(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"fixture-proxy-ok")

        def log_message(self, *_args):
            pass

    target = http.server.ThreadingHTTPServer(("127.0.0.1", 0), HTTP)
    servers.append(target)
    threading.Thread(target=target.serve_forever, daemon=True).start()
    mixed_port = port()
    mihomo_home = root / "mihomo"
    mihomo_home.mkdir()
    # No Geo, subscriptions, rule providers or external network downloads in this fixture.
    (mihomo_home / "config.yaml").write_text(f'mixed-port: {mixed_port}\nmode: rule\nlog-level: silent\nrules:\n  - MATCH,DIRECT\n')
    mihomo_log = (root / "mihomo.log").open("w")
    logs.append(mihomo_log)
    mihomo = subprocess.Popen(["mihomo", "-d", str(mihomo_home)], env=new, stdout=mihomo_log, stderr=mihomo_log)
    processes.append(mihomo)
    wait_port(mixed_port, mihomo)
    request = http.client.HTTPConnection("127.0.0.1", mixed_port, timeout=5)
    request.request("GET", f"http://127.0.0.1:{target.server_address[1]}/fixture")
    response = request.getresponse()
    assert response.status == 200 and response.read() == b"fixture-proxy-ok"
    request.close()
    print("PASS: chezmoi reads the authorized store; real Mihomo HTTP proxy forwards a local request without downloads", flush=True)
finally:
    for process in reversed(processes):
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
    for server in servers:
        server.shutdown()
        server.server_close()
    for log in logs:
        log.close()
    for env in (old, new):
        subprocess.run(["gpgconf", "--kill", "all"], env=env, capture_output=True)
