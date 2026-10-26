# Dotfiles

这是我的跨平台 chezmoi 配置仓库，主要覆盖 Arch Linux/Hyprland 和 macOS 两套桌面环境，同时管理 shell、编辑器、终端、文件管理器、输入法、代理、远程访问和若干本地脚本。

仓库根目录是 chezmoi source directory，目标路径由 chezmoi 规则映射：

- `dot_config/foo` -> `~/.config/foo`
- `dot_local/bin/executable_x` -> `~/.local/bin/x`
- `private_Library/private_LaunchAgents` -> `~/Library/LaunchAgents`
- `*.tmpl` -> 通过 chezmoi template 渲染后写入目标路径

## Quick Start

1. 备份已有配置，安装 Git、curl 和 chezmoi。Arch 先安装 paru；macOS 先运行 `xcode-select --install` 并完成弹窗安装。
2. 初始化仓库（将 `<repo>` 替换为本仓库 Git 地址），按提示选择 profile、填写本机数据；不用代理则将代理地址留空，不用 VPN / 配置共享则关闭。

   ```bash
   # 未安装 chezmoi 时先执行；安装后若不在 PATH 中，使用 ./bin/chezmoi
   sh -c "$(curl -fsLS get.chezmoi.io)"
   chezmoi init <repo>
   ```

