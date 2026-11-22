#!/usr/bin/env python3
"""Drive a real installer through public-key enrollment and proxy handover."""

import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import socket
import subprocess
import sys
import termios
import time
import urllib.request

HOME = Path.home()
OLD_IP = os.environ["OLD_IP"]
TEMPORARY = f"http://{OLD_IP}:18080"
LOCAL = "http://127.0.0.1:17890"
SOURCE = HOME / "source"
CONFIG = HOME / ".config/chezmoi/chezmoi.toml"
EXCHANGE = Path("/exchange")
FIXTURE = Path("/fixture")


def run(args, *, expected=0, env=None, timeout=180):
    result = subprocess.run(list(map(str, args)), env=env, capture_output=True, text=True, timeout=timeout)
    print(result.stdout, end="", flush=True)
    print(result.stderr, end="", file=sys.stderr, flush=True)
    assert result.returncode == expected, (args, result.returncode)
    return result.stdout.strip()


def proxy_environment(proxy):
    env = dict(os.environ)
    for name in ("http_proxy", "https_proxy", "all_proxy", "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"):
        env[name] = proxy
    env.update(no_proxy="localhost,127.0.0.1,::1", NO_PROXY="localhost,127.0.0.1,::1")
    return env


def assert_no_internet():
    try:
        connection = socket.create_connection(("1.1.1.1", 443), timeout=3)
    except OSError:
        pass
    else:
        connection.close()
        raise AssertionError("New device has a direct TCP route to the Internet")
    # Test both routing to a literal IP and a named HTTPS endpoint. Bypass every proxy.
    for target in ("https://1.1.1.1", "https://api.github.com"):
        result = subprocess.run(["curl", "--noproxy", "*", "-kfsS", "--connect-timeout", "3", "--max-time", "5", target],
                                capture_output=True)
        assert result.returncode != 0, f"New device bypassed old-device proxy: {target}"
    print("PASS: direct Internet requests fail, even when explicitly bypassing proxies", flush=True)


def download(url, proxy):
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({"http": proxy, "https": proxy}))
    with opener.open(url, timeout=60) as response:
        assert response.status == 200
        return response.read()


def prepare():
    assert_no_internet()
    for tool in ("paru", "chezmoi", "gopass", "mihomo", "git"):
        assert shutil.which(tool) is None, f"Preinstalled tool hides bootstrap: {tool}"
    shutil.copytree("/source", SOURCE, ignore=shutil.ignore_patterns(".git", "__pycache__", "artifacts"))
    # Repository policy: do not download production externals in a test fixture.
    (SOURCE / ".chezmoiexternal.toml").write_text("")
    CONFIG.parent.mkdir(parents=True)
    CONFIG.write_text('''[data]
name = "New Fixture"
email = "new-device@example.invalid"
inputMethod = "tiger"
fduConnect = false
phoneBluetoothMac = ""
[data.install]
profile = "custom"
modules = "core"
command = "paru -S --needed --noconfirm --skipreview"
admin = true
[data.downloads]
preferChezmoi = true
githubMirror = "direct"
githubMirrorPrefix = ""
[data.features]
proxy = false
downloadChecks = false
[data.waybar]
hostnameSymbol = "new-fixture"
[data.configShare]
mode = "none"
''')
    (HOME / ".ssh").mkdir(mode=0o700)
    shutil.copyfile(EXCHANGE / "known_hosts", HOME / ".ssh/known_hosts")
    (HOME / ".gnupg").mkdir(mode=0o700)
    (HOME / ".gnupg/gpg-agent.conf").write_text(f"pinentry-program {FIXTURE / 'pinentry.py'}\n")
    # No host/user credential sockets are mounted. Pinentry and askpass supply only
    # fixture passphrases; trust comes from the shared host public key above.
    print("PASS: new device starts without Git, chezmoi, paru, gopass or Mihomo", flush=True)


