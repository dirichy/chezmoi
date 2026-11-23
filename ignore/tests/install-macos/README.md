# macOS installation CI

The `Install on macOS` workflow runs on GitHub's `macos-15` Apple Silicon runner.
Relevant pushes to `main` or `ci/**`, and pull requests, run the `custom/core` installation. `workflow_dispatch`
also accepts `desktop: true`, which adds the real desktop formulae/casks without
launching the desktop tools to grant permissions.

The driver requires a disposable GitHub-hosted macOS job and refuses to run on a
normal workstation. The work directory must not exist. Installation uses a source
copy, synthetic init answers, a temporary HOME, and separate config/cache/state
paths. Homebrew installs real packages into the disposable VM's normal prefix;
its download cache and logs are redirected into the test workspace. The checkout
and runner user's dotfiles are not the installation destination.

The scenario verifies:

1. Existing Xcode Command Line Tools and passwordless sudo are usable. Run the
   actual `install.sh --init --yes` with core modules; bootstrap chezmoi if it is
   absent, install missing Homebrew dependencies, and execute native init/apply.
2. Check generated feature flags, files and LaunchAgent plist syntax. The optional
   desktop scenario also checks Karabiner JSON and the Hammerspoon entry point.
3. Check for missing selected dependencies, repeat the installer using saved init
   answers without installing packages again, repeat apply, and require an empty
   file diff.
4. Start the installed Mihomo with an isolated fixture configuration. The route is
   `curl/Homebrew -> Mihomo -> recording HTTP CONNECT upstream -> Internet`.
   The upstream is a loopback fixture reusing the Linux CI forwarding helper;
   `MATCH,fixture-upstream` provides no DIRECT fallback. No Geo database or
   production subscription is needed.
5. Force an HTTPS request through Mihomo and require the upstream to observe it.
   Choose an absent small CLI formula (`hello` or `cowsay`), use a fresh Homebrew
   download cache, fetch its bottle through Mihomo, require an upstream connection
   to `ghcr.io`, then really install and execute it through the same proxy setup.
6. Stop the upstream and require the same HTTPS request to fail; stop Mihomo and
   require failure again. Processes and loopback listeners are cleaned up on exit.
7. Run the full regression suite natively on macOS, including plist/JSON checks
   and the macOS service wrapper with mocked service operations.

Logs and a successful-run coverage summary are uploaded from `logs/*.log` only.
No home, keyring, configuration tree, bottle cache or real credentials are uploaded.

## What this does not require or prove

The core chain does not control windows, monitor input, use TUN, change the system
proxy or start desktop services, so it needs no Accessibility/Input Monitoring
consent. GitHub's runner already has Homebrew and CLT: this is not a bare-machine
bootstrap test. Available packages are reused, and the initial brew inventory is
logged. External downloads declared in `.chezmoiexternal.toml` are disabled;
input-method rendering uses small checked-in dictionary fixtures.

Unlike the Linux container scenario, direct Internet access is not blocked for the
whole VM. Explicit client proxies, upstream request recording and failure controls
verify the tested traffic path. This does not validate personal subscriptions,
GPG enrollment, real LaunchAgent startup, plugin downloads, logins or desktop
behavior. The optional desktop package installation may expose cask-specific
installer/reboot requirements, but passing it does not certify GUI permissions.

## Desktop permissions and virtual machines

A physical Mac is not required just to test Accessibility APIs: a macOS VM with
an interactive login session and appropriate authorization can run desktop tests.
A prepared VM snapshot or dedicated runner can retain a manually approved test
identity. Where supported, managed Macs can receive privacy permissions through
[MDM/PPPC](https://support.apple.com/guide/deployment/dep38df53c2a/web).

An ordinary fresh GitHub-hosted VM does not inherit our approvals. Passwordless
sudo is distinct from TCC consent. Apple's documented
[`tccutil reset`](https://developer.apple.com/documentation/xcode/resetting-access-to-protected-resources-in-macos)
removes decisions; it is not a general grant command. Direct TCC database edits
are an image/version-dependent workaround, not a portable authorization mechanism.
No TCC database or SIP changes are part of this workflow.

Other apps also split coverage. Hammerspoon runs XCTest in
[GitHub Actions](https://github.com/Hammerspoon/hammerspoon/blob/master/.github/workflows/ci_testbuild.yml),
while [its window tests](https://github.com/Hammerspoon/hammerspoon/blob/master/Hammerspoon%20Tests/HSwindow.m)
explicitly skip several operations there. For this repository, verifying actual
window movement/key remapping would be a separate authorized desktop scenario.
Yabai's scripting addition additionally has SIP requirements; an Accessibility
grant alone does not enable that feature.

The fixture controls can be checked offline on Linux or macOS without installing
packages or starting the real network scenario:

```bash
./ignore/tests/test.sh install-macos
```