3. 按需配置 gopass store / 解密私钥，写入 [Secrets](#secrets) 中要使用的条目；检查并修改 source 中自己的 SSH 主机、代理节点、应用路径及硬件快捷键。
4. 检查并应用配置，输入 sudo 密码，回答服务启停确认；按安装日志补装失败的包。

   ```bash
   chezmoi diff
   chezmoi apply --dry-run
   chezmoi apply
   ```

5. 按使用的功能完成下列手动设置。

| 功能 / 平台 | 操作 |
| --- | --- |
| Zsh / 终端 | 需要时运行 `chsh -s "$(command -v zsh)"`，重新登录 |
| Zen 快捷键 | 在 `about:support` 打开配置文件夹，退出 Zen，备份并用 `ignore/zen/zen-keyboard-shortcuts.json` 替换同名文件，重新启动 |
| Surfingkeys | 安装扩展；在扩展设置中启用 Advanced mode，将 Load settings from 设为 `http://127.0.0.1:18080/surfingkeys/config.js`（需开启 Surfingkeys 配置共享） |
| Tailscale / Sunshine | 登录 Tailscale；设置 Sunshine 账号并配对 Moonlight |
| Linux 桌面 | 配置 greetd 登录入口，启动 Hyprland；将检查后的 `~/.cache/rsync_to_root/etc/keyd/` 配置安装到 `/etc/keyd/`，配置动态绑定权限并重启 keyd |
| 壁纸 | 将图片放入 `~/Pictures/wallpaper` |
| Linux 输入法 | 在 Fcitx5 中启用 Rime / 所选方案并重新部署，启动 Fcitx5 |
| Linux 代理 | 自行启动 Mihomo 或配置服务 |
| Linux 硬件功能 | 使用手机 idle 探测时配置 `l2ping` 权限，否则调整 `hypridle.conf`；按需配置 DDC / 背光设备权限、GRUB 启动项及 sudo 权限 |
| macOS 桌面 | 启动 Hammerspoon、Karabiner，授予辅助功能 / 输入监控等所需权限，按需开启登录启动；安装 Alfred 5 或修改 Cmd-Space 绑定 |
| macOS 输入法 | 安装 `/Library/Input Methods/Fcitx5.app`，在系统设置中启用，准备 Rime 词库并部署 |
| macOS 窗口管理 | 安装、授权并启动 Yabai 或 AeroSpace；使用当前 wmux 时选择 Yabai，并配置 scripting addition / sudo 权限 |
| macOS 系统代理 | 在网络设置中设置代理，或使用 `toggle_proxy` |
| 局域网配置共享 | 设置允许客户端 CIDR，开放 TCP 18080，在客户端填写订阅 / 脚本 URL |
| SSH 隧道 / 通知 | 准备 SSH 密钥和远端认证；按下文启用隧道 / 配置通知服务 |

## Setup Notes

### 初始化选项

| 提示 | 需要填写 / 选择的内容 |
| --- | --- |
| `machine profile` | 按下表选择；默认 `desktop` |
| `administrator on this machine` | 是否具备管理员权限；无权限选 `false`，缺失依赖需要自行准备 |
| `package install command` | Linux 确认包管理命令；留空则只提示手动安装缺失包。macOS 安装脚本固定使用 Homebrew |
| `install modules` | 仅 `custom` 询问，填写逗号分隔模块；Linux 支持 `core,shell,system,font-and-im,desktop,proxy,apps,dev,latex,nvidia,extra`，macOS 支持 `core,shell,font-and-im,proxy,desktop,dev,extra` |
| `use proxy for shell and desktop apps` | 是否让 shell、Hyprland 和系统代理使用代理地址，默认关闭；与 Mihomo 的安装和服务启用相互独立 |
| `proxy address host:port` | 启用代理使用开关时填写代理地址，默认 `127.0.0.1:7890` |
| `input method profile` | `tiger` 或 `flypy` |
| `enable fdu-connect` | 需要复旦 VPN 才选 `true`，还需准备账号 secret |
| `Waybar hostname symbol` | 状态栏显示的主机标识，默认主机名 |
| `config sharing mode` | `none`（默认）、`all` 或 `custom`；`custom` 再选 `mihomo,surfingkeys` 中要共享的项目 |
| `allowed client CIDR` | 启用共享时填写；默认 `127.0.0.1/32`，局域网共享需填写实际网段，并自行配置防火墙允许 TCP 18080 |
| `name` / `email` | 自己的 Git 用户名和邮箱；`name=dirichy` 会额外下载作者的 gopass store，其他用户应填写自己的名字 |
| `Your mobile BluetoothMac...` | Linux idle 检测使用的手机蓝牙 MAC；不用此功能可留空，并按下文调整 idle 配置 |

| Profile | 用途 |
| --- | --- |
| `headless` | 命令行 / 远程机器 |
| `minimal` | 命令行 + 输入法相关配置 / 字体 |
| `desktop` | 桌面、输入法、代理和常用应用 |
| `devbox` | 命令行开发环境 |
| `full` | 开发 + 桌面；Linux 额外安装 LaTeX 和检测到的 NVIDIA 支持 |
| `everything` | `full` + 个人额外应用 / 游戏 |
| `custom` | 自选安装模块；配置是否生成还取决于模板中的 features/apps 推导 |
| `skip` | 跳过依赖安装并关闭多数可选配置；仍会管理部分公共文件，不等于不写入任何配置 |

### 安装与配置说明

- 初始化答案保存在本机 chezmoi 配置中，可用 `chezmoi edit-config` 检查 `[data]`。直接修改 profile 不会重新推导已有 features/apps；模板默认值不会覆盖 `prompt*Once` 保存的答案。`INSTALL_PROFILE` / `INSTALL_MODULES` 只改变依赖安装，不改变配置文件集合。
- Linux 包名主要面向 Arch，其他发行版需要核对包名。脚本不会安装 paru；安装失败可能只输出警告。macOS 安装脚本固定使用 Homebrew，缺少时自动安装，需具备相应权限。
- 初始化的代理地址不会提前启动代理；启用后 shell 会使用该地址。缺失 secret 会使用默认值；下载加密 store 后仍需解密私钥。macOS 安装清单不含 gopass。在 apply 后补齐 secret 时需再次 apply。
- 个人 SSH 地址 / 用户名 / 路由器匹配在 `dot_ssh/config.tmpl`，代理节点 / DNS / 路由在 `dot_config/mihomo/config.yaml.tmpl`。Linux 的 GRUB 项、DDC 输入值、OpenRGB profile，以及 macOS 的 Wi-Fi 名称和应用路径需按本机调整。
- Zsh 路径需在 `/etc/shells` 中才能用 chsh。首次启动 Zsh、Neovim、Yazi 会自动下载插件；Yazi 安装失败时运行 `ya pkg install`，需要自定义提示符时运行 `p10k configure`。
- Linux 脚本安装 / 启用 greetd，但不写 `/etc/greetd/config.toml`。Hyprland 配置使用原生 Lua，需使用支持此配置格式的版本。keyd 配置只生成在用户缓存目录，不会自动安装到 `/etc/keyd/`。
- Linux 手机 idle 检测调用 `sudo l2ping`，需无需交互即可运行；壁纸脚本读取 `~/Pictures/wallpaper`，还需确认 hyprpaper 使用的壁纸存在。远程机器需要退出登录后仍运行 user service 时，另行配置 linger。
- macOS 安装清单不含 Fcitx5.app、Yabai、AeroSpace 和 Alfred。`fcitx5-remote` 链接依赖上述 app 安装位置；Rime 大词库 external 目前只为 Linux Fcitx5 下载。当前 wmux 的 macOS 窗口操作使用 Yabai，`yabairc` 会调用 `sudo yabai --load-sa`。
- 服务确认被拒绝或在非交互环境中跳过后，可在新 Zsh 中运行 `chezmoi x services --check` 检查、`chezmoi x services` 补做；其他 shell 直接运行 source 中的 `ignore/bin/dotfiles-services`。Linux 管理 config-share、FDU Connect、later；macOS 管理 config-share、FDU Connect、Mihomo。
- 服务协调脚本在 `chezmoi diff` 时渲染为空，避免每次显示产生噪声；`chezmoi apply` 时仍会正常检查并按需确认服务启停。
- 配置共享可能包含订阅凭据，CIDR 应只允许自己的客户端访问。系统代理与 shell 代理变量需要分别配置。

### 日常更新

```bash
chezmoi cd
git pull
chezmoi diff
chezmoi apply
```

仓库提供 `.githooks/pre-commit`：提交删除或重命名的 chezmoi source 文件时，
它会把不再管理的旧目标路径自动加入 `.chezmoiremove`，使其他机器下次
`chezmoi apply` 时删除对应文件；若目标文件在本机被修改，chezmoi 仍会询问是否覆盖。
新机器第一次 `chezmoi apply` 时会通过 `run_once_before_configure-chezmoi-git-hooks.sh.tmpl`
自动完成配置。如果 clone 后尚未 apply，也可以手动启用：

```bash
git config core.hooksPath .githooks
```

hook 会自动暂存 `.chezmoiremove`。纯属性重命名（例如给 source 文件增加
`executable_` 前缀但目标路径不变）不会误加删除记录。

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

- `profile`: 本机 profile，控制依赖安装和配置启用，默认 `desktop`
- `name`: Git 用户名
- `email`: Git 邮箱
- `inputMethod`: 输入法方案，目前可选 `tiger` 或 `flypy`
- `features.proxy`: 是否让 shell、Hyprland 和系统代理使用代理地址，默认关闭；不控制 Mihomo 的安装、配置或服务
- `proxy.address`: 启用代理使用开关时采用的网络代理地址，默认 `127.0.0.1:7890`；关闭时为空且不会询问地址
- `inputMethod`: 输入法方案，例如 `tiger` 或 `flypy`
- `fduConnect`: 是否启用复旦 VPN 配置
- `phoneBluetoothMac`: 用于 Hyprland idle 判断是否在家
- `configShare.mode`: Linux/macOS 配置共享范围，可选 `none`、`all` 或 `custom`
- `configShare.items`: `custom` 模式下发布的配置名，当前支持 `mihomo`、`surfingkeys`
- `configShare.allowedCIDR`: 配置共享服务允许访问的客户端网段

完整问题和 profile 说明见 Setup Notes。配置会写入本机 chezmoi 配置文件，不应该直接提交真实 secret。

Profile 会展开成几组本机数据：

- `install.profile`: 安装脚本默认使用的 profile，可被 `INSTALL_PROFILE` 临时覆盖
- `install.modules`: `custom` profile 下的模块列表，可被 `INSTALL_MODULES` 临时覆盖
- `install.command`: Linux 包安装命令，脚本按空白拆成命令参数，并逐个把包名追加到命令后执行；可被 `INSTALL_COMMAND` 临时覆盖
- `install.admin`: 是否是这台机器上的管理员，可被 `INSTALL_ADMIN` 临时覆盖；非管理员会跳过系统模块、驱动模块、system 级 service 和所有 sudo 操作
- `features.*`: 是否启用某类配置，例如 `inputMethod`, `linuxDesktop`, `macDesktop`, `proxy`
- `apps.<name>.enabled`: 是否落下某个软件的配置
- `apps.<name>.profile`: 同一软件在不同机器 profile 下的配置变体入口

当前内置 profile：

- `headless`: CLI 和系统服务，不启用桌面/输入法配置
- `minimal`: CLI、系统服务和输入法
- `desktop`: 桌面日用配置
- `devbox`: 开发工具配置
- `full`: devbox + 桌面 + 硬件/串流相关配置
- `everything`: full + 个人额外应用
- `custom`: 手写安装模块列表
- `skip`: 不安装软件，并尽量不落下可选配置组

## Secrets

secret 通过 `gopass-safe` 读取：

```toml
[secret]
command = "{{ joinPath .chezmoi.sourceDir "ignore" "bin" "gopass-safe" }}"
```

查找规则是 `chezmoi/<key>`，找不到时使用模板里的默认值。当前使用到的 secret 包括：

- `serverIP`
- `ikuuu`
- `wyyctc`
- `fduID`
- `fduSecret`
- `maimaiSSpassword`: 个人 Shadowsocks 节点密码
- `tmuxNotifyToken`: tmux 通知服务的认证 token（还需自行部署通知服务）

## Dependencies

依赖安装脚本：

- Arch Linux: `run_onchange_after_install-packages-linux.sh.tmpl`
- macOS: `run_onchange_after_install-packages-macos.sh.tmpl`

Linux 安装脚本默认按当前发行版给出安装命令，例如 Arch/Manjaro 使用 `paru -S --needed --noconfirm --skipreview`，Debian/Ubuntu 使用 `sudo apt-get install -y`，Fedora 使用 `sudo dnf install -y`。其它发行版可以在 init 时填写 `install.command`，例如 `sudo apk add` 或 `sudo xbps-install -Sy`。安装会逐包执行，单个包失败只会 warning，不会中断整个 module。

包名仍以当前配置使用的名字为主；非 Arch 系统遇到包名不匹配时，安装脚本会 warning 并继续，用户再按提示手动安装。

Linux 模块支持 `package:command` 形式声明软检测命令。脚本会先检查 `command` 是否存在；存在就认为这项能力已经可用，不再尝试安装 `package`。这适合共享机器、系统级预装软件，或软件来自不同包管理器的场景。

非管理员机器上，Linux 安装脚本会跳过 `system` 和 `nvidia` 模块，也不会启用 system 级 service 或运行任何 `sudo` 命令；用户级配置、用户级 service 和普通应用安装仍按 profile 与 `package:command` 检测执行。

`.chezmoiignore` 和 `.chezmoiexternal.toml` 都会读取 `features.*` / `apps.*`；未启用的配置组不会落文件，对应的大文件或外部资源也不会下载。

`.Xresources` 不再由 chezmoi 管理。Hyprland 的 monitor setup 会先 merge 已有文件，再按当前显示器 scale 写入 `Xft.dpi = scale * 96`，然后重新 `xrdb -merge ~/.Xresources`；这样下次开机也能尽早使用上一次生成的 DPI。

Linux 主要依赖：

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
- `~/scripts/lua/wmux.lua`

主要功能：

- Lua 驱动的 Hyprland 配置和 keymap
- 原生 Hyprland Lua 配置，配合 wmux 统一跨平台键位
- Hyprpaper/Waybar/Hypridle/Sunshine/udisken 随 Hyprland 启动或重启
- NVIDIA/Wayland/Electron/Fcitx 相关环境变量
- 针对 QQ、微信、Sioyek、mpv、pavucontrol 等窗口规则
- `keyd.lua` 支持按当前窗口动态调整 keyd 绑定
- 双系统配置nopasswd后可以一键切系统。需要免密sudo执行grub-reboot和reboot。

相关服务：

- `config-share.service`: 在 `~/.local/share/config-share` 提供只读 HTTP 配置共享；初始化时可选择全部、关闭或自定义发布 `mihomo`、`surfingkeys`，并限制允许访问的客户端网段。
- `fdu-connect.service`: 复旦 VPN，一个账号只能登录在一台设备，不然有bug。可以一个设备然后局域网共享。
- `ssh-tunnel@.service`: 反向 SSH tunnel，用于在外网中转访问内网，需要有服务器。

配置共享固定监听 TCP `18080`。`all` 会发布当前支持的全部配置；`custom` 接受逗号分隔的配置名；两者都会询问允许访问的 CIDR。应用配置后手动启用服务：

```bash
chezmoi x services
```

对应 URL 为 `http://<主机地址>:18080/mihomo/config.yaml` 和 `http://<主机地址>:18080/surfingkeys/config.js`。Mihomo 入口只是指向实际配置的单文件链接，不会公开整个 `~/.config/mihomo` 目录。

每次 `chezmoi apply` 后会检查仓库管理的用户服务。Linux 使用 `systemctl --user` 管理 Config Share、FDU Connect 和 Later；macOS 使用原生 `launchctl` 管理 Config Share、FDU Connect 和 Mihomo。期望启用但尚未启用的服务会询问是否启用并启动；配置中已经关闭但仍处于 enabled 状态的服务会询问是否停止并禁用。非交互 apply 只报告差异。也可以手动运行 `chezmoi x services --check` 做只读检查，或使用 `chezmoi x services --yes` 接受全部调整。仓库内部 helper 位于 `ignore/bin`，由 zsh 中的 `chezmoi x` wrapper 调用，不会部署到 `~/.local/bin`。Linux 上需要实例参数的 `ssh-tunnel@.service` 不参与自动协调。

macOS 的交互式 zsh 还提供一个 `systemctl` 兼容 wrapper，Linux 则原样调用系统的 `systemctl`。它支持常用的 `status`、`show`、`cat`、`is-active`、`is-enabled`、`start`、`stop`、`restart`、`enable/disable --now`、`list-units` 和 `list-unit-files`；底层使用当前用户的 `gui/$UID` launchd domain。例如：

```bash
systemctl --user status mihomo
systemctl --user restart config-share
systemctl --user disable --now fdu-connect
```

`daemon-reload` 在 macOS 上是带说明的 no-op。timer、socket、journal 等 systemd 专属功能不会伪装成 launchd 功能。

反向 SSH tunnel 示例：

```bash
systemctl --user enable --now ssh-tunnel@520.service
```

## Waybar

Waybar 配置在 `dot_config/waybar`。

特性：

- Catppuccin 主题配色
- 模块按 `modules/`, `modules/custom/`, `modules/hyprland/` 拆分
- chezmoi 动态检测电池：台式机隐藏 battery，笔记本显示 battery
- CPU 常驻，GPU/memory/temperature 放入系统监控抽屉
- Disk 常驻显示最满分区，tooltip 显示全部本地块设备挂载点
- Disk 单击打开 `duf`，右键打开 `bashmount`
- Tailscale 状态模块，点击优先打开 `tsui`/`tailtui`，否则 fallback 到 `tailscale status`
- Backlight 支持 `ddcutil`、`brightnessctl` 自动 fallback
- Clock 两行显示日期和时间，点击打开 `calcurse`
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
- `Caffeine` 模块防止电脑休眠。

Karabiner 功能：

- `fn` 切换 Fcitx5 输入法
- Moonlight 场景下交换 Command/Option，统一远程控制体验
- Joy-Con 控制 Sioyek
- 部分规则由 `wmux` 生成，与linux有一样的平铺桌面keybind。

Yabai 功能：

- 由`wmux`生成的与`hyprland`一样的keybind。
- 1-9 工作区
- 浮动窗口规则
- mpv/Moonlight 全屏规则

## Browser

`ignore/zen/` 不部署到 home，仓库没有自动导入浏览器配置的脚本。两项配置都需要手动设置。

### Zen 快捷键

1. 在 Zen 打开 `about:support`，找到“配置文件夹 / Profile Folder”，打开当前 profile 的目录。
2. 完全退出 Zen，备份目录中已有的 `zen-keyboard-shortcuts.json`。
3. 将仓库的 `ignore/zen/zen-keyboard-shortcuts.json` 复制到该目录，替换同名文件。
4. 重新启动 Zen，在“设置 → 键盘快捷键”中检查并调整绑定。

不要复制整个 profile。仓库文件中包含扩展快捷键，对应扩展也需自行安装；跨平台迁移后检查 Ctrl / Command 等修饰键。Zen 快捷键设置入口见[官方文档](https://docs.zen-browser.app/user-manual/shortcuts)。

### Surfingkeys

安装 Surfingkeys 扩展后，选择一种方式设置：

- **粘贴配置**：运行下列命令，复制输出，在扩展设置中启用 Advanced mode，粘贴到配置编辑器并保存。

  ```bash
  chezmoi cd
  chezmoi execute-template < ignore/zen/surfingkeys.js.tmpl
  ```

- **从共享 URL 加载**：初始化时启用 `configShare` 并选择 `surfingkeys`，应用配置并确认启动 config-share 服务。在扩展设置的 `Load settings from` 中填入 `http://127.0.0.1:18080/surfingkeys/config.js` 并保存；其他设备将 `127.0.0.1` 改为共享主机地址，并配置允许客户端 CIDR / 防火墙。

不要直接粘贴 `.tmpl` 源文件；其中包含需要 chezmoi 展开的模板。共享服务使用渲染后的 `~/.local/share/config-share/surfingkeys/config.js`。URL 加载方式见 [Surfingkeys 官方说明](https://github.com/brookhong/Surfingkeys#load-settings-from-a-local-file)。

## Shell

Zsh 配置在 `dot_config/zsh`：

- Antidote 管理 zsh 插件
- Powerlevel10k prompt
- fzf-tab、zsh-autosuggestions、history substring search、syntax highlighting
- `zoxide` 接管 `cd`
- 常用别名和一字母命令
- `s` 函数使用 autossh 和保活参数连接远端；远端交互式 zsh 会自动调用 `t`
- `t` 函数选择/创建 tmux session；手动运行时 detach 后返回原 Zsh，SSH 初始化自启时使用 `t --exec` 替换当前 shell；选择列表中按 `q`、输入 session 名时按 `Esc` 可留在当前 shell，自启选择期间按 `Ctrl-C` 会取消 tmux 并继续完成 Zsh 初始化
- `v` 函数封装 Neovim 打开文件/目录/历史路径

Tmux 配置在 `dot_config/tmux`：

- `C-f` 临时进入 prefix table，状态栏短暂显示
- Vim 风格 pane 导航
- fzf session switcher
- 通用 `copy` wrapper，优先使用系统剪贴板，并以 OSC 52 支持 tmux/SSH
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
- Rime 方案包括虎码、小鹤双拼（`rime_ice`）和全拼（`rime_ice_full`）；输入 `/schema` 后按 `1`、`2`、`3` 选择，也保留 `F4` 方案菜单
- 全拼与双拼共用雾凇词库及用户词典调频数据
- 虎码使用数字选词，并支持空格、`;`、`'` 和方向键选词
- `.chezmoiignore` 会按系统忽略不适用的前端配置

重新部署：

```bash
fcitx5-remote -r
```

macOS 使用 Fcitx5.app 时，`~/.local/bin/fcitx5-remote` 是到 app 内二进制的 symlink。

## Proxy And Network

配置共享由 `configShare` 控制，Linux 使用 `config-share.service`，macOS 使用 `config-share` LaunchAgent。`chezmoi init` 的允许客户端 CIDR 默认为 `127.0.0.1/32`，输入为空也使用此值，仅允许本机访问。允许局域网访问时填写实际网段，例如 `192.168.1.0/24`；网段的主机位必须为零，`127.0.0.1/24` 等输入会被拒绝。已有非空配置会保留，需自行修改。

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
- `qq` : Linux QQ/Hyprland wrapper
- `sioyek`: 强制 Sioyek 使用 xcb
- `sunshine_pre`: Sunshine 启动前显示器布局处理
- `toggle_proxy`: macOS 网络代理开关
- `tmux-notify`: tmux 桌面与 msmtp 邮件通知，按事件每 30 分钟去重

`tmux-notify` 每次都会发送桌面通知；邮件单独按事件执行 30 分钟 debounce。它默认把
`.email` 作为收件地址，发件地址由 msmtp 默认账户决定；可用
`TMUX_NOTIFY_EMAIL` 和 `TMUX_NOTIFY_INTERVAL`（秒）覆盖。邮件失败后每 5 分钟重试，最多尝试
3 次；测试或调试时可用 `TMUX_NOTIFY_RETRY_INTERVAL` 和 `TMUX_NOTIFY_MAX_ATTEMPTS` 覆盖。
进入或重新选择 tmux window/pane 时会删除该目标原有的邮件发送记录，因此随后运行的新程序
不会继承上一个程序的冷却时间。
投递日志位于 `${XDG_STATE_HOME:-~/.local/state}/tmux-notify.log`。邮件投递前需配置 msmtp
的默认账户（通常位于 `~/.msmtprc` 或 `~/.config/msmtp/config`）。

### One-off scheduled tasks (Linux)

`later.path` 监控 `~/.local/state/later/tasks`（或 `$XDG_STATE_HOME/later/tasks`），用于管理支持重启和过期时间的一次性任务。首次运行 `later` 或启动 `later.service` 时会自动创建带注释的任务文件。开机、任务文件变化或定时唤醒时，Python 脚本只为最近的未来任务创建一个 transient systemd timer。编译缓存位于 `later/cache/compiled.json`；未修改的任务复用已解析时间，只有新增或修改行才会重新解析。成功编译后，待执行行会统一写成绝对开始时间和绝对截止时间：

```text
# start-deadline command
2026-10-01T23:00:00-2026-10-01T23:10:00 ~/.local/bin/backup
2026-10-03T09:30:00-2026-10-03T11:30:00 notify-send '记得提交报告'
```

编辑或查看任务文件：

```bash
systemctl --user enable --now later.path later.service
later -e
later -l
later +2h+30m notify-send '两小时后的提醒'
later +3d ~/.local/bin/backup
later 2026-10-03T09:30+2h 'backup | gzip > backup.gz'
later 09:30+20m notify-send '早会'
later 10-03T09:30-10-03T11:00 long-job
later -j
later -j a13f91c2
later -j a13f91c2 -f
```

首个参数是执行时间。相对时间以 `+` 开头并可组合单位，例如 `+2d3h`；本机绝对时间支持 `YYYY-MM-DDTHH:MM[:SS]`。也可以写 `YY-MM-DDTHH:MM`（固定补成 20xx）、`MM-DDTHH:MM`（下一次该月日）或 `HH:MM`（下一次该时刻），但不接受时区标记。末尾的 `+时长` 表示允许延迟执行多久，省略时默认 `1h`；也可以用 `开始时间-截止时间` 直接给出绝对区间。所有简写都会在编译成功后原地展开成完整绝对区间；任意行编译失败时会立即报告行号，且不做部分改写。后面的参数全部属于命令，分隔用的 `--` 可写可不写。不带参数运行 `later` 会按 Pending、Running、Failed、Expired 分类显示任务。

每个规范化任务会由完整任务行生成一个稳定的八位 ID，并显示在 `later` 状态和直接添加结果中。任务的合并 stdout/stderr、开始时间和退出状态保存在 `~/.local/state/later/logs/<ID>.log`。`later -j` 使用 `fzf` 按任务行选择日志；没有 `fzf` 或不在交互终端时打印日志索引。也可以用 `later -j ID` 直接查看，或加 `-f` 持续跟随。ID 支持无歧义的前缀。
交互式输出会分别高亮 ID、开始时间、截止时间、命令和任务状态，`fzf` 也会保留这些颜色；设置 `NO_COLOR`、重定向输出或使用 dumb terminal 时自动输出纯文本。

新建任务文件首行的 `# vim: set ft=later :` modeline 会让 Neovim 将其识别为 `later` filetype，不依赖固定路径 autocmd；已有任务文件需要手动补上这一行。Neovim 通过 `later --check=- --json` 检查当前未保存的 buffer，在打开、保存、离开 Insert mode，以及 Normal mode 停留到 `CursorHold` 时更新 `vim.diagnostic`；错误会像 LSP diagnostics 一样显示下划线、浮窗和跳转，不需要额外的语言服务器。命令行也可以只读检查任务文件或 stdin：

```bash
later --check
later --check=- --json < ~/.local/state/later/tasks
```

过期时间支持 `s`、`m`、`h`、`d`。每个未注释行都是待执行任务。运行中的任务会改成 `# [running]`；成功后移除，失败后改成 `# [failed:退出码]`，过期后改成 `# [expired]`。删除状态标记和行首 `#` 即可重试。命令以当前用户权限运行，关机等操作仍需另行配置权限。查看日志和启用 timer：

```bash
journalctl --user -u 'later*'
systemctl --user enable --now later.path later.service
```

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

macOS 的 `systemctl` wrapper 将 `restart` 映射为先 `launchctl bootout`、再 `bootstrap`，重新读取磁盘上的 plist；例如 `systemctl --user restart config-share`。`daemon-reload` 仍为空操作，因为 launchd 没有无需停止服务的对应命令。

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
- 代理地址来自 `proxy.address`；启用 proxy 模块时默认 `127.0.0.1:7890`。
- 部分个人设备名和主机名写在 SSH/Hyprland 配置中。
