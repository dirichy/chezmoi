#!/usr/bin/env python3
"""Check apply maintenance cadence in a minimal, fully isolated source tree."""

import os
from pathlib import Path
import shutil
import subprocess
import sys

repo, temporary = map(Path, sys.argv[1:])
root = temporary / "maintenance"
source, home = root / "source", root / "home"
source.mkdir(parents=True)
home.mkdir()
log = root / "events"
log.write_text("")
files = [
    "run_after_reconcile-user-services.sh.tmpl",
    "run_once_before_configure-chezmoi-git-hooks.sh.tmpl",
    "run_onchange_after_prepare-app-resources.sh.tmpl",
    ".chezmoitemplates/preferChezmoiDownloads",
    ".chezmoitemplates/zsh-plugin-repos",
    "dot_config/zsh/plugin-manager.zsh",
    "dot_config/nvim/lua/lazy_nvim.lua",
    "dot_config/nvim/lua/plugins/lsp.lua",
    "dot_config/yazi/package.toml",
    "dot_config/mihomo/config.yaml.tmpl",
]
for name in files:
    target = source / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(repo / name, target)
# Referenced config sources are used only for hashes. No app is started for real.
(source / ".chezmoiignore").write_text(".config\nignore\n")
helper = source / "ignore/bin/dotfiles-services"
helper.parent.mkdir(parents=True)
helper.write_text('#!/bin/sh\nprintf "services\\n" >> "$TEST_MAINTENANCE_LOG"\n')
helper.chmod(0o755)
(home / ".config/yazi").mkdir(parents=True)
(home / ".config/yazi/package.toml").write_text("")
config = root / "config.toml"
fixture = (repo / "ignore/tests/fixtures/linux-headless.toml").read_text()
fixture = fixture.replace('[data.apps.mihomo]\nenabled = false', '[data.apps.mihomo]\nenabled = true')
config.write_text(fixture)
subprocess.run(["git", "init", "-q", str(source)], check=True)
# Functions take precedence over standard Homebrew PATH entries on macOS too.
shell_env = root / "bash-env"
shell_env.write_text('''
nvim() { printf 'nvim\\n' >> "$TEST_MAINTENANCE_LOG"; return "${TEST_NVIM_EXIT:-0}"; }
ya() { printf 'yazi\\n' >> "$TEST_MAINTENANCE_LOG"; }
mihomo() { printf 'mihomo\\n' >> "$TEST_MAINTENANCE_LOG"; }
''')
env = {key: value for key, value in os.environ.items() if not key.startswith("DOTFILES_")}
env.update(HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
           XDG_CACHE_HOME=str(home / ".cache"), XDG_DATA_HOME=str(home / ".local/share"),
           XDG_STATE_HOME=str(home / ".local/state"), BASH_ENV=str(shell_env),
           TEST_MAINTENANCE_LOG=str(log))
command = ["chezmoi", "--source", str(source), "--destination", str(home),
           "--config", str(config), "--cache", str(root / "cache"),
           "--persistent-state", str(root / "state"), "--refresh-externals=never",
           "--no-tty", "apply", "--keep-going"]


def apply(extra=None, expected=0):
    log.write_text("")
    result = subprocess.run(command, env=dict(env, **(extra or {})), capture_output=True, text=True)
    assert result.returncode == expected, result
    return log.read_text().splitlines()


# Skip flags only affect this apply; they must not consume run_once/run_onchange state.
assert apply(dict(DOTFILES_SKIP_HOOKS="1", DOTFILES_SKIP_APP_INIT="1", DOTFILES_SKIP_SERVICES="1")) == []
assert set(apply()) == {"nvim", "yazi", "mihomo", "services"}
assert subprocess.check_output(["git", "-C", str(source), "config", "--get", "core.hooksPath"], text=True).strip() == ".githooks"
assert apply() == ["services"]
plugin = source / "dot_config/nvim/lua/plugins/lsp.lua"
plugin.write_text(plugin.read_text() + "\n-- fixture configuration change\n")
assert set(apply()) == {"nvim", "yazi", "mihomo", "services"}
# Failure is reported, subsequent services still run, and unchanged failed resources retry.
plugin.write_text(plugin.read_text() + "\n-- retry fixture\n")
assert set(apply(dict(TEST_NVIM_EXIT="7"), expected=1)) == {"nvim", "yazi", "mihomo", "services"}
assert set(apply()) == {"nvim", "yazi", "mihomo", "services"}
assert apply() == ["services"]
# A future change to daily service capabilities is picked up without reinstalling.
helper.write_text(helper.read_text() + 'printf "new-service-capability\\n" >> "$TEST_MAINTENANCE_LOG"\n')
assert apply() == ["services", "new-service-capability"]
print("Maintenance: per-apply services, changed resources, failed-step retries and deferred first-run hooks passed")
