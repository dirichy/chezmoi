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
- macOS LaunchAgent plist parsing, Karabiner JSON, and rendered installer Zsh syntax;
- Linux and macOS service lifecycle behavior through mocks on either platform;
- desktop CLI integration through deterministic commands in `mock-bin`;
- the caller-provided fallback contract of the chezmoi-only `hyprctl-safe` helper;
- Bash syntax for non-template shell scripts;
- Lua syntax when `luac` is available.

Required dependencies are `chezmoi`, Bash and Python 3; macOS checks also use
Zsh. `luac` is optional. GUI authorization, application behavior and real service
startup still require manual verification on the corresponding platform. Add behavioral
assertions to `test.sh` whenever a profile gains or loses an important file.
