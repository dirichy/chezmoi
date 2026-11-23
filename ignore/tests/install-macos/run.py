#!/usr/bin/env python3
"""Real macOS installation smoke test, restricted to disposable GitHub-hosted runners."""

import argparse
import http.server
import json
import os
import runpy
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import threading
import time
import tomllib


def prepare(repo, root, desktop):
    root.mkdir()  # Refuse to reuse a nonempty installation, cache or state.
    source, home = root / "source", root / "home"
    shutil.copytree(repo, source, ignore=shutil.ignore_patterns(".git", ".cache", "__pycache__"))
    (source / ".chezmoiexternal.toml").write_text("")
    home.mkdir()
    logs = root / "logs"
    logs.mkdir()
    config = root / "chezmoi.toml"
    modules = "core,desktop" if desktop else "core"
    answers = (repo / "ignore/tests/fixtures/install-macos/answers.toml").read_text()
    config.write_text(answers.replace('modules = "core"', f'modules = "{modules}"'))
    # Desktop init enables input-method templates. Seed tiny local upstreams only.
    for scheme in ("rime-ice", "rime-tiger"):
        upstream = home / ".cache" / scheme / "upstream"
        upstream.mkdir(parents=True)
        for path in (repo / "ignore/tests/fixtures" / scheme).glob("*.yaml"):
            shutil.copy2(path, upstream)
        (upstream / "opencc").mkdir()
        (upstream / "opencc/emoji.txt").write_text("笑\t笑 😄\n")
    return source, home, config, logs


def environment(home, root):
    env = dict(os.environ)
    # Keep all user configuration/keyrings away from the runner account's home.
    env.update(HOME=str(home), ZDOTDIR=str(home / ".config/zsh"),
               XDG_CONFIG_HOME=str(home / ".config"), XDG_CACHE_HOME=str(home / ".cache"),
               XDG_DATA_HOME=str(home / ".local/share"), XDG_STATE_HOME=str(home / ".local/state"),
               GNUPGHOME=str(home / ".gnupg"), GIT_CONFIG_GLOBAL=str(home / ".gitconfig"),
               GOPASS_CONFIG_NOSYSTEM="true", GOPASS_NO_NOTIFY="true", CHECKPOINT_DISABLE="1",
               HOMEBREW_CACHE=str(root / "brew-cache"), HOMEBREW_LOGS=str(root / "brew-logs"),
               HOMEBREW_NO_AUTO_UPDATE="1", HOMEBREW_NO_INSTALL_CLEANUP="1",
               HOMEBREW_NO_ANALYTICS="1", NONINTERACTIVE="1", CI="1",
               DOTFILES_SKIP_APP_INIT="1", DOTFILES_SKIP_SERVICES="1", DOTFILES_SKIP_HOOKS="1",
               PYTHONPYCACHEPREFIX=str(root / "pycache"))
    env["PATH"] = str(home / ".local/bin") + os.pathsep + env["PATH"]
    return env


def proxy_environment(env, address):
    result = dict(env)
    for key in ("http_proxy", "https_proxy", "all_proxy", "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"):
        result[key] = address
    result.update(no_proxy="", NO_PROXY="")
    return result


def proxy_config(port, upstream_port):
    return {"mixed-port": port, "bind-address": "127.0.0.1", "allow-lan": False,
            "mode": "rule", "log-level": "info", "geo-auto-update": False,
            "proxies": [{"name": "fixture-upstream", "type": "http",
                         "server": "127.0.0.1", "port": upstream_port}],
            "rules": ["MATCH,fixture-upstream"]}


