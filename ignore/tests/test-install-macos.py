#!/usr/bin/env python3
"""Offline checks for macOS CI fixture isolation, native init data and proxy wiring."""

import json
import os
import plistlib
import shutil
from pathlib import Path
import runpy
import subprocess
import sys
import tomllib

repo, temporary = map(Path, sys.argv[1:])
module = runpy.run_path(str(repo / "ignore/tests/install-macos/run.py"))
for desktop in (False, True):
    root = temporary / ("macos-desktop" if desktop else "macos-core")
    source, home, config, logs = module["prepare"](repo, root, desktop)
    assert not (source / ".chezmoiexternal.toml").read_text()
    assert not (source / ".git").exists()
    env = module["environment"](home, root)
    for key in ("HOME", "ZDOTDIR", "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_DATA_HOME",
                "XDG_STATE_HOME", "GNUPGHOME", "GIT_CONFIG_GLOBAL", "HOMEBREW_CACHE", "HOMEBREW_LOGS"):
        assert Path(env[key]).is_relative_to(root), key
    for key in ("DOTFILES_SKIP_APP_INIT", "DOTFILES_SKIP_SERVICES", "DOTFILES_SKIP_HOOKS"):
        assert env[key] == "1"
    command = ["chezmoi", "--source", str(source), "--destination", str(home), "--config", str(config),
               "--cache", str(root / "cache"), "--persistent-state", str(root / "state"),
               "--refresh-externals=never", "--no-tty", "--override-data", '{"chezmoi":{"os":"darwin"}}']
    if sys.platform == "darwin":
        initialized = subprocess.run(command + ["init"], env=env, stdin=subprocess.DEVNULL,
                                     capture_output=True, text=True, timeout=30)
        assert initialized.returncode == 0, initialized.stdout + initialized.stderr
    else:
        # init always uses the native OS; execute-template supports a Darwin override on Linux.
        rendered = subprocess.check_output(command + ["execute-template", "--init", "--stdinisatty=false",
                                            "--file", str(source / ".chezmoi.toml.tmpl")], env=env, text=True)
        config.write_text(rendered)
    data = tomllib.loads(config.read_text())["data"]
    assert data["install"]["modules"] == ("core,desktop" if desktop else "core")
    assert data["features"]["macDesktop"] == desktop
    assert data["features"]["linuxDesktop"] is False
    assert data["features"]["inputMethod"] == desktop
    assert data["downloads"]["githubMirrorPrefix"] == ""
    assert data["configShare"]["mode"] == "none"
    render_config = root / "render.json"
    render_config.write_text(json.dumps({"data": data, "secret": {"command": "echo"}}))
    base = command.copy()
    base[base.index("--config") + 1] = str(render_config)
    managed = subprocess.check_output(base + ["managed", "--include", "files,symlinks", "--path-style", "relative"],
                                      env=env, text=True).splitlines()
    assert ".config/fcitx5/conf/rime.conf" not in managed  # Linux-only, even in the desktop profile.
    assert (".config/karabiner/karabiner.json" in managed) == desktop
    plist = subprocess.check_output(base + ["cat", str(home / "Library/LaunchAgents/mihomo.plist")], env=env)
    assert plistlib.loads(plist)["Label"] == "mihomo"
    if desktop and shutil.which("lua"):
        karabiner = subprocess.check_output(base + ["cat", str(home / ".config/karabiner/karabiner.json")], env=env)
        assert json.loads(karabiner)["profiles"]
    try:
        module["prepare"](repo, root, desktop)
    except FileExistsError:
        pass
    else:
        raise AssertionError("fixture must refuse to reuse installation state")

config = module["proxy_config"](12345, 23456)
assert config["rules"] == ["MATCH,fixture-upstream"]
assert config["allow-lan"] is False and config["bind-address"] == "127.0.0.1"
assert config["proxies"] == [{"name": "fixture-upstream", "type": "http", "server": "127.0.0.1", "port": 23456}]
proxy_env = module["proxy_environment"]({"https_proxy": "stale", "NO_PROXY": "*"}, "http://127.0.0.1:12345")
assert proxy_env["NO_PROXY"] == proxy_env["no_proxy"] == ""
assert all(proxy_env[key] == "http://127.0.0.1:12345" for key in
           ("http_proxy", "https_proxy", "all_proxy", "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"))
blocked = temporary / "must-not-install"
result = subprocess.run([sys.executable, str(repo / "ignore/tests/install-macos/run.py"), "--work", str(blocked)],
                        env=dict(os.environ, GITHUB_ACTIONS="false"), capture_output=True, text=True)
assert result.returncode == 2 and not blocked.exists()
print("macOS CI: isolated core/desktop init, externals disabled, proxy route/bypass controls and hosted-runner guard passed")
