#!/usr/bin/env python3
"""Exercise rendered installers with failing package managers, without installing anything."""

import os
from pathlib import Path
import shutil
import subprocess
import sys

repo, temporary = map(Path, sys.argv[1:])
root = temporary / "installers"
root.mkdir()
bin_dir = root / "bin"
bin_dir.mkdir()
home = root / "home"
home.mkdir()
log = root / "calls"


def mock(name, body):
    target = bin_dir / name
    target.write_text("#!/bin/sh\n" + body + "\n")
    target.chmod(0o755)


mock("pacman", "exit 1")
mock("install-mock", 'echo "$*" >> "$INSTALL_TEST_LOG"; exit 1')
mock("brew", '''case "$1" in
shellenv) exit 0 ;;
list) exit 1 ;;
install) echo "$*" >> "$INSTALL_TEST_LOG"; exit 1 ;;
*) exit 99 ;;
esac''')
mock("xcode-select", "exit 0")
mock("curl", "echo 'unexpected network access' >&2; exit 99")
env = dict(os.environ, PATH=f"{bin_dir}:/usr/bin:/bin", HOME=str(home),
           XDG_CONFIG_HOME=str(home / ".config"), XDG_CACHE_HOME=str(home / ".cache"),
           INSTALL_TEST_LOG=str(log), INSTALL_PROFILE="custom", INSTALL_MODULES="core,shell,proxy",
           INSTALL_COMMAND="install-mock", INSTALL_ADMIN="false", SKIP_SERVICES="1",
           SKIP_LUAROCKS="1")

for platform in ("linux", "macos"):
    shell = "bash"
    if not shutil.which(shell):
        print(f"# skip - {platform} installer behavior requires {shell}")
        continue
    shell = shutil.which(shell)
    runtime_env = dict(env, PATH=str(bin_dir))
    for phase, name in (("before", "core"), ("after", "packages")):
        source = repo / f"run_onchange_{phase}_install-{name}-{platform}.sh.tmpl"
        rendered = root / f"{platform}-{phase}.sh"
        command = ["chezmoi", "--source", str(repo), "--destination", str(home),
                   "--config", str(repo / f"ignore/tests/fixtures/{platform}-desktop.toml"),
                   "--cache", str(root / "cache"), "--persistent-state", str(root / "state"),
                   "--refresh-externals=never", "execute-template", "--file", str(source)]
        rendered.write_text(subprocess.check_output(command, text=True, env=env))
        subprocess.run([shell, "-n", str(rendered)], check=True)
        if shutil.which("shellcheck"):
            subprocess.run(["shellcheck", str(rendered)], check=True)
        log.write_text("")
        result = subprocess.run([shell, str(rendered)], env=runtime_env, capture_output=True, text=True)
        assert result.returncode == (1 if phase == "before" else 0), result
        assert f"Installation failures ({phase}):" in result.stderr, result.stderr
        calls = log.read_text().splitlines()
        assert len(calls) >= 2, calls
        if phase == "before":
            assert not any("mihomo" in call for call in calls), calls
            assert any("gopass" in call for call in calls), calls
        else:
            assert any("neovim" in call for call in calls), calls
            assert any("mihomo" in call for call in calls), calls
            assert not any("gopass" in call for call in calls), calls
        # Profiles and explicit module lists share dispatch on both platforms.
        log.write_text("")
        profiled = subprocess.run([shell, str(rendered)],
                                  env=dict(runtime_env, INSTALL_PROFILE="desktop", INSTALL_MODULES=""),
                                  capture_output=True, text=True)
        assert profiled.returncode == (1 if phase == "before" else 0), profiled
        assert ("mihomo" in log.read_text()) == (phase == "after"), log.read_text()
        log.write_text("")
        selected = subprocess.run([shell, str(rendered)],
                                  env=dict(runtime_env, INSTALL_MODULES=" shell, font-and-im proxy "),
                                  capture_output=True, text=True)
        assert selected.returncode == (1 if phase == "before" else 0), selected
        calls = log.read_text()
        assert "gopass" not in calls, calls
        if phase == "after":
            assert "mihomo" in calls and "neovim" in calls, calls
            assert ("android-tools" if platform == "linux" else "--cask android-platform-tools") in calls, calls
        else:
            assert "neovim" not in calls and "python" in calls, calls
        if platform == "macos":
            mock("xcode-select", "exit 1")
            unavailable = subprocess.run([shell, str(rendered)], env=runtime_env,
                                         capture_output=True, text=True)
            assert unavailable.returncode == (1 if phase == "before" else 0), unavailable
            assert f"Installation failures ({phase}):" in unavailable.stderr, unavailable.stderr
            mock("xcode-select", "exit 0")
        # A skip profile must never call the package manager, even with module overrides.
        log.write_text("")
        skipped = subprocess.run([shell, str(rendered)], env=dict(runtime_env, INSTALL_PROFILE="skip"),
                                 capture_output=True, text=True)
        assert skipped.returncode == 0 and not log.read_text(), skipped
        # Existing packages make the entire phase succeed.
        if platform == "linux":
            mock("pacman", "exit 0")
        else:
            mock("brew", 'case "$1" in shellenv|list) exit 0 ;; *) exit 99 ;; esac')
        successful = subprocess.run([shell, str(rendered)], env=runtime_env, capture_output=True, text=True)
        assert successful.returncode == 0, successful
        assert "Installation failures" not in successful.stderr, successful.stderr
        if platform == "linux":
            mock("pacman", "exit 1")
        else:
            mock("brew", '''case "$1" in
shellenv) exit 0 ;;
list) exit 1 ;;
install) echo "$*" >> "$INSTALL_TEST_LOG"; exit 1 ;;
*) exit 99 ;;
esac''')

# Verify chezmoi runs before scripts before rendering dependent files.
source = root / "ordering-source"
source.mkdir()
marker = root / "dependency-ready"
mock("install-mock", f'case "$1" in neovim|mihomo) exit 1 ;; esac; /usr/bin/touch "{marker}"; exit 0')
(source / "run_onchange_before_install-core.sh").write_text((root / "linux-before.sh").read_text())
(source / "run_onchange_after_install-packages.sh").write_text((root / "linux-after.sh").read_text())
(source / "dot_dependency.tmpl").write_text('{{ output "/bin/cat" "' + str(marker) + '" }}ready')
command = ["chezmoi", "--source", str(source), "--destination", str(home),
           "--config", str(repo / "ignore/tests/fixtures/linux-desktop.toml"),
           "--cache", str(root / "ordering-cache"), "--persistent-state", str(root / "ordering-state"),
           "--refresh-externals=never", "--no-tty", "apply"]
# Force a package installation even if the host already has core commands.
mock("pacman", "exit 1")
(bin_dir / "bash").symlink_to(shutil.which("bash"))
command[0] = shutil.which("chezmoi")
result = subprocess.run(command, env=runtime_env, capture_output=True, text=True)
assert result.returncode == 0 and (home / ".dependency").read_text() == "ready", result
assert "Installation failures (after):" in result.stderr, result.stderr
marker.unlink()
(home / ".dependency").unlink()
mock("install-mock", "exit 1")
before = source / "run_onchange_before_install-core.sh"
before.write_text(before.read_text() + "\n# Retry core installation.\n")
result = subprocess.run(command, env=runtime_env, capture_output=True, text=True)
assert result.returncode != 0 and not (home / ".dependency").exists(), result
assert "Installation failures (before):" in result.stderr, result.stderr