def verify_network(repo, root, env, run):
    # Reuse the Linux fixture's real HTTP/CONNECT forwarding, bound to loopback here.
    proxy = runpy.run_path(str(repo / "ignore/tests/install-lan/lan-services.py"))["Proxy"]

    class RecordingProxy(proxy):
        def do_CONNECT(self):
            self.server.destinations.append(self.path)
            super().do_CONNECT()

        def log_message(self, message, *args):
            with (root / "logs/upstream.log").open("a") as stream:
                stream.write((message % args) + "\n")

    upstream = http.server.ThreadingHTTPServer(("127.0.0.1", 0), RecordingProxy)
    upstream.destinations = []
    thread = threading.Thread(target=upstream.serve_forever, daemon=True)
    thread.start()
    with socket.socket() as reservation:
        reservation.bind(("127.0.0.1", 0))
        port = reservation.getsockname()[1]
    address = f"http://127.0.0.1:{port}"
    proxy_env = proxy_environment(env, address)
    work = root / "mihomo"
    work.mkdir()
    (work / "config.yaml").write_text(json.dumps(proxy_config(port, upstream.server_port)))
    process = None
    try:
        run("mihomo-config", ["mihomo", "-t", "-d", work])
        with (root / "logs/mihomo.log").open("w") as stream:
            process = subprocess.Popen(["mihomo", "-d", str(work)], env=env,
                                       stdin=subprocess.DEVNULL, stdout=stream, stderr=subprocess.STDOUT)
        for _ in range(100):
            if process.poll() is not None:
                raise RuntimeError("Mihomo exited before opening its listener; see mihomo.log")
            try:
                with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                    break
            except OSError:
                time.sleep(0.1)
        else:
            raise RuntimeError("Mihomo did not open its listener")
        curl = ["/usr/bin/curl", "--fail", "--silent", "--show-error", "--max-time", "20",
                "--noproxy", "", "--proxy", address, "https://example.com", "--output", os.devnull]
        run("https-through-mihomo", curl, env=proxy_env)
        assert "example.com:443" in upstream.destinations, "HTTPS bypassed the configured upstream"
        installed = run("formulae-before-proxy-install", ["brew", "list", "--formula", "--versions"])
        names = {line.split()[0] for line in installed.splitlines() if line.strip()}
        package = next((name for name in ("hello", "cowsay") if name not in names), None)
        assert package, "all smoke-test CLI packages are already installed on this runner"
        # Separate, initially empty cache: preinstalled packages/bottles cannot satisfy the fetch.
        proxy_env["HOMEBREW_CACHE"] = str(root / "proxy-download-cache")
        before = len(upstream.destinations)
        run("fetch-cli-through-mihomo", ["brew", "fetch", "--force", "--force-bottle", package], env=proxy_env)
        assert any(host == "ghcr.io:443" for host in upstream.destinations[before:]), "bottle fetch bypassed the upstream"
        run("install-cli-through-mihomo", ["brew", "install", "--force-bottle", package], env=proxy_env)
        prefix = run("cli-prefix", ["brew", "--prefix"], env=proxy_env).strip()
        executable = Path(prefix) / "bin" / package
        assert os.access(executable, os.X_OK), "installed CLI is not executable"
        run("installed-cli", [executable, "--version" if package == "hello" else "ci-fixture"], env=proxy_env)
        upstream.shutdown()
        upstream.server_close()
        thread.join(timeout=5)
        assert process.poll() is None, "Mihomo exited before the upstream failure control"
        run("closed-upstream-must-fail", curl, env=proxy_env, success=False, timeout=30)
        assert process.poll() is None, "upstream failure crashed Mihomo"
        process.terminate()
        process.wait(timeout=15)
        run("stopped-mihomo-must-fail", curl, env=proxy_env, success=False, timeout=30)
    finally:
        if thread.is_alive():
            upstream.shutdown()
            upstream.server_close()
            thread.join(timeout=5)
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work", required=True, type=Path)
    parser.add_argument("--desktop", action="store_true", help="also install the real desktop module")
    args = parser.parse_args()
    if (sys.platform != "darwin" or os.environ.get("GITHUB_ACTIONS") != "true"
            or os.environ.get("RUNNER_ENVIRONMENT") != "github-hosted"):
        parser.error("real package installation is allowed only in a disposable GitHub-hosted macOS job")
    repo = Path(__file__).resolve().parents[3]
    root = args.work.resolve()
    source, home, config, logs = prepare(repo, root, args.desktop)
    env = environment(home, root)

    def run(label, command, timeout=1800, *, env=env, success=True):
        print(f"==> {label}", flush=True)
        path = logs / f"{label}.log"
        with path.open("w") as stream:
            try:
                result = subprocess.run(list(map(str, command)), env=env, stdin=subprocess.DEVNULL,
                                        stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
            finally:
                print(path.read_text(), end="", flush=True)
        if (result.returncode == 0) != success:
            raise RuntimeError(f"{label} failed with exit {result.returncode}; see {path}")
        return path.read_text()

    run("platform", ["/usr/bin/sw_vers"])
    run("command-line-tools", ["/usr/bin/xcode-select", "-p"])
    run("sudo", ["/usr/bin/sudo", "-n", "true"])
    run("brew-before", ["brew", "list", "--versions"])
    command = ["/bin/bash", source / "install.sh", "--source", source, "--destination", home,
               "--config", config, "--cache", root / "chezmoi-cache", "--state", root / "state.boltdb",
               "--yes", "--skip-identity", "--skip-services", "--skip-plugins", "--skip-hooks"]
    run("install", [*command, "--init"])
    data = tomllib.loads(config.read_text())["data"]
    assert data["install"]["modules"] == ("core,desktop" if args.desktop else "core")
    assert data["features"]["macDesktop"] == args.desktop
    assert data["features"]["linuxDesktop"] is False
    assert (home / ".gitconfig").is_file()
    assert (home / ".config/mihomo/config.yaml").is_file()
    run("mihomo-plist", ["/usr/bin/plutil", "-lint", home / "Library/LaunchAgents/mihomo.plist"])
    cm = shutil.which("chezmoi", path=env["PATH"])
    assert cm, "installer did not make chezmoi available"
    base = [cm, "--source", source, "--destination", home, "--config", config,
            "--cache", root / "chezmoi-cache", "--persistent-state", root / "state.boltdb",
            "--refresh-externals=never", "--no-tty"]
    check = run("dependencies", ["/bin/bash", source / "ignore/bin/dotfiles-packages", "--check",
                                 "--destination", home, "--config", config, "--cache", root / "chezmoi-cache",
                                 "--persistent-state", root / "state.boltdb", "--refresh-externals=never"])
    assert "Warning: missing dependencies:" not in check
    if args.desktop:
        run("karabiner-json", ["/usr/bin/plutil", "-lint", home / ".config/karabiner/karabiner.json"])
        assert (home / ".hammerspoon/init.lua").is_file()
    repeat = run("install-again", command)
    assert "Existing checkout and init answers found; reusing them." in repeat
    assert "Installing formula:" not in repeat and "Installing cask:" not in repeat
    run("apply-again", [*base, "apply", "--keep-going"])
    # Use a separate stdout file: chezmoi diagnostics must not be confused with a diff.
    diff = subprocess.run([*map(str, base), "diff", "--exclude", "scripts"], env=env,
                          stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=120)
    (logs / "diff.log").write_text(diff.stdout + diff.stderr)
    assert diff.returncode == 0 and not diff.stdout.strip(), "apply did not converge; see diff.log"
    verify_network(repo, root, env, run)
    summary = {
        "result": "passed", "modules": data["install"]["modules"],
        "verified": ["real Homebrew packages", "native init/apply", "repeat install", "repeat apply", "plist/JSON",
                     "HTTPS via real Mihomo and a recording CONNECT upstream",
                     "uncached CLI bottle fetch/install via Mihomo", "upstream/Mihomo failure controls"],
        "not_verified": ["fresh Homebrew/CLT bootstrap", "device enrollment", "production externals",
                         "production proxy subscriptions", "network-wide direct-egress blocking",
                         "plugin downloads", "GUI/TCC authorization", "real user services", "app logins", "SIP/scripting addition"],
    }
    (logs / "summary.log").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
