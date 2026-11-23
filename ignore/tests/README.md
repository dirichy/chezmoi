# Dotfiles tests

```bash
./ignore/tests/test.sh                  # only groups with changed inputs since their last pass
./ignore/tests/test.sh --dry-run        # show what would run and why
./ignore/tests/test.sh --list           # list groups and dependency globs
./ignore/tests/test.sh rime-native      # force a particular group
./ignore/tests/test.sh proxy services   # force several groups
./ignore/tests/test.sh --all            # force the full regression suite
```

The first run establishes a baseline and runs every default group. Later runs
compare dependency file names, contents, executable modes and symlink targets
against each group's last successful run. This includes staged, unstaged and
untracked files; it does not depend on a commit or just on modification times.
A failure discards that group's cached pass. Optional checks skipped because a
tool is absent remain pending. Changes to the runner or detected tool/platform
identity invalidate cached passes. Use `--all` after other environment changes
(for example, changing a library without changing its package metadata).

Pass records live in the Git-ignored `ignore/tests/.cache/`, never in the real
home or chezmoi state. `--cache-dir PATH` selects another location; losing the
cache simply causes tests to run again. Explicit group names always force a run.
The runner executes groups sequentially and reports their durations.

Dependencies are declared in [dependencies.py](dependencies.py), using
repository-relative globs (`*` also matches `/`). Every group also depends on the
runner, its own script and shared fixture helpers. Add indirect template includes,
source hashes, fixtures and mock commands when updating a test. `profiles` also
checks deployed source file names, so additions, deletions and renames trigger
managed-set assertions even when the affected file is not a template. Shared
configuration changes can select multiple groups; template dependencies are
limited to those each group uses.

| Groups | Coverage / main inputs |
| --- | --- |
| `runner` | Incremental selection, content/mode/name changes, failures, skips and force options in a disposable Git repo |
| `installers`, `install-entry` | Package templates and standalone bootstrap, with mocked installers |
| `install-macos` | Offline isolation, init-data and proxy-wiring checks for the macOS CI fixture |
| `maintenance` | Apply hooks and referenced app resources |
| `downloads` | External download definitions, mirror templates, probe helper and timer |
| `rime-tiger` | Dictionary/Emoji generation and local Git external ordering |
| `rime-deploy` | Android deployment helper with fake ADB |
| `rime-native`, `rime-android` | Actual librime input against isolated desktop/Android fixtures |
| `rime-lua`, `rime-config` | Lua input helpers and Fcitx5 switching configuration |
| `profiles` | Managed/ignored paths for desktop, headless and skip |
| `render` | All managed files rendered for three profiles, Waybar and platform output checks |
| `proxy`, `cidr`, `hypr-helper` | Proxy routing, CIDR template and desktop command fallback |
| `services`, `config-share`, `later` | Service mocks, sharing server and one-off scheduling |
| `syntax` | Non-template Bash/Zsh and standalone Lua syntax |

Rendering uses one uncompressed `chezmoi archive` per profile, rather than
starting chezmoi for each managed file. This renders the target state without
executing apply hooks. Behavioral assertions are in `groups/` and Python/Lua
integration tests remain individually readable alongside the runner.

The suite selects Linux or macOS fixtures according to the host OS. Run it on
both platforms to cover both platform-specific file sets. It uses a temporary
source copy with `.chezmoiexternal.toml` disabled, plus isolated destination,
cache, and state paths. It does not download external resources, install
packages, apply files to the real home directory, or control real services.
Required dependencies are `chezmoi`, Git, Bash, Zsh and Python 3.11+ (for
`tomllib`); macOS checks also use the system-provided `plutil`. Lua behavior and
syntax checks use optional `lua` and `luac`; installer lint uses `shellcheck`
when available. Native Rime tests require Linux, `cc`, `pkg-config`, librime
development files and librime-lua. Missing optional dependencies are reported as
skipped. Fully mocked service logic runs on both platforms.

GUI authorization, application behavior and real service startup still require
manual verification on the corresponding platform. Add behavioral assertions to
`groups/profiles.sh` whenever a profile gains or loses an important file.

A separate real enrollment integration test requires OpenSSH (including sshd), GnuPG,
gopass, Mihomo, Git, Python and chezmoi. Run it as a normal user **inside a disposable
namespace/container** with an empty work path:

```bash
python3 ignore/tests/test-enrollment.py /work/source /work/enrollment-test
```

It uses fake identities and a fake encrypted store, never imports a private key,
requires public-key SSH authorization before cloning through a local HTTP CONNECT
proxy, then runs the real `add-device` on the simulated old device. It checks that
only after authorization and Git synchronization can the new device decrypt
`chezmoi/bootstrap-check = fixture-device-enrollment-ok`. It also renders a native
chezmoi secret and forwards a local HTTP request through real Mihomo. No external
resources are downloaded. This test is intentionally separate from the default
suite because it starts listeners and agents and needs all of those dependencies.
The default suite mocks paru bootstrap and verifies it never runs in check-only mode.

For an actual network-restricted Arch installation including **real paru build and
installation**, see [install-lan/README.md](install-lan/README.md). The matching
GitHub Actions workflow uses old/new device containers and cuts off the temporary
LAN proxy after fetching the permanent upstream address from an encrypted store's
subscription link. It is separate from `test.sh` because it downloads/installs
actual packages in disposable containers and needs Docker, network access and
substantial build time.

For native macOS installation, Mihomo forwarding and real CLI package installation,
see [install-macos/README.md](install-macos/README.md). The workflow uses a disposable
GitHub-hosted VM; that network/package scenario remains separate from the default
offline suite. Its fixture checks are included as the `install-macos` group.