def install():
    prepare()
    env = dict(os.environ, SSH_ASKPASS=str(FIXTURE / "askpass.sh"), SSH_ASKPASS_REQUIRE="force",
               DISPLAY="fixture:0", GNUPGHOME=str(HOME / ".gnupg"),
               CHECKPOINT_DISABLE="1", GOPASS_CONFIG_NOSYSTEM="true", GOPASS_NO_NOTIFY="true",
               GIT_CONFIG_NOSYSTEM="1", LANG="C.UTF-8")
    command = ["bash", str(SOURCE / "install.sh"), "--source", str(SOURCE), "--config", str(CONFIG),
               "--init", "--proxy", TEMPORARY,
               "--store", f"ssh://tester@{OLD_IP}:2222/home/tester/repos/passwords.git",
               "--skip-plugins", "--skip-services", "--skip-hooks"]
    master, slave = pty.openpty()

    def terminal():
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    process = subprocess.Popen(command, env=env, stdin=slave, stdout=slave, stderr=slave,
                               preexec_fn=terminal, close_fds=True)
    os.close(slave)
    buffer = ""
    transcript = []
    prompts = 0
    deadline = time.monotonic() + 70 * 60
    try:
        while True:
            assert time.monotonic() < deadline, "Installer exceeded 70 minutes"
            if not select.select([master], [], [], 1)[0]:
                if process.poll() is not None:
                    break
                continue
            try:
                data = os.read(master, 65536)
            except OSError as error:
                if error.errno == errno.EIO:
                    break
                raise
            if not data:
                break
            text = data.decode(errors="replace")
            sys.stdout.write(text)
            sys.stdout.flush()
            transcript.append(text)
            buffer += text
            while "[Y/n] " in buffer:
                buffer = buffer.split("[Y/n] ", 1)[1]
                os.write(master, b"y\n")
            prompt = "then press Enter (Ctrl-C to continue later): "
            if prompt in buffer:
                buffer = buffer.split(prompt, 1)[1]
                prompts += 1
                assert prompts <= 2, "Unexpected repeated authorization prompt"
                if prompts == 1:
                    state = HOME / ".local/share/dotfiles"
                    shutil.copyfile(HOME / ".ssh/id_ed25519.pub", EXCHANGE / "new-device.pub")
                    shutil.copyfile(state / "device-public.asc", EXCHANGE / "device-public.asc")
                    shutil.copyfile(state / "gpg-fingerprint", EXCHANGE / "gpg-fingerprint")
                    (EXCHANGE / "awaiting-ssh-authorization").touch()
                    ready = EXCHANGE / "ssh-authorized"
                else:
                    # The private repository is accessible but no GPG access yet.
                    store = HOME / ".local/share/gopass/stores/root"
                    assert (store / ".git").exists()
                    fingerprint = (EXCHANGE / "gpg-fingerprint").read_text().strip()
                    assert fingerprint[-16:] not in (store / ".gpg-id").read_text()
                    (EXCHANGE / "awaiting-gpg-authorization").touch()
                    ready = EXCHANGE / "gpg-authorized"
                authorization_deadline = time.monotonic() + 180
                while not ready.exists():
                    assert time.monotonic() < authorization_deadline, "Old device did not authorize the new device"
                    time.sleep(0.25)
                os.write(master, b"\n")
        assert process.wait(timeout=10) == 0, "Actual install.sh failed"
    finally:
        os.close(master)
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            process.wait(timeout=10)
    output = "".join(transcript)
    assert prompts == 2, "SSH and GPG authorization were not tested independently"
    assert "Bootstrap paru" in output, "paru bootstrap was skipped"
    clean_output = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", output)
    assert re.search(r"\bCompiling\s+paru\s+v", clean_output), "No actual Rust compilation of paru was observed"
    assert "Installation completed." in output
    assert "Package installation failures:" not in output
    (HOME / "install-transcript.log").write_text(output)
    # Actual installed packages, not fixture stubs or binaries preloaded in the image.
    run(["pacman", "-Q", "paru", "mihomo", "gopass", "openssh", "rust", "base-devel"])
    run(["paru", "--version"])
    run([HOME / ".local/bin/chezmoi", "--version"])
    actual = run(["gopass", "show", "--password", "--nofuzzysearch", "--nosync", "chezmoi/bootstrap-check"], env=env)
    assert actual == "fixture-device-enrollment-ok"
    print("PASS: real installer built/installed paru, installed core, and completed two-device enrollment", flush=True)


