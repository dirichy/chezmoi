# Dotfiles

这是我的跨平台 chezmoi 配置仓库，主要覆盖 Arch Linux/Hyprland 和 macOS 两套桌面环境，同时管理 shell、编辑器、终端、文件管理器、输入法、代理、远程访问和若干本地脚本。

仓库根目录是 chezmoi source directory，目标路径由 chezmoi 规则映射：

- `dot_config/foo` -> `~/.config/foo`
- `dot_local/bin/executable_x` -> `~/.local/bin/x`
- `private_Library/private_LaunchAgents` -> `~/Library/LaunchAgents`
- `*.tmpl` -> 通过 chezmoi template 渲染后写入目标路径

## Quick Start

首次安装：

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <repo>
```

已有 chezmoi 后：

```bash
chezmoi init <repo>
chezmoi diff
chezmoi apply
```

日常更新：

```bash
chezmoi cd
git pull
chezmoi diff
chezmoi apply
```

把本机修改纳入仓库：

```bash
chezmoi add ~/.config/foo
chezmoi cd
git diff
git add .
git commit
```

## Template Data

首次运行会由 `.chezmoi.toml.tmpl` 询问这些数据：

- `name`: Git 用户名
- `email`: Git 邮箱
- `inputMethod`: 输入法方案，例如 `tiger` 或 `flypy`
- `screenResolution`: 屏幕宽高，用于 Xresources DPI
- `monitorScale`: 显示缩放
- `fduConnect`: 是否启用复旦 VPN 配置
- `phoneBluetoothMac`: 用于 Hyprland idle 判断是否在家

配置会写入 chezmoi 的本地状态，不应该直接提交真实 secret。

## Secrets

secret 通过 `gopass-safe` 读取：

```toml
[secret]
command = "{{ joinPath .chezmoi.sourceDir "tools" "gopass-safe" }}"
```

查找规则是 `chezmoi/<key>`，找不到时使用模板里的默认值。当前使用到的 secret 包括：

- `serverIP`
- `ikuuu`
- `wyyctc`
- `fduID`
- `fduSecret`

## Dependencies

依赖安装脚本：

- Arch Linux: `run_onchange_after_install-pacakges-archlinux.sh.tmpl`
- macOS: `run_onchange_after_install-pacakges-macos.sh.tmpl`

Arch 主要依赖：

- 桌面: `hyprland`, `hyprpaper`, `hypridle`, `waybar`, `wofi`, `kitty`
- 音频/蓝牙: `pipewire-audio`, `pipewire-pulse`, `wireplumber`, `bluez`, `blueman`, `pavucontrol`
- 网络/代理: `networkmanager`, `tailscale`, `mihomo`, `fdu-connect`
- CLI/TUI: `neovim`, `tmux`, `yazi`, `lazygit`, `bottom`, `bashmount`, `nvtop`
- 工具: `fzf`, `zoxide`, `ripgrep`, `fd`, `jq`, `gh`, `gopass`, `lsd`, `imagemagick`
- NVIDIA/显示: `nvidia-open`, `ddcutil`, `brightnessctl`
- 输入法: `fcitx5`, `fcitx5-rime`

macOS 主要依赖通过 Homebrew 安装：

- CLI: `git`, `neovim`, `tmux`, `yazi`, `fzf`, `zoxide`, `mihomo`, `jq`, `gh`
- GUI: Hammerspoon, Karabiner-Elements, Kitty, Sioyek, Tailscale, EasyDict
- 字体: JetBrains Mono Nerd Font

macOS 安装脚本会先检测是否能访问 Google；不能访问时使用清华 Homebrew 镜像。

## Repository Map

```text
.chezmoi.toml.tmpl                 chezmoi 本机数据和 secret 配置
.chezmoiignore                     按系统忽略不适用的配置
.chezmoiexternal.toml              外部资源，如 Rime 大文件、Hammerspoon Spoon、gopass store
.chezmoitemplates/                 被其他模板 include 的片段
dot_config/hypr/                   Arch Linux Hyprland 桌面
dot_config/waybar/                 Waybar 状态栏
dot_config/wofi/                   Wofi 启动器
dot_config/systemd/user/           Linux user services
dot_config/nvim/                   Neovim 配置
dot_config/tmux/                   Tmux 配置和 helper 脚本
dot_config/zsh/                    Zsh/antidote 配置
dot_config/yazi/                   Yazi 文件管理器
dot_config/mihomo/                 Mihomo/Clash Meta 代理配置
dot_config/fcitx5/                 Fcitx5/Rime 配置
dot_config/aerospace/              macOS AeroSpace 配置
dot_config/yabai/                  macOS Yabai 配置
dot_config/private_karabiner/      macOS Karabiner 配置模板
dot_hammerspoon/                   macOS Hammerspoon 自动化
dot_local/bin/                     自定义命令
private_Library/LaunchAgents       macOS launchd services
```

## Linux Desktop

Linux 桌面以 Hyprland 为主，入口是：

- `~/.config/hypr/hyprland.lua`
- `~/.config/hypr/shortcuts.lua`
- `~/scripts/lua/wmux.lua`

主要功能：

- Lua 驱动的 Hyprland 配置和 keymap
- 原生 Hyprland Lua 配置，配合 wmux 统一跨平台键位
- Hyprpaper/Waybar/Hypridle/Sunshine/udisken 随 Hyprland 启动或重启
- NVIDIA/Wayland/Electron/Fcitx 相关环境变量
- 针对 QQ、微信、Sioyek、mpv、pavucontrol 等窗口规则
- `keyd.lua` 支持按当前窗口动态调整 keyd 绑定

相关服务：

- `mihomo_config_server.service`: 在 `~/.config/mihomo` 起 HTTP server
- `fdu-connect.service`: 复旦 VPN
- `ssh-tunnel@.service`: 反向 SSH tunnel

反向 SSH tunnel 示例：

```bash
systemctl --user enable --now ssh-tunnel@520.service
```

## Waybar

Waybar 配置在 `dot_config/waybar`。

特性：

- Catppuccin Frappe 固定配色
- 模块按 `modules/`, `modules/custom/`, `modules/hyprland/` 拆分
- chezmoi 动态检测电池：台式机隐藏 battery，笔记本显示 battery
- CPU 常驻，GPU/memory/temperature 放入系统监控抽屉
- Disk 常驻显示最满分区，tooltip 显示全部本地块设备挂载点
- Disk 单击打开 `duf`，右键打开 `bashmount`
- Tailscale 状态模块，点击优先打开 `tsui`/`tailtui`，否则 fallback 到 `tailscale status`
- Backlight 支持 `ddcutil`、`brightnessctl` 自动 fallback
- Clock 折叠显示日期，点击打开 `calcurse`
- Arch logo 打开 power menu

脚本约定：

- `foo.sh status`: 给 Waybar 输出状态 JSON，必须快速返回
- `foo.sh usage/menu`: 点击后打开 TUI 或交互菜单，可以阻塞
- `fzf-theme.sh`: 给 fzf 菜单导出统一配色

## macOS Desktop

macOS 主要由三部分组成：

- Hammerspoon: `dot_hammerspoon/`
- Karabiner: `dot_config/private_karabiner/`
- AeroSpace/Yabai: `dot_config/aerospace/`, `dot_config/yabai/`

Hammerspoon 功能：

- 启动后执行桌面初始化
- 输入法/Rime 辅助
- Wi-Fi 相关静音逻辑
- Cmd-Q 防误触
- 通过 Spoon 安装 `Caffeine` 和 `EmmyLua`

Karabiner 功能：

- `fn` 切换 Fcitx5 输入法
- Moonlight 场景下交换 Command/Option，统一远程控制体验
- Joy-Con 控制 Sioyek
- 部分规则由 `lua_keymapper` 生成

AeroSpace/Yabai 功能：

- Vim 风格窗口导航
- 1-9 工作区
- 浮动窗口规则
- mpv/Moonlight 全屏规则

## Shell

Zsh 配置在 `dot_config/zsh`：

- Antidote 管理 zsh 插件
- Powerlevel10k prompt
- fzf-tab、zsh-autosuggestions、history substring search、syntax highlighting
- `zoxide` 接管 `cd`
- 常用别名和一字母命令
- `s` 函数使用 autossh 进入远端 tmux
- `t` 函数选择/创建 tmux session
- `v` 函数封装 Neovim 打开文件/目录/历史路径

Tmux 配置在 `dot_config/tmux`：

- `C-f` 临时进入 prefix table，状态栏短暂显示
- Vim 风格 pane 导航
- fzf session switcher
- OSC52/系统剪贴板集成
- btm popup
- activity notification

## Editor

Neovim 配置在 `dot_config/nvim`：

- `lazy.nvim` 自动 bootstrap
- Lua 模块化配置：options/keymaps/autocmds/plugins
- LSP、completion、treesitter、debug、UI、LaTeX、Neorg、LeetCode、Firenvim 等插件分组
- 支持 LuaRocks 路径
- `PROF=1 nvim` 可启用 snacks profiler

常用命令：

```bash
nvim
PROF=1 nvim
```

## File Manager

Yazi 配置在 `dot_config/yazi`：

- Dracula/Catppuccin flavor
- full-border、simple-status、starship
- GVFS mount、recycle-bin、duckdb preview、docx preview
- Vim 风格导航
- 大量中文 desc 的 keymap，适合用内置 help 查询

首次进入 Yazi 时，`init.lua` 会在 require 插件失败后尝试执行：

```bash
ya pkg install
```

## Input Method

Linux 使用 Fcitx5 + Rime：

- 配置目录：`dot_config/fcitx5`
- 大文件通过 `.chezmoiexternal.toml` 下载到 `~/.local/share/fcitx5/rime`
- `.chezmoiignore` 会按系统忽略不适用的前端配置

重新部署：

```bash
fcitx5-remote -r
```

macOS 使用 Fcitx5.app 时，`~/.local/bin/fcitx5-remote` 是到 app 内二进制的 symlink。

## Proxy And Network

Mihomo 配置在 `dot_config/mihomo/config.yaml.tmpl`：

- 订阅 URL 通过 gopass secret 注入
- Fudan、广告、AI、Apple、Bilibili 等规则 provider
- Linux 通过 user service 或手动启动
- macOS 通过 LaunchAgent 启动

FDU Connect：

- 配置：`dot_config/fdu-connect/config.toml.tmpl`
- Linux service：`dot_config/systemd/user/fdu-connect.service.tmpl`
- macOS LaunchAgent：`private_Library/private_LaunchAgents/fdu-connect.plist.tmpl`
- 由 `.chezmoi.toml.tmpl` 的 `fduConnect` 开关控制

## SSH

SSH 配置在 `dot_ssh/config.tmpl`：

- 全局启用 ControlMaster 连接复用
- `server` 从 secret `serverIP` 读取
- `dell`, `yoga`, `wyy`, `byl` 支持 LAN/Tailscale/ProxyJump 多路径
- 路由器 MAC 检测通过 `.chezmoitemplates/linuxRouterIP` 和 `darwinRouterIP`

注意：systemd 的 `ssh-tunnel@.service` 显式设置 `ControlMaster=no`，避免共享连接导致 tunnel 服务退出或状态异常。

## Local Commands

`dot_local/bin` 提供本地命令：

- `hyprmonitor`: 读取当前 Hyprland monitor 字段
- `lua_keymapper`: 生成 Karabiner/keyd/WM 相关 keymap
- `qq`, `tencentqq`: Linux QQ/Hyprland wrapper
- `sioyek`: 强制 Sioyek 使用 xcb
- `sunshine_pre`: Sunshine 启动前显示器布局处理
- `toggle_proxy`: macOS 网络代理开关

## Apply And Reload

常见应用方式：

```bash
chezmoi apply
```

Linux reload：

```bash
systemctl --user restart waybar
hyprctl reload
fcitx5-remote -r
```

macOS reload：

```bash
hs -c 'hs.reload()'
launchctl unload ~/Library/LaunchAgents/mihomo.plist
launchctl load ~/Library/LaunchAgents/mihomo.plist
```

Tmux reload：

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

## Maintenance Notes

- 先在目标文件里修改，再用 `chezmoi add` 收回仓库。
- 涉及 secret 的值不要直接写入仓库，优先放到 gopass。
- 修改模板后先跑：

```bash
chezmoi diff
chezmoi apply --dry-run
```

- 修改 Waybar 后可以验证：

```bash
chezmoi execute-template < dot_config/waybar/config.jsonc.tmpl
```

- 修改 shell 脚本后至少跑：

```bash
bash -n path/to/script.sh
```

- `.chezmoiignore` 负责按 OS 隐藏不适用配置；新增平台相关文件时要同步检查 ignore 规则。

## Known Assumptions

- 主要 Linux 发行版是 Arch Linux，包管理使用 `paru`。
- Linux 桌面默认 Hyprland + systemd user services。
- macOS 默认 Apple Silicon Homebrew 路径 `/opt/homebrew`。
- 代理端口约定为 `127.0.0.1:7890`。
- 部分个人设备名和主机名写在 SSH/Hyprland 配置中。
