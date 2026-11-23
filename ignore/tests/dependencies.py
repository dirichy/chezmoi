"""Repository-relative glob dependencies for each default test group.

Globs use fnmatch: * also matches /. Keep indirect include/hash inputs here.
Platform fixtures are conservative: both OS fixtures invalidate shared tests.
Real enrollment and install-lan remain explicit integration tests, outside this runner.
"""

CONFIG = [".chezmoi.toml.tmpl", ".chezmoiignore"]
DOWNLOAD_TEMPLATES = [".chezmoitemplates/githubDownloadURL*",
                      ".chezmoitemplates/preferChezmoiDownloads", ".chezmoitemplates/zsh-plugin-repos"]
INSTALL_TEMPLATES = [".chezmoitemplates/install-*", ".chezmoitemplates/githubDownloadURL"]
FIXTURES = ["ignore/tests/fixtures/*.toml"]
RIME = ["dot_local/share/fcitx5/rime/*", "ignore/tests/fixtures/rime-*/*",
        "ignore/bin/rime-tiger-dictionary", "ignore/bin/rime-merge-emoji"]
SOURCES = ["dot_*", "private_*", "symlink_*", "executable_*", "readonly_*", "exact_*",
           "create_*", "modify_*", "encrypted_*", "literal_*", "scripts/*", "run_*", ".chezmoiremove"]
SEEDS = ["ignore/tests/fixtures/rime-ice/*.yaml", "ignore/tests/fixtures/rime-tiger/*.yaml"]

DEPENDENCIES = {
    "runner": ["ignore/tests/test-runner.py"],
    "installers": CONFIG + FIXTURES + INSTALL_TEMPLATES + ["ignore/bin/dotfiles-packages", "ignore/tests/test-installers.py"],
    "install-macos": CONFIG + DOWNLOAD_TEMPLATES + [".chezmoitemplates/isIPv4CIDR",
        ".github/workflows/install-macos.yml", "ignore/tests/install-macos/*", "ignore/tests/test-install-macos.py",
        "ignore/tests/fixtures/rime-*/*", "ignore/tests/fixtures/install-macos/*", "private_Library/*", "dot_config/private_karabiner/*", "scripts/lua/*"],
    "install-entry": ["install.sh", "ignore/bin/dotfiles-packages", "ignore/tests/test-install-entry.py"],
    "maintenance": CONFIG + FIXTURES + DOWNLOAD_TEMPLATES + ["run_*", "dot_config/zsh/plugin-manager.zsh",
        "dot_config/nvim/lua/*", "dot_config/yazi/package.toml", "dot_config/mihomo/config.yaml.tmpl",
        "ignore/tests/test-maintenance.py"],
    "downloads": CONFIG + FIXTURES + DOWNLOAD_TEMPLATES + [".chezmoitemplates/isIPv4CIDR",
        ".chezmoiexternal.toml", "ignore/bin/check-downloads",
        "dot_config/mihomo/config.yaml.tmpl", "dot_config/systemd/user/dotfiles-download-check.*",
        "ignore/tests/test-downloads.py"],
    "rime-tiger": CONFIG + FIXTURES + RIME + DOWNLOAD_TEMPLATES + [".chezmoiexternal.toml", "ignore/tests/test-rime-tiger.py"],
    "rime-deploy": ["ignore/bin/rime-deploy", "ignore/tests/test-rime-deploy.py"],
    "rime-native": CONFIG + FIXTURES + RIME + ["ignore/tests/test-rime-radical.py"],
    "rime-android": CONFIG + FIXTURES + RIME + ["ignore/tests/test-rime-radical.py"],
    "rime-lua": ["dot_local/share/fcitx5/rime/*", "ignore/tests/test-rime-tools.lua", "ignore/tests/test-rime-simp.lua"],
    "rime-config": CONFIG + FIXTURES + ["dot_config/fcitx5/conf/private_rime.conf.tmpl"],
    "cidr": CONFIG + FIXTURES + [".chezmoitemplates/isIPv4CIDR"],
    "hypr-helper": ["ignore/bin/hyprctl-safe"],
    # File names (not contents) also affect the managed set; runner handles this separately.
    "profiles": CONFIG + FIXTURES + SEEDS,
    "proxy": CONFIG + FIXTURES + SEEDS + [".chezmoitemplates/githubDownloadURL",
        "dot_config/zsh/dot_zshenv.tmpl",
        "dot_config/mihomo/config.yaml.tmpl"],
    "render": CONFIG + FIXTURES + SOURCES + SEEDS + [".chezmoitemplates/*", "ignore/bin/*", "ignore/tests/mock-bin/*"],
    "services": ["ignore/bin/dotfiles-services", "ignore/bin/systemctl-macos", "ignore/tests/mock-bin/*"],
    "config-share": ["dot_local/libexec/executable_config-share-server", "ignore/tests/test-config-share-server.py"],
    "syntax": ["*.sh", "*.bash", "scripts/lua/*.lua", "dot_hammerspoon/*.lua",
        "dot_config/yazi/*.lua"],
    "later": ["dot_local/bin/executable_later", "ignore/tests/test-later.sh", "ignore/tests/mock-bin/systemctl",
        "ignore/tests/mock-bin/systemd-run"],
}
