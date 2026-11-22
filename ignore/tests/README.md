# Dotfiles tests

Run the regression suite from anywhere in the repository:

```bash
./ignore/tests/test.sh
```

The suite selects Linux or macOS fixtures according to the host OS. Run it on
both platforms to cover both platform-specific file sets. It uses a temporary
source copy with `.chezmoiexternal.toml` disabled, plus isolated destination,
cache, and state paths. It does not download external resources, install
packages, apply files to the real home directory, or control real services.
It checks:

- the managed file set for `desktop`, `headless`, and `skip` profiles on the current platform;
- rendering of every managed file and template in those profiles;
- macOS LaunchAgent plist parsing, Karabiner JSON, and rendered installer Bash syntax;
- Linux and macOS installer Bash syntax and ShellCheck (when available), mocked package failures,
  shared module selection, installed-package detection, aggregated failures and read-only daily checks;
- the standalone installer before chezmoi/init, temporary proxy inheritance, idempotent retries
  and failure summaries through simulated bootstrap/download/apply commands;
- maintenance Zsh ignoring user startup files and inheriting proxy variables even with broken shell configs;
- maintenance cadence: services on every apply, resources on configuration changes, retries after failure,
  and skipped first-install maintenance remaining available on later applies;
- GitHub mirror init choices/defaults, public download rendering without secrets, bounded-response
  validation through mocks, and an opt-in Linux-only download-check timer (no public network requests);
- external URL fallback using local files, and Geo external entries/native auto-update settings
  following the download preference on Linux and macOS (rendering only; no database downloads);
- Linux and macOS service lifecycle behavior through mocks on either platform;
- the macOS systemctl wrapper with native `plutil` on macOS only (service calls remain mocked);
- desktop CLI integration through deterministic commands in `mock-bin`;
- the caller-provided fallback contract of the chezmoi-only `hyprctl-safe` helper;
- Tiger/Ice Git external platform gates, same-apply update/render ordering, common-character
  selection, generated shorthand recommendations independent of destination write order,
  artifact caching and shared Emoji priority/deduplication with isolated local Git fixtures;
- shared Rime semicolon date commands, independent scheme configuration, numeric prefixes, calculators
  schema menu consistency, and session-only option defaults/preservation when `lua` is available;
- native librime input checks for full-pinyin/Xiaohe radical lookup, auxiliary filtering,
  semicolon candidates, symbol categories/short aliases, shared keyboard/current-page-click/expanded-list-click menu actions,
  private phrase single-value commits, repeated schema switching followed by normal typing, and Tiger repeat after numeric/manual commits
  or during four-code continuous input, fixed second-candidate placement and equivalent
  semicolon/digit-2 selection, literal empty-code display with space/punctuation cleanup and native normal
  commits (including valid ASCII dictionary entries) (including supplementary Unicode characters) on Linux with cc, librime development files
  and librime-lua installed (otherwise skipped; all dictionaries and state are isolated fixtures);
- the Android template branch selected with `--override-data` on all four schemes: backslash commands/selection,
  tilde lookup and radical filtering, literal Enter commits preserving the actual input,
  platform-specific components/key bindings, the function root menu and settings-menu toggles through keyboard and touch,
  and desktop defaults remaining unchanged;
- ownership-preserving Android Rime updates through a local fake ADB, including preflight rejection,
  partial-write rollback and unchanged inode/UID/GID/mode (never accesses a real phone);
- Bash syntax for non-template shell scripts;
- Lua syntax when `luac` is available.

Required dependencies are `chezmoi`, Git, Bash and Python 3.11+ (for `tomllib`); macOS checks also use
Zsh and the system-provided `plutil`. Linux skips checks that require native macOS
tools; fully mocked service logic still runs on both platforms. `luac` is optional.
GUI authorization, application behavior and real service
startup still require manual verification on the corresponding platform. Add behavioral
assertions to `test.sh` whenever a profile gains or loses an important file.

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