def handover():
    env = proxy_environment(TEMPORARY)
    env.update(GNUPGHOME=str(HOME / ".gnupg"), CHECKPOINT_DISABLE="1", GOPASS_CONFIG_NOSYSTEM="true")
    link = run(["bash", SOURCE / "ignore/bin/gopass-safe", "ikuuu", "missing-subscription"], env=env)
    assert link.startswith(f"http://{OLD_IP}:18082/")
    # Download only the fake link obtained from the encrypted store. No production
    # Mihomo Geo/providers/externals are fetched by this scenario.
    subscription = json.loads(download(link, TEMPORARY))
    proxy = subscription["proxies"][0]
    assert proxy["server"] == OLD_IP and proxy["port"] != 18080
    work = HOME / ".cache/lan-proxy"
    work.mkdir(parents=True)
    config = {"mixed-port": 17890, "mode": "rule", "log-level": "info",
              "proxies": subscription["proxies"], "rules": ["MATCH,old-device"]}
    (work / "config.yaml").write_text(json.dumps(config))
    run(["mihomo", "-t", "-d", work], env=env)
    with (HOME / "mihomo.log").open("w") as log:
        process = subprocess.Popen(["mihomo", "-d", str(work)], env=env, stdout=log, stderr=log,
                                   start_new_session=True)
    (work / "pid").write_text(str(process.pid))
    for _ in range(100):
        assert process.poll() is None, "Mihomo exited"
        try:
            socket.create_connection(("127.0.0.1", 17890), timeout=0.1).close()
            break
        except OSError:
            time.sleep(0.1)
    else:
        raise AssertionError("Mihomo listener did not start")
    # The new local proxy already routes through the downloaded old-device port.
    assert download("https://example.com", LOCAL)
    (HOME / "handover.json").write_text(json.dumps({"local": LOCAL, "upstream": proxy}))
    print("PASS: encrypted store link downloaded; local Mihomo uses the permanent upstream port", flush=True)


def verify():
    with socket.socket() as connection:
        connection.settimeout(2)
        assert connection.connect_ex((OLD_IP, 18080)) != 0, "Temporary proxy was not shut down"
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({"http": TEMPORARY, "https": TEMPORARY}))
    try:
        opener.open("https://example.com", timeout=5)
    except OSError:
        pass
    else:
        raise AssertionError("Temporary proxy can still reach the Internet")
    assert_no_internet()
    assert download("https://example.com", LOCAL)
    env = proxy_environment(LOCAL)
    # Keep the one-time bootstrap marker out of the post-handover process. The
    # proxy works through ordinary HTTP(S)_PROXY variables on a daily apply.
    env.pop("BOOTSTRAP_PROXY", None)
    env.update(DOTFILES_SKIP_APP_INIT="1", DOTFILES_SKIP_SERVICES="1", DOTFILES_SKIP_HOOKS="1",
               GNUPGHOME=str(HOME / ".gnupg"), CHECKPOINT_DISABLE="1")
    before = hashlib.sha256((HOME / ".ssh/id_ed25519").read_bytes()).hexdigest()
    # Prove package downloads/installation still work after cutting off the temporary
    # proxy, rather than merely testing an already-cached apply with no network I/O.
    assert subprocess.run(["pacman", "-Q", "tree"], capture_output=True).returncode != 0
    run(["paru", "-S", "--needed", "--noconfirm", "tree"], env=env)
    run(["tree", "--version"], env=env)
    run([HOME / ".local/bin/chezmoi", "--source", SOURCE, "--config", CONFIG, "--refresh-externals=never",
         "apply", "--keep-going"], env=env)
    assert hashlib.sha256((HOME / ".ssh/id_ed25519").read_bytes()).hexdigest() == before
    # An additional network fetch makes late proxy failures visible independently of apply.
    run(["curl", "-fsS", "--max-time", "45", "https://example.com", "-o", "/dev/null"], env=env)
    print("PASS: temporary port closed; direct Internet blocked; permanent proxy, package installation and daily apply succeed", flush=True)


if __name__ == "__main__":
    {"install": install, "handover": handover, "verify": verify}[sys.argv[1]]()
