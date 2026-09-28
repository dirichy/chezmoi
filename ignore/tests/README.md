# Dotfiles tests

Run the regression suite from anywhere in the repository:

```bash
./ignore/tests/test.sh
```

The suite uses isolated temporary destination, cache, and state paths. It never
applies files to the real home directory. It checks:

- the managed file set for `desktop`, `headless`, and `skip` Linux profiles;
- rendering of every managed file and template in those profiles;
- desktop CLI integration through deterministic commands in `mock-bin`;
- the caller-provided fallback contract of the chezmoi-only `hyprctl-safe` helper;
- Bash syntax for non-template shell scripts;
- Lua syntax when `luac` is available.

The only required dependency is `chezmoi`. `luac` is optional. Add behavioral
assertions to `test.sh` whenever a profile gains or loses an important file.
