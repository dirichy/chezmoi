# Dotfiles

这是我的跨平台 chezmoi 配置仓库，主要覆盖 Arch Linux/Hyprland 和 macOS 两套桌面环境，同时管理 shell、编辑器、终端、文件管理器、输入法、代理、远程访问和若干本地脚本。

仓库根目录是 chezmoi source directory，目标路径由 chezmoi 规则映射：

- `dot_config/foo` -> `~/.config/foo`
- `dot_local/bin/executable_x` -> `~/.local/bin/x`
- `private_Library/private_LaunchAgents` -> `~/Library/LaunchAgents`
- `*.tmpl` -> 通过 chezmoi template 渲染后写入目标路径

## Quick Start

1. 备份已有配置。准备 Bash 和 curl 或 wget；Arch 使用普通管理员用户运行并准备 sudo。缺失 Git 时入口先用 pacman 安装；默认包安装命令为 paru，缺失时会自动准备 base-devel/Git/Rust 并以普通用户构建。也可在 init 时选择其他安装命令。macOS 先运行 `xcode-select --install` 并完成弹窗。
2. 下载并运行独立安装入口；它在 chezmoi 不存在时安装到 `~/.local/bin`，再初始化仓库。仓库地址可用 `--repo` 指定；已有 checkout 和 init 答案会复用。

   ```bash
   curl -fL https://raw.githubusercontent.com/dirichy/chezmoi/main/install.sh -o /tmp/dotfiles-install.sh
   bash /tmp/dotfiles-install.sh
   # 已在仓库中时：
   ./install.sh
   ```

   新机器需要局域网代理时，下载入口本身可用 `https_proxy`，入口用 `--proxy` 或 `BOOTSTRAP_PROXY`。将 `<LAN-IP>` 换成可用代理地址：

   ```bash
   https_proxy='http://<LAN-IP>:7890' curl -fL https://raw.githubusercontent.com/dirichy/chezmoi/main/install.sh -o /tmp/dotfiles-install.sh
   BOOTSTRAP_PROXY='http://<LAN-IP>:7890' bash /tmp/dotfiles-install.sh
   ```

3. 按 init 提示选择 profile、模块、软件包安装命令、日常代理和下载模式。临时安装代理不会写入配置；日常代理可以填写本机 Mihomo 的 `127.0.0.1:7890`。按 [Secrets](#secrets) 流程生成本机密钥、由旧设备授权密码库，并核对个人 SSH、代理和硬件设置；缺失 secret 会使用默认值，补齐后需再次 apply。
4. 安装入口用于新机器的一次性引导：安装核心依赖、准备设备 SSH/GPG 密钥并克隆/验证密码库、补装所选模块依赖，再执行 `chezmoi apply --keep-going`。资源初始化、Git hook 和用户服务检查由 apply 的维护脚本负责；后续能力更新也走 apply，无需重跑安装入口。安装失败会在最后汇总，按提示补装依赖或重试 apply。

   ```bash
   chezmoi init                  # 之后需要重新生成配置、询问新增选项时
   ./install.sh --skip-services   # 安装时不操作用户服务
   ./install.sh --skip-plugins    # 跳过软件 / 插件初始化
   ./install.sh --help
   ```

   日常 apply 负责配置、external 和维护；依赖清单变化只检查并警告缺失项，不自动安装软件。建议使用 `--keep-going`，让独立步骤继续执行，最后报告失败：

   ```bash
   chezmoi diff
   chezmoi apply --keep-going
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
| macOS 窗口管理 | `desktop` 模块安装 Yabai；授权并手动启动，配置 scripting addition / sudo 权限。改用 AeroSpace 时另行安装 |
| macOS 系统代理 | 在网络设置中设置代理，或使用 `toggle_proxy` |
| 局域网配置共享 | 设置允许客户端 CIDR，开放 TCP 18080，在客户端填写订阅 / 脚本 URL |
| SSH 隧道 / 通知 | 准备 SSH 密钥和远端认证；按下文启用隧道 / 配置通知服务 |

## Setup Notes

### 初始化选项

| 提示 | 需要填写 / 选择的内容 |
| --- | --- |
| `machine profile` | 按下表选择；默认 `desktop` |
| `administrator on this machine` | 是否具备管理员权限；无权限选 `false`，缺失依赖需要自行准备 |
| `prefer chezmoi downloads...` | 两边都能管理下载时是否优先使用 chezmoi；默认 `true`，目前用于选择 Zsh 插件和 Mihomo Geo 的下载方式 |
| `GitHub download mirror` | `ghfast`（默认）、`direct` 或 `custom`；自定义镜像填写拼接在原始 URL 前面的 HTTPS 前缀 |
| `run scheduled download checks...` | 仅 Linux 非 `skip` profile 询问，默认关闭；只在一台常开主机上启用 |
| `package install command` | Linux 确认包管理命令；留空则只提示手动安装缺失包。macOS 安装脚本固定使用 Homebrew |
| `install modules` | 仅 `custom` 询问，填写逗号分隔模块；Linux 支持 `core,shell,system,font-and-im,desktop,proxy,apps,dev,latex,nvidia,extra`，macOS 支持 `core,shell,font-and-im,proxy,desktop,dev,extra` |
| `use proxy for shell and desktop apps` | 是否让 shell、Hyprland 和系统代理使用代理地址，默认关闭；与 Mihomo 的安装和服务启用相互独立 |
| `proxy address host:port` | 启用代理使用开关时填写代理地址，默认 `127.0.0.1:7890` |
| `input method profile` | `tiger` 或 `flypy` |
| `enable fdu-connect` | 需要复旦 VPN 才选 `true`，还需准备账号 secret |
| `Waybar hostname symbol` | 状态栏显示的主机标识，默认主机名 |
| `config sharing mode` | `none`（默认）、`all` 或 `custom`；`custom` 再选 `mihomo,surfingkeys` 中要共享的项目 |
| `allowed client CIDR` | 启用共享时填写；默认 `127.0.0.1/32`，局域网共享需填写实际网段，并自行配置防火墙允许 TCP 18080 |
| `name` / `email` | 自己的 Git 用户名和邮箱；用于 Git 配置和本机设备密钥 |
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
- Linux 包名主要面向 Arch，其他发行版需要核对包名。默认安装命令为 paru 且缺失时，脚本先用 sudo pacman 安装 base-devel/Git/Rust，再以当前普通用户在 `~/.cache/dotfiles` 中构建安装 paru（不把 Rust 构建放进 tmpfs）；手动安装入口会汇总软件包安装失败并继续其他独立步骤，最后返回失败状态。macOS 安装脚本固定使用 Homebrew，缺少时自动安装，需具备相应权限。
- 初始化的代理地址不会提前启动代理；启用后 shell 会使用该地址。缺失 secret 会使用默认值；新设备生成自己的私钥，密码库必须由旧设备授权后才能解密。macOS 核心安装包含 gopass 和 GnuPG。在 apply 后补齐 secret 时需再次 apply。
- 个人 SSH 地址 / 用户名 / 路由器匹配在 `dot_ssh/config.tmpl`，代理节点 / DNS / 路由在 `dot_config/mihomo/config.yaml.tmpl`。Linux 的 GRUB 项、DDC 输入值、OpenRGB profile，以及 macOS 的 Wi-Fi 名称和应用路径需按本机调整。
- Zsh 路径需在 `/etc/shells` 中才能用 chsh。Zsh 插件默认由 chezmoi external 在 apply 时下载；`downloads.preferChezmoi = false` 时改由 Antidote 在首次启动时下载。Neovim、Yazi 首次启动会自动下载插件。Yazi 安装失败时运行 `ya pkg install`，需要自定义提示符时运行 `p10k configure`。
- Linux 脚本安装 / 启用 greetd，但不写 `/etc/greetd/config.toml`。Hyprland 配置使用原生 Lua，需使用支持此配置格式的版本。keyd 配置只生成在用户缓存目录，不会自动安装到 `/etc/keyd/`。
- Linux 手机 idle 检测调用 `sudo l2ping`，需无需交互即可运行；壁纸脚本读取 `~/Pictures/wallpaper`，还需确认 hyprpaper 使用的壁纸存在。远程机器需要退出登录后仍运行 user service 时，另行配置 linger。
- macOS 的 `desktop` 模块包含 Yabai；Fcitx5.app、AeroSpace 和 Alfred 仍需另行安装。Fcitx5 使用[官方 macOS 安装器](https://fcitx-contrib.github.io/)，目前没有 Homebrew 官方 cask。`fcitx5-remote` 链接依赖上述 app 安装位置；虎码和雾凇词典会随输入法配置跨平台通过 Git external 更新。当前 wmux 的 macOS 窗口操作使用 Yabai，`yabairc` 会调用 `sudo yabai --load-sa`。
- 服务确认被拒绝或在非交互环境中跳过后，可在新 Zsh 中运行 `chezmoi x services --check` 检查、`chezmoi x services` 补做；其他 shell 直接运行 source 中的 `ignore/bin/dotfiles-services`。Linux 管理 config-share、FDU Connect、later；macOS 管理 config-share、FDU Connect、Mihomo。
- 每次 apply 都检查用户服务；需要启停时询问确认，非交互环境只报告差异。也可以手动运行 `chezmoi x services`。
- 配置共享可能包含订阅凭据，CIDR 应只允许自己的客户端访问。系统代理与 shell 代理变量需要分别配置。

### 基础能力和设备加入

`core` 包含 Git、OpenSSH、GnuPG、gopass、curl、Python 和 Mihomo；Linux 另含 Zsh/tmux，macOS 使用系统 Zsh 并准备 pinentry-mac。Mihomo 配置对所有非 `skip` profile 生成，是否让日常 shell 使用它仍由 `features.proxy` 决定。

首次安装先使用 `--proxy` 提供的局域网代理。SSH Git 连接也会通过临时 HTTP(S) CONNECT 隧道；代理地址不会写入 SSH 配置。Mihomo 配置中的订阅来自密码库，授权和 apply 完成后仍需验证本机代理实际可用，再切换日常代理。

```bash
./install.sh --store git@github.com:YOUR_ACCOUNT/passwords.git
# 暂停授权后继续，无需重跑 install.sh：
chezmoi x identity --store git@github.com:YOUR_ACCOUNT/passwords.git
chezmoi apply --keep-going
# 只生成/导出公钥，先去旧设备完成授权：
chezmoi x identity --prepare
```

身份准备只生成本机私钥，没有私钥导入选项。已有默认 SSH 密钥、选定的本机 GPG 密钥和密码库会复用；多把 GPG 密钥匹配同一邮箱时，用 `--gpg-key <完整指纹>` 明确选择。公钥和指纹位于 `~/.local/share/dotfiles/device-public.asc`、`gpg-fingerprint`，SSH 公钥位于 `~/.ssh/id_ed25519.pub`（已有 id_rsa 时复用）。为生成的私钥设置口令，不要把私钥复制到旧设备。

在 GitHub 添加 SSH 公钥，在旧设备核对 GPG 完整指纹并运行下方 `add-device`，审核后同步旧设备密码库。新设备只克隆/拉取并检查解密，不自行改变 recipient；验证成功后才报告身份准备完成。`--yes` 不会跳过解密验证；`--skip-identity` 用于明确跳过本次身份准备。密码库不再由 external 管理。

### 日常更新

```bash
chezmoi cd
git pull
chezmoi diff
chezmoi apply --keep-going
```

仓库提供 `.githooks/pre-commit`：提交删除或重命名的 chezmoi source 文件时，
它会把不再管理的旧目标路径自动加入 `.chezmoiremove`，使其他机器下次
`chezmoi apply` 时删除对应文件；若目标文件在本机被修改，chezmoi 仍会询问是否覆盖。
首次 apply 会通过 `run_once_before` 配置 hook。也可以手动启用：

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
- `features.downloadChecks`: 是否在本机生成定时下载检查的 systemd user units，默认关闭
- `downloads.preferChezmoi`: 两边都能管理下载时，是否优先由 chezmoi 管理；默认 `true`，目前用于 Zsh 插件和 Mihomo Geo，不是全局下载开关
- `downloads.githubMirror`: init 时选择的 GitHub 下载方式：`ghfast`、`direct` 或 `custom`
- `downloads.githubMirrorPrefix`: 实际使用的下载前缀；空字符串表示直连
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

按完整路径 `chezmoi/<key>` 精确读取，不触发模糊查找、自动同步或公钥自动导出，找不到时使用模板里的默认值。当前使用到的 secret 包括：

- `serverIP`
- `ikuuu`
- `wyyctc`
- `fduID`
- `fduSecret`
- `maimaiSSpassword`: 个人 Shadowsocks 节点密码
- `tmuxNotifyToken`: tmux 通知服务的认证 token（还需自行部署通知服务）

新增设备使用自己的 GPG 私钥。在新设备生成含加密子密钥的 GPG 密钥后，执行 `gpg --armor --export <完整指纹> > device-public.asc`，只传递公钥。在已有授权的设备上核对完整指纹，然后运行：

```bash
./ignore/bin/add-device device-public.asc <完整指纹>
# 使用特定 gopass 子 store 时，在末尾追加 store 名称。
```

脚本只接受单个 ASCII-armored 公钥并核对主密钥完整指纹，再导入公钥、调用 gopass 自带的 recipient 授权和重加密。保留 gopass 的确认与信任检查；不会自动设置 ultimate trust。`--nosync` 禁止自动拉取或推送，但 gopass 自身可能创建本地提交。失败时会报告公钥已导入、授权未完成，可检查后重跑；不自动回退已完成操作。审核并手动同步 store 后，新设备用自己的私钥读取它，无需复制其他设备的私钥。本仓库不再使用 git-crypt。

安装链路另有 [双设备 GitHub Actions 测试](ignore/tests/install-lan/README.md)：新设备没有直连外网，真实编译安装 paru，依次完成 SSH/GPG 授权，再从假密码库的订阅链接取得长期代理，关闭临时代理后验证下载、装包和 apply。可在 Actions 手动运行，也可本机用 Docker 执行测试入口。

## Dependencies

`install.sh` 只做一次性引导，不承载日常功能。它安装 chezmoi、初始化仓库、调用公共依赖安装能力，再执行普通 apply。以后新增能力放进对应配置、公共包清单或 `run_*`，不要求已有机器重跑入口。

| 能力 | 执行时机 | 失败处理 |
| --- | --- | --- |
| 系统软件包安装、sudo 操作、临时安装代理 | 手动入口；后续补包用 `chezmoi x packages` | 安装失败汇总，继续独立步骤 |
| SSH/GPG 设备身份、密码库加入 | 首次安装；后续 `chezmoi x identity` | 等待 GitHub / 旧设备授权，检查解密后才成功 |
| 缺失依赖检查 | `run_onchange_before`，依赖清单 / 检查逻辑变化时 | 只警告，不安装、不提权 |
| 仓库 Git hook | `run_once_before`，首次 apply | 失败警告 |
| 应用资源初始化 | `run_onchange_after`，相关配置 / 初始化逻辑变化时 | 失败返回错误，下次 apply 重试；`--keep-going` 继续其他步骤 |
| 用户服务检查与协调 | `run_after`，每次 apply | 需要改变时确认；失败警告 |
| chezmoi 管理的外部资源 | external 的缓存 / 刷新周期 | 由 chezmoi 报告下载失败 |

后续依赖缺失时运行 `chezmoi x packages`，只检查用 `chezmoi x packages --check`。其他 shell 可直接运行仓库内 `ignore/bin/dotfiles-packages`。这些入口与首次安装共用包清单和逐包检测逻辑。

入口只要求 Bash 和 curl/wget，可在安装 chezmoi、运行 init 之前执行。已有 chezmoi、仓库与 init 数据会复用；`--source` 选择已有 checkout，`--repo` 选择初始化来源。安装选项沿用 `[data.install]`，`INSTALL_PROFILE` / `INSTALL_MODULES` / `INSTALL_COMMAND` / `INSTALL_ADMIN` 仍可临时覆盖。

包清单与平台差异保留在 `.chezmoitemplates/install-packages-linux`、`install-packages-macos`；`.chezmoitemplates/install-common` 共用模块调度、逐包检测与失败汇总，语法兼容 macOS 自带 Bash 3.2。先准备 Python 3 / Lua 等模板依赖，再安装所选模块；缺失项逐包尝试，最后把失败交给手动入口汇总，不阻止独立的配置应用步骤。`skip` 跳过软件包安装。

入口为子进程统一导出临时 HTTP 代理变量，并通过进程级 Git 配置覆盖 Git 代理，不写全局 gitconfig。资源初始化通过 `zsh -dfc` 跳过用户启动配置，直接继承入口导出的代理变量；Linux 的 sudo 安装命令会请求保留代理变量，是否获准取决于 sudo 策略。临时代理在入口退出后结束，不会自动变成日常代理。

软件资源使用各自的初始化流程：Antidote 下载缺失的 Zsh 插件，Lazy 安装缺失的 Neovim 插件，`ya pkg install` 安装 Yazi 包，`mihomo -t` 初始化并验证配置；不启动桌面应用窗口。部分语言服务器 / 按文件类型触发的解析器仍需按使用需求安装。原版 Mihomo 的下载网络由它自身决定，不保证使用 shell HTTP 代理；需要临时局域网 HTTP 代理下载 Geo 时，使用默认的 chezmoi 下载模式。

`--yes` 可用于非交互安装（包括接受服务协调），`--skip-plugins`、`--skip-services`、`--skip-hooks` 只跳过本次安装中的对应维护，`--skip-identity` 跳过本次设备授权，下次普通 apply 仍可执行。入口始终调用普通 `apply --keep-going`，因此未来新增的维护脚本也自动纳入。失败后补包用 `chezmoi x packages`，重试资源初始化用 `chezmoi apply --keep-going`；无需重跑安装入口。`--config`、`--destination`、`--cache`、`--state` 支持独立目录，测试均使用隔离配置和模拟命令。

Linux 安装脚本默认按当前发行版给出安装命令，例如 Arch/Manjaro 使用 `paru -S --needed --noconfirm --skipreview`，Debian/Ubuntu 使用 `sudo apt-get install -y`，Fedora 使用 `sudo dnf install -y`。其它发行版可以在 init 时填写 `install.command`，例如 `sudo apk add` 或 `sudo xbps-install -Sy`。安装会逐包执行，单个包失败不会中断整个 module，最终汇总所有失败并返回非零状态。

包名仍以当前配置使用的名字为主；非 Arch 系统遇到包名不匹配时，安装脚本会记录失败并继续，用户再按汇总提示手动安装。

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

两平台的 `shell` 模块都包含日常工具 `ripgrep`（`rg`）、`tree`、`bat`、`bottom`（`btm`）、`uv`、`duf`、`dust`、`wget`，以及 ZIP、7-Zip 和 Zstandard 压缩工具（Linux 包名为 `7zip`，macOS 为 `sevenzip`）。这些工具随所有非 `custom` / `skip` profile 安装；`custom` 需选择 `shell` 模块。

两平台的 `shell` 模块还包含 `msmtp`、`thefuck`、`wakeonlan`、`aria2` 和 `bypy`。Linux 的 bypy 使用 AUR 包；macOS 没有 Homebrew 官方 formula，由 `uv tool install bypy` 安装到隔离环境，命令放在 `~/.local/bin`，不修改系统 Python。

两平台的 `shell` 模块还安装 Neovim 当前配置使用的格式化和检查工具：StyLua、isort、Black、rustfmt（随 Rust 安装）、prettierd、shfmt、ClangFormat、ShellCheck、Hadolint、Luacheck、markdownlint、Ruff、yamllint 和 tex-fmt。默认启用的语言服务也通过全局包管理器安装：texlab、LuaLS、Pyright、JSON、Marksman、Dockerfile、Docker Compose、Bash 和 clangd。Linux 的 Compose 服务使用 npm 全局安装到 `~/.local`，其余使用系统包；macOS 使用 Homebrew，clangd 使用已有工具链在 PATH 中提供的版本；需要特定版本时自行调整 PATH 或在 `~/.local/bin` 中链接。Neovim 直接调用 `clangd`，不探测或回退到其他版本。Neovim 不再加载 Mason；语言服务配置用 `:help lspconfig-all` 查阅，formatter、linter 和调试器等工具可搜索 [Mason Registry 网页目录](https://mason-registry.dev/registry/list)。LTeX+（`ltex-ls-plus`）随其他 LSP 自动安装，仍用 `<leader>tc` 手动启用；Linux 使用 AUR 的 `ltex-ls-plus-bin`，macOS 使用 Homebrew 的 `ltex-ls-plus`。Linux 的 prettierd、tex-fmt 和 hadolint-bin 使用 AUR 包，需要支持 AUR 的安装命令。

Yazi 的 Starship、MediaInfo、DuckDB、ouch、Word/PDF/SVG 预览和回收站插件依赖也随 `shell` 安装，包括 `pandoc`、`poppler`、`resvg`、`trash-cli`、FFmpeg 和 ImageMagick；Linux 的 GVfs/磁盘挂载后端放在 `system` 模块。macOS 的 `trash-cli` 管理 Freedesktop 回收站，与 Finder 回收站分开；当前删除操作仍使用 Yazi 默认行为。Neovim 的图片处理共用 ImageMagick，macOS 图片粘贴另安装 `pngpaste`，Linux Wayland 剪贴板由 `desktop` 模块的 `wl-clipboard` 提供。

Rime 的 `font-and-im` 模块还包含手机部署所需的 ADB（Linux `android-tools` / macOS `android-platform-tools`）。Linux `shell` 模块包含 Neovim 自动编译 Treesitter parser 所需的 GCC、Make 和 Treesitter CLI；macOS 使用 Xcode Command Line Tools 的编译器/Make，并安装 `tree-sitter-cli`（`tree-sitter` 包只提供解析库）。

wmux 使用随仓库分发的纯 Lua JSON 编解码器 [rxi/json.lua v0.1.2](https://github.com/rxi/json.lua/tree/v0.1.2)，源码和 MIT 许可保存在 `scripts/lua/wmux/vendor/json.lua`。Karabiner 模板渲染和 Yabai 查询不依赖 lua-cjson / LuaRocks，首次渲染只需已有的 Lua 解释器。

macOS 安装脚本会先检测是否能访问 Google；不能访问时使用清华 Homebrew 镜像。

### 下载镜像与链接检查

init 可选择 `ghfast`（默认 `https://ghfast.top/`）、官方直连 `direct` 或自定义 HTTPS 前缀。此前没有 `downloads` 数据的机器继续使用 ghfast。已有机器用 `chezmoi edit-config` 修改本机数据，例如切换官方直连：

```toml
[data.downloads]
githubMirror = "direct"
githubMirrorPrefix = ""
```

真正用于生成 URL 的是 `githubMirrorPrefix`；修改后重新 apply。镜像只负责 GitHub 文件下载，覆盖 Spoon、FDU Connect 安装包、Mihomo Geo / 规则和 Homebrew 的官方安装脚本分支；Homebrew 的清华镜像分支保持独立。Git 克隆、插件管理器和私有订阅不经过此选项。Spoon 在 external 中用小循环列出，跟踪 `master` 下的 ZIP，每 24 小时刷新；Geo 跟踪 MetaCubeX 的 `release` 数据分支。镜像地址失效时，可以切换直连或其他镜像，无需修改多处模板。

Spoon 和 FDU Connect 的 archive external 默认通过 `urls` 按顺序回退：本机选定镜像 → `gh-proxy.com` → `ghproxy.net` → ghfast → 官方地址（重复地址去重）。选择 `direct` 时只使用官方地址。外部地址全部失败仍会由 chezmoi 报错，可用 `chezmoi apply --keep-going` 继续处理其他目标，最终保留失败状态。这里的回退针对下载失败，不应把它当成内容校验的替代。

手动检查入口会渲染两个平台的公共 HTTP 下载链接，不调用 secret、不访问个人密码库或订阅，也不执行 apply / 安装。检查以最多 4 KiB 的请求探测 HTTP 状态、空响应、HTML 错误页和 ZIP 文件头，不下载完整 Geo 数据，也不等同于完整文件校验：

```bash
./ignore/bin/check-downloads                 # 检查本机选择的镜像，失败时非零退出
./ignore/bin/check-downloads --direct        # 对照检查官方地址，帮助区分镜像与上游问题
./ignore/bin/check-downloads --list          # 只列出链接，不联网
./ignore/bin/check-downloads --filter spoon # 只检查 Spoon
```

脚本需要 Python 3.11+ 和 chezmoi。默认回归测试仍离线；`check-downloads` 是单独的联网操作，网络超时会报告失败，但不能据此认定上游文件已删除。

定时检查只需在一台常开 Linux 主机 / 服务器上开启。init 时选择下载检查，或者在已有 `[data.features]` 中设置 `downloadChecks = true`，apply 后才会生成对应的 service / timer；其他机器默认不生成。不会通过服务协调脚本自动启用此 timer。在选定主机上手动启用：

```bash
systemctl --user daemon-reload
systemctl --user enable --now dotfiles-download-check.timer
systemctl --user start dotfiles-download-check.service # 可选：立即检查一次
journalctl --user -u dotfiles-download-check.service
```

timer 每天触发一次，随机延迟最多一小时，并补做关机期间错过的执行。结果保留在 journal，失败时 service 进入 failed 状态，不会自动通知或修改配置。若需退出登录后仍运行 user timer，另行配置用户 linger。检查使用这台机器的镜像设置，覆盖仓库内两个平台的公共资源；无需在每台客户端重复运行。设为 `false` 前先手动禁用 timer：`systemctl --user disable --now dotfiles-download-check.timer`。

## Repository Map

```text
.chezmoi.toml.tmpl                 chezmoi 本机数据和 secret 配置
.chezmoiignore                     按系统忽略不适用的配置
.chezmoiexternal.toml              外部资源，如 Rime 大文件、Hammerspoon Spoon
.chezmoitemplates/                 被其他模板 include 的片段
dot_config/hypr/                   Arch Linux Hyprland 桌面
dot_config/waybar/                 Waybar 状态栏
dot_config/wofi/                   Wofi 启动器
dot_config/systemd/user/           Linux user services
dot_config/nvim/                   Neovim 配置
dot_config/tmux/                   Tmux 配置和 helper 脚本
dot_config/zsh/                    Zsh 配置与显式插件加载
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

每次 `chezmoi apply` 都会检查仓库管理的用户服务，首次安装也通过同一个 apply 流程执行。Linux 使用 `systemctl --user` 管理 Config Share、FDU Connect 和 Later；macOS 使用原生 `launchctl` 管理 Config Share、FDU Connect 和 Mihomo。期望启用但尚未启用的服务会询问是否启用并启动；配置中已经关闭但仍处于 enabled 状态的服务会询问是否停止并禁用。非交互服务协调默认只报告差异（安装入口显式使用 `--yes` 时接受调整）。也可以手动运行 `chezmoi x services --check` 做只读检查，或使用 `chezmoi x services --yes` 接受全部调整。仓库内部 helper 位于 `ignore/bin`，由 zsh 中的 `chezmoi x` wrapper 调用，不会部署到 `~/.local/bin`。Linux 上需要实例参数的 `ssh-tunnel@.service` 不参与自动协调。

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

- `downloads.preferChezmoi` 选择插件下载方式；两种方式共用 `plugin-repos.txt` 清单和 `plugins.zsh` 加载顺序
- Powerlevel10k prompt
- fzf-tab、zsh-autosuggestions、history substring search、syntax highlighting
- `zoxide` 接管 `cd`
- 常用别名和一字母命令

Vi 模式会在进入普通模式时记住输入法状态并临时切换英文（`temp_ascii`），回到插入模式、提交或取消命令时恢复（`restore`）；重复进入普通模式不会覆盖保存的状态。本地 Linux/macOS 直接调用 `fcitx5-remote`，遵循当前 shell 的命令查找规则，允许通过函数或 PATH 中的 wrapper 自定义；命令缺失时跳过。本地查询和切换由后台 worker 串行处理，不阻塞 ZLE；恢复也异步执行，因此命令启动时输入法可能仍在恢复中。Fcitx5 Rime 两个平台均设为切换时上屏原始输入（`Commit raw input`），不提交候选预览；该设置对其他输入法切换也生效。SSH 会话通过 Kitty 的 `SetUserVar=im` 协议控制客户端输入法，需要客户端启用本仓库的 `im-control.py` watcher；经过 tmux 时需允许 passthrough（本仓库已开启）。

Esc 等待时间由 Zsh 的 `KEYTIMEOUT` 控制，单位为 10ms：本地或 tmux 内设为 `1`（10ms），SSH 且不在 tmux 内设为 `5`（50ms）。通过 `SSH_TTY` / `SSH_CONNECTION` 和 `TMUX` 在 shell 启动时判断；已有 tmux pane 重新 attach 不会重新计算。tmux 自身的 `escape-time` 保持 40ms。

`downloads.preferChezmoi` 表示管理方式的偏好，不表示是否允许下载。没有此字段的旧配置默认按 `true` 处理；目前用于 Zsh 插件和 Mihomo Geo；Spoon 暂时仍由 external 下载，Neovim、Yazi 等软件自己的插件下载机制保持原样。可在 `chezmoi edit-config` 中设置：

```toml
[data.downloads]
preferChezmoi = true
# 同一表中保留已有 githubMirror / githubMirrorPrefix。
```

`true` 时，所有 profile（包括 `skip`）通过 chezmoi `git-repo` external 下载到 `~/.config/zsh/plugins/`，刷新间隔为一周（`168h`），使用浅克隆和 `git pull --ff-only`。刷新只在运行 chezmoi 时发生，需要立即更新时可运行 `chezmoi apply -R ~/.config/zsh`。

`false` 时，chezmoi 不声明 Zsh 插件 external；Zsh 使用 `~/.config/zsh/.antidote/` 中的 Antidote，将插件下载到同目录下的 `.antidote-plugins/`，已有插件不会在每次启动时联网更新。手动运行 `antidote update` 更新插件和管理器。Antidote 只负责下载，不生成或加载 `.zsh_plugins.zsh` 缓存；安装管理器使用临时目录，下载期间使用自动释放的文件锁，没有有效 HEAD 的残留 checkout 会保留到 `.cache/` 后重试。Git checkout 已有有效 HEAD 但工作区损坏时，仍需检查后手动修复。

两种方式的仓库清单来自 `.chezmoitemplates/zsh-plugin-repos`，加载顺序在 `dot_config/zsh/plugins.zsh`。切换偏好后需要 apply，旧后端的插件目录保留，不自动删除；缺失插件会提示，但不会中止其余 Zsh 配置。

单独配置 Zsh 的机器可以复制**已部署的整个** `~/.config/zsh/`，包括隐藏文件和当前后端下载的插件（不是仓库中的 `dot_config/zsh/` 模板）。接收端不需要 chezmoi；Antidote 模式的管理器也包含在该目录内。可先用下面的方式启动，或把第二行加入接收端的 `~/.zshenv`，作为持久入口（保留原有内容）：

```zsh
ZDOTDIR="$HOME/.config/zsh" zsh
. "$HOME/.config/zsh/.zshenv"
```

目标机需安装 Zsh；完整体验还需 `fzf`、`zoxide`、Neovim、tmux 等所用命令，复制目录不会安装程序。macOS 插件仓库也会在 Linux 下载，但只在 macOS 加载，方便跨平台复制。部署的 `.zshenv` 中代理和 TERM 策略仍来自原机器的模板数据，复制后请按目标机器调整；Homebrew 路径在启动时按平台检测。自定义提示符 `.p10k.zsh` 也应一起复制。

历史记录默认改存为 `$ZDOTDIR/.zsh_history`，补全和语法高亮缓存放在 `$ZDOTDIR/.cache/`；其他工具仍遵循各自的数据/缓存路径。旧历史通常在 `~/.local/share/zsh/history`，需要保留时请在关闭其他 Zsh 后自行迁移；跨机复制时可排除历史和缓存，缓存会重建。旧 `.zsh_plugins.zsh`、其 `.zwc` 以及 `~/.cache/antidote/` 不再使用，未自动删除，以便核对后自行清理；`.antidote/` 仅在 Antidote 模式下使用。

其他 Shell 工具：

- `s` 函数使用 autossh 和保活参数连接远端；远端交互式 zsh 会自动调用 `t`
- `t` 函数选择/创建 tmux session；手动运行时 detach 后返回原 Zsh，SSH 初始化自启时使用 `t --exec` 替换当前 shell；选择列表中按 `q`、输入 session 名时按 `Esc` 可留在当前 shell，自启选择期间按 `Ctrl-C` 会取消 tmux 并继续完成 Zsh 初始化
- `v` 函数封装 Neovim 打开文件/目录/历史路径
- `a r`（或 `codex r`）用 fzf 恢复当前目录的 Codex session，`a ra` 显示全部目录；列表顶部提示快捷键：`Ctrl-D` 切回当前目录，`Ctrl-A` 显示全部，`Enter` 恢复。当前目录视图隐藏路径，全部视图显示路径；最近活动时间简写为 `5m`、`3h`、`2d`、`4w`，超过一年留空。匹配目录使用解析符号链接后的完整路径，不含子目录。选择后以该 session 的目录调用 `codex resume <id> --cd <cwd>`，原生 `codex resume` 保持原样。
- 会话标题优先使用 Codex 保存的名称（`threads.name`，包括自动生成或手动重命名的标题），其次使用 `session_index.jsonl` 的最新 `thread_name`，都没有时才使用原始标题 / 第一句 prompt；旧版 rollout 模式也会同步名称索引中的重命名。
- Session picker 默认进入 Insert 模式输入搜索；`Esc` 切到 Normal 并保留搜索过滤，`j/k` 上下选择，`i` 回到 Insert。Normal 下 `q` / `Esc` 取消，两种模式均可 `Enter` 恢复。顶部显示当前模式和快捷键，边框标明 `cwd` / `all`。此模式切换需要 fzf 0.59+。
- Session 索引在 `${CODEX_HOME:-~/.codex}/wrapper-resume.sqlite3`，只读同步本地 Codex 数据库中的未归档 CLI/VS Code 会话，不按账号隔离；旧版本没有可用数据库时增量读取 `sessions/`。当前目录优先，再按恢复次数的对数与最近活动时间加权排序（1 小时内 ×4、1 天内 ×2、1 周内 ×0.5、更早 ×0.25）；次数只记录此 picker 的选择。删除索引可重建，但会丢失恢复次数。需要 `fzf`、`python3`，缺少时回退原生 picker。

Tmux 配置在 `dot_config/tmux`：

- `C-f` 临时进入 prefix table，状态栏短暂显示
- Vim 风格 pane 导航
- fzf session switcher
- 通用 `copy` wrapper，优先使用系统剪贴板，并以 OSC 52 支持 tmux/SSH
- `copy` 的 OSC 52 输入超过 64 KiB 时先确认并显示输入大小；优先使用通用 `dialog` / `whiptail`，未安装时退回终端 `[y/N]` 提示，默认取消。tmux 中在独立 popup 内确认；无可用交互终端或 popup 打开失败时取消。确认后流式编码、发送全文，wrapper 不再截断，但仍受接收终端的大小限制。系统剪贴板与远程 tunnel 后端不受影响，Neovim 内置 OSC 52 不经过此 wrapper。
- btm popup
- activity notification

## Editor

Neovim 配置在 `dot_config/nvim`：

- `lazy.nvim` 自动 bootstrap
- Lua 模块化配置：options/keymaps/autocmds/plugins
- LSP、completion、treesitter、debug、UI、LaTeX、Neorg、LeetCode、Firenvim 等插件分组
- Treesitter 缺失 parser 时异步安装，完成后自动启用相关缓冲区的高亮、折叠和缩进
- 支持 LuaRocks 路径
- `PROF=1 nvim` 可启用 snacks profiler

Kitty 的 scrollback 使用 [kitty-scrollback.nvim](https://github.com/mikesmithgh/kitty-scrollback.nvim)，
保留 `Ctrl+f` 后按 `Esc` 的入口，并关闭插件默认 Neovim 键位。插件由 lazy.nvim 在首次启动时安装；
复制后打开的编辑窗中，`:w` 保持粘贴回 Kitty 的行为，`:q` 将编辑窗全文复制到系统剪贴板并退出整个 scrollback。
Kitty 通过 action alias 调用 `~/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py`，
自定义 `XDG_DATA_HOME` / `NVIM_APPNAME` 时需同步调整此路径。要求 Kitty >= 0.43.0、Neovim >= 0.10。
应用配置并安装插件后，完全退出并重新打开 Kitty，使 `listen_on` 生效，再运行 `:KittyScrollbackCheckHealth` 检查。

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
- 上游由 `.chezmoiexternal.toml` 克隆到 `~/.cache/rime-tiger/upstream` 和 `~/.cache/rime-ice/upstream`，词典由模板读取或链接到 `~/.local/share/fcitx5/rime`
- Rime 方案包括虎码·常用（`tiger`）、小鹤双拼（`rime_ice`）、全拼（`rime_ice_full`）和虎码·全字集（`tiger_full`）；输入 `;s` 后按 `1`、`2`、`3`、`4` 选择，也保留 `F4` 方案菜单
- 全拼与双拼共用雾凇词库及用户词典调频数据
- 虎码使用数字选词，并支持空格、`;`、`'` 和方向键选词
- `.chezmoiignore` 会按系统忽略不适用的前端配置

虎码上游由 Git external 克隆到 `~/.cache/rime-tiger/upstream`，跟踪 [zhhmn/huma-rime](https://github.com/zhhmn/huma-rime) 的 `master` 分支，刷新间隔为 `24h`。更新使用 `git pull --ff-only`，不再定期下载整个 ZIP，也不需要自定义 SHA 查询脚本。此目录由 chezmoi 管理，不要直接修改。

词典生成在对应 `.tmpl` 文件渲染时完成，不使用 `run_after`，不写入真实输入法目录之外的配置。完整 `apply` 按路径顺序先更新 `.cache/` 下的上游，再渲染 `.local/` 下的词典，因此同一次 apply 使用更新后的码表：

- `tiger.dict.yaml.tmpl` 读取上游完整词典。
- `tiger_common.dict.yaml.tmpl` 调用 `ignore/bin/rime-tiger-dictionary`：任意编码权重 ≥ 255 的字，其全部编码都保留，原权重和顺序不变，不依赖 `core2022`。阈值为 helper 的 `COMMON_MIN_WEIGHT`。
- `lua/tiger/simp_table.lua.tmpl` 复用同一上游指纹及常用字典缓存，生成简码推荐表；直接读取生成器返回内容，不依赖常用字典先落盘。
- `tiger_common.extended.dict.yaml.tmpl` 保留本地扩展词典的全部条目，仅替换导入的词典名称。
- `opencc` 链接到本地 `shared_opencc`，其中仅链接虎码读音、拆分所需的上游文件；不引入上游旧版 `s2t.json`，简转繁统一使用系统 OpenCC 标准 `s2t`。上游方案、Lua、快捷键和鼠须管皮肤不会覆盖本地配置。网站启动器已移除，不再部署或加载上游 `lua/exe.lua`。

虎码拼音反查的候选注释优先使用当前方案码表中的真实整词码；没有整词码时逐字显示虎码，字间用空格分开，同字多码用 `/` 分开。`?` 表示该字未收录在当前方案码表中。拼音提示开关只作用于正常虎码输入，反查时保留虎码提示。

雾凇使用同样的 Git external 更新方式，跟踪 `main`，间隔 `24h`，使用 `git pull --ff-only`。`rime_ice.dict.yaml.tmpl` 读取上游主词典，`cn_dicts` / `en_dicts` 链接上游词库目录，替代固定的 `rime_bigfiles` 压缩包。部件词典 `radical_pinyin.dict.yaml` 和基础部件方案 `radical_pinyin.schema.yaml` 也直接链接上游，随 external 更新；小鹤部件覆盖层、本地主输入方案、Lua 扩展和键位继续自行维护，不会自动开启其余上游功能。全拼和小鹤双拼继续共用 `rime_ice` 词库和用户词典。

虎码与雾凇共用 `shared_emoji/emoji.json` 和生成的 `emoji.txt`。模板调用 `ignore/bin/rime-merge-emoji` 合并两边的 `opencc/emoji.txt`：保留原文字，重叠项优先采用雾凇顺序，再补入虎码候选，按完整 Unicode 字符串精确去重（不合并有无变体选择符、肤色不同的 Emoji）。两套方案的 Emoji 开关统一命名为 `emoji`，首次会话按启动方案设置默认状态（虎码关、雾凇开），之后切方案不重置；全局 `Ctrl+Shift+3` 和虎码 `Ctrl+i` 均操作此开关。雾凇 `others.txt` 中的翻译、别名、化学式等附加转换不自动合入。合并仅在配置渲染时执行，不在按键路径执行。

尚未启用的上游功能与 Emoji 对比见 [Rime 上游功能对照](ignore/rime-upstream-notes.md)。

当前全部功能、公共化结果和待选项见 [Rime 功能全表](ignore/rime-features.md)。四套方案共用日期、计算器和数字金额工具；计算器保留虎码 `=...` / 雾凇 `cC...`，金额转换保留虎码 `S123` / 雾凇 `R123`。日期与时间分别使用 `/d`、`/t`，也能用英文关键词搜索：

| 输入 | 功能 |
| --- | --- |
| `/d` | 日期，后续候选提供子命令 |
| `/de` / `/dc` | 英文 / 中文日期 |
| `/t` / `/dt` | 时间 / 日期时间（含实际时区） |
| `/ts` | 时间戳 |
| `/dw` / `/dm` | 星期 / 英文月份 |

日期映射集中在 `lua/date_commands.lua`，输入更长命令时不会提前提交短命令。`/path`、`/version` 的调试入口及虎码 `/simpstats` 保留。组件按方案加载，`rime.lua` 不预加载扩展；简繁统一使用标准 `s2t`。网站入口已移除。

私人短语与符号共用 `/` 菜单、逐级导航和英文 fuzzy 搜索。`/q` 列出可用的 gopass 条目名；条目只有一个值时，点选、空格或数字选择后直接上屏，有多个值时才进入下一层选择。实际值保留原文，不受简繁、Emoji 滤镜改写，也不加入拼音词典。

只需在 `dot_local/share/fcitx5/rime/lua/private_quick_phrase_data.lua.tmpl` 的 `$keys` 列表追加一个名字：

```gotemplate
{{- $keys := list
  "phone/main"
  "phone/backup"
  "fduID"
-}}
```

名称相对于 `chezmoi/`，例如 `phone/main` 对应 `gopass insert chezmoi/phone/main`。不再单独维护编码、label、菜单名称或英文关键词：gopass 条目名同时用于精确路径、显示和 fuzzy，目录分隔符、下划线、连字符和 camelCase 会自动分词。显式列表避免把密码、token 等其他 secret 自动暴露给输入法；同一资料只维护一份，`fduID` 同时供 Rime 和 fdu-connect 使用。

| gopass 条目 | 精确入口 | fuzzy 示例 |
| --- | --- | --- |
| `chezmoi/phone/main` | `/qphone/main` | `/main` |
| `chezmoi/phone/backup` | `/qphone/backup` | `/backup` |
| `chezmoi/phone/dad` | `/qphone/dad` | `/dad` |
| `chezmoi/fduID` | `/qfduID` | `/fdu` |

可以直接打完整路径，也可以输入 `/qphone/` 等前缀，再选菜单中的条目。条目名已显示为候选文字时，注释留空，不重复名称或路径；显示实际值时仍用条目名区分来源。路径分隔符可以省略：例如 `phone/work` 也能用 `/phonework` 或 `/phwrk` 搜到，不需要另配别名。`/main` 这样的 fuzzy 查询找到条目后，只有一个值时按一次空格或数字即可直接上屏，不再要求先进入条目。名称支持英文字母、数字、`/`、`_`、`-`，区分大小写的完整名称用于精确入口，fuzzy 不区分大小写。私人路径输入中，数字或分隔符在命中已知未完成路径时继续补全，否则保留选词、翻页等用途；已经进入实际值候选后，数字用于选择。若两个名字存在数字后缀歧义，可从 `/q` 菜单进入。

模板逐条读取列表中的 gopass secret，缺失或不可解密的条目会省略；`.chezmoitemplates/luaString` 对引号、反斜杠和控制字符进行 Lua 字符串转义，资料只作为文本写入明文 Lua 表。列表顺序就是菜单顺序；名称重复时只显示一次。耗时只发生在渲染阶段，Lua 初始化后只查内存，不依赖 gopass、Python 或 Shell。数据文件缺失或格式错误时不加载，不在日志中输出私人资料。

桌面产物 `lua/quick_phrase_data.lua` 权限为 `0600`；dotfiles 只保存名字列表，真实资料在 gopass，产物和 `chezmoi diff` / `cat` 预览仍是明文，不应提交到 Git。修改条目或列表后重新应用短语文件，再手动重新部署 Rime。

部署到支持 Lua 的 fcitx5-android 时，使用下文的 `rime-export` 导出渲染后的配置、Lua、私人短语和词典资源。手机运行输入法时不需要 chezmoi 或 gopass；导入或更新配置后手动重新部署 Rime。

桌面与手机共用源模板，不再维护 Android 的 `default.custom.yaml` 补丁。模板开头只读取一次 `.chezmoi.os`，后续用普通条件分支决定键位和组件；渲染时传入 `--override-data '{"chezmoi":{"os":"android"}}'` 生成手机版，不传则沿用本机平台。四套方案共用 `default.yaml` 中的 `input_keys`，Lua 在运行时读取这张表：

| 行为 | 桌面 | Android |
| --- | --- | --- |
| 功能入口 / 切方案 | `;` / `;s` | `\` / `\s` |
| 设置菜单 | `;o` | `\o` |
| 字母快符 | `e;` → `（` | `e\` → `（` |
| 普通候选二选、虎码重复末字 | `;` / `z;` | `\` / `z\` |
| 反查 / 部件辅码 | 反引号 | `~` |
| 退格 | Backspace 或反斜杠 | Backspace |

手机输入的编码始终保留 `\` 和 `~`，不转发为桌面按键。例如 `\s`、`~riyue`、`shi~mu` 后按回车，会原样上屏；空格、数字和点选仍执行相应功能或提交候选。英文模式中这两个字符正常输入。手机分支移除翻页快捷键、桌面组合键、以词定字快捷键、击键统计、简码提醒与记录、历史上屏组件及虎码 Unicode 提示滤镜和同文键盘选项；翻页或展开候选由手机前端处理。桌面功能保留。

单独输入 `;`（手机 `\`）打开功能总菜单，显示“切换方案”（`s`）、“设置”（`o`），桌面虎码另有“击键统计”（`k`）。候选注释显示下一键；点选、空格或数字可进入子菜单或执行动作，也可直接追加字母使用 `;s` / `;o` / `;k`。子菜单退格回到总菜单，回车原样上屏当前编码。总菜单使用与 `/` 相同的原生候选选择机制，功能名称不会上屏。

`;o`（手机 `\o`）打开设置菜单，显示当前方案实际配置的普通开关及其当前状态（如“读音 关”“简繁 简体”），省略切换后的状态，点选、空格或数字即可切换，菜单名称不会上屏；不显示已移除的功能或同文专用键盘选项。两端均使用简短注释：数字转换只标“小写 / 大写 / 金额 / 金额大写”，虎码简繁与 Emoji 不重复提示原文字；读音、拆分、纠错、菜单路径和私人条目名等用于辨别候选的信息保留。

用 `./ignore/bin/rime-export /tmp/rime-android-phone` 导出手机版，输出目录必须不存在。脚本读取本机 chezmoi 数据，在独立的 source、destination、cache 和 persistent state 中渲染 Android 分支，只处理 Rime，不运行安装脚本或刷新 external；复用桌面已有的 `.cache/rime-ice/upstream` 和 `.cache/rime-tiger/upstream`。产物将词典和 OpenCC 链接展开成实际文件，把合并后的 Emoji 映射放进 `opencc/`，不包含桌面的 build 或用户词库。输出目录权限为 `0700`，私人短语文件保持 `0600`，只打印成功渲染的条目数量，不输出内容。

导出后执行 `adb push /tmp/rime-android-phone /sdcard/Download/`。在手机 DocumentsUI 的 Download 目录中打开 `rime-android-phone`，全选其内部文件及目录，复制到侧边栏“小企鹅输入法5”下的 `data/rime`，确认同名文件覆盖，再在 Rime 菜单中重新部署。不要把整个外层目录套进 `rime`，也不要直接用 ADB 写应用目录。脚本不自动传输、重载或删除手机数据；导入前可先通过应用备份原配置。

首次通过 DocumentsUI 导入后，日常更新可运行 `./ignore/bin/rime-deploy --dry-run` 预览，再运行 `./ignore/bin/rime-deploy`。它自动导出、比较手机文件的 SHA-256，只更新变化的现有文件，通过向原文件写入内容保留 inode、UID/GID 和权限，不使用 `adb push` 替换应用文件，也不执行 chown/chmod。写入后验证哈希和权限，失败时尝试恢复本次已更新文件。要求已导入文件与 Rime 根目录所有者及组一致且 ADB 可写；如果缺少文件或权限不符，整批更新在写入前停止，并提示先用 DocumentsUI 导入。不会覆盖用户词库、build 或安装状态，也不自动重载输入法；完成后在手机点一次重新部署。支持 `--from-dir <已导出目录>` 和 `--serial <ADB设备>`，不需要额外 APK。


全拼与小鹤默认开启部件拆字反查和部件辅码，统一使用反引号：开头输入反引号后加部件拼音查字，例如全拼 `` `riyue ``、小鹤 `` `riyt `` 均查“明”；已有拼音后加反引号及部件筛选候选，例如全拼 `` shi`mu ``、小鹤 `` ui`mu `` 筛选“柿”。全拼使用 `radical_pinyin`，小鹤使用 `radical_pinyin_flypy` 的独立拼写索引，共用同一部件词典；这两个辅助方案不加入 F4 的主方案列表。候选置顶 `pin_cand_filter` 仍未启用。

四套方案以 `quick_input` 作为功能命令入口（桌面 `;`，手机 `\`），功能实现仍放在独立模块中：`;s` 切方案，`;o` 开关设置，桌面虎码 `;k` 开始 / 结束击键统计；日期时间、符号与私人短语由 `/` 统一输入。

功能总菜单、符号菜单、私人短语菜单、`;s` 方案菜单和 `;o` 设置菜单统一由 `lua/menu_selection.lua` 监听 Rime 的 `select_notifier` 执行动作。键盘空格、数字键只转换为原生候选选择；回车交给 editor 上屏原始编码，前端点选当前页或展开列表中的候选走同一套动作；普通汉字、日期及实际符号仍交给原生提交。`quick_input` 只保留入口、路径续写、退格返回、翻页等按键适配，不再另行提交菜单项或切方案。选择菜单项时暂缓名称上屏，完成原生选择后再跳转或提交；切方案、组件销毁时断开回调，避免重复处理。

`/` 打开逐级补全的符号菜单，每层候选注释只显示下一键，模糊结果只显示目标路径。可以直接追加字母进入下一层，也可以点选或用空格选择；只有一个实际值的叶条目选中即上屏，分类和多值条目继续进入下一层。子菜单内还可用数字选择，根目录数字用于 `/0` 到 `/10` 的直接查询。退格返回上一层。顶层按内容分类：`a` 箭头（arrows）、`m` 数学（math）、`l` 语言（languages）、`e` 表情（emoji）、`g` 棋牌运动（games）、`n` 自然（nature）、`w` 文字（writing）、`c` 货币（currency）、`u` 单位（units）、`k` 键盘符号（keyboard）、`v` 勾叉（verification），另有 `/d` 日期、`/t` 时间和 `/q` 私人短语。没有“常用符号”分类；原混合组中容易判断含义的符号已拆出或归入既有分类，剩余特殊标记留在末尾 `/o` 并显示预览。例如：

- `/a` 直接进入箭头，`/vc` / `/vx` 分别进入对号 / 错号。
- `/l` → `g`（Greek）得到 `/lg` 希腊字母；`G` 为大写。
- `/l` → `j`（Japanese）→ `h` / `k` 得到 `/ljh` 平假名 / `/ljk` 片假名。
- `/m` → `f`（fractions）得到 `/mf` 分数。

原混合组的明确入口包括 `/wl` 版权注册、`/wM` 商标、`/wS` 服务商标、`/p` 电话传真、`/r` 回收、`/j` 交通、`/i` 工具、`/s` 科学、`/hw` 警告、`/hm` 医疗、`/ha` 无障碍、`/nr` 宗教、`/nl` 地点、`/gj` 将棋、`/gC` 跳棋、`/gs` 运动、`/vb` 复选框、`/eF` 旗帜。天气、天文、方向手势、几何图形等补入既有分类。也可直接输入 `/phone`、`/copyright`、`/warning`、`/recycle` 等英文关键词查找。

子项优先使用英文助记键；多字母子项输入到一半仍显示匹配提示。候选先显示精确路径对应的字符 / 内容或当前层分类，再补全局英文模糊结果。例如 `/greek`、`/grk` 都能找到“希腊字母”，选择后进入 `/lg`；`/date`、`/time`、`/timestamp` 分别找到日期、时间、时间戳入口。模糊匹配检索路径及英文关键词，完整词、前缀和连续匹配优先，同一符号组不重复列出。中文名称只用于显示。英文关键词参与检索但不显示在注释中；实际符号和日期不再重复附加组名或命令清单，缩短横排候选框。

菜单条目的格式是 `{ "下一键", "显示名称", "数据键或子菜单", "英文关键词" }`；分组的默认关键词在同文件 `group_keywords`，日期映射仍由 `lua/date_commands.lua` 管理。常用组也保留独立短入口：

| 输入 | 符号组 |
| --- | --- |
| `/0` … `/10` | 对应数字的各种写法 |
| `/jt` / `/sx` / `/fs` | 箭头 / 数学 / 分数 |
| `/b` / `/bd` | 括号 / 标点 |
| `/hb` / `/u` | 货币 / 单位 |
| `/bq` / `/tq` / `/yy` | 表情 / 天气 / 音乐 |
| `/pk` / `/mj` / `/sz` | 扑克 / 麻将 / 骰子 |

完整符号表继续由 `symbols.yaml` 管理，`symbol_*` 为共享数据键，菜单路径集中在 `lua/symbol_menu.lua`；短入口引用同一份数据。拉丁字母变体在 `/lv`，其后追加原字母；数字直接用 `/0` 到 `/10` 打开对应变体，`/mn` 只保留一个去重后的数字总项；符号组按内容归类，没有明确归属的直接放在总菜单末尾并显示符号预览，不设“全部分类”。原 `;x` 及分号符号入口已移除。桌面四套方案均可用 `-` 上一页、`=` 下一页；拼音另保留 Tab / Shift+Tab 翻页，虎码 Tab 仍清屏。计算器中的减号保留为运算符。`;` 单独输入优先显示功能总菜单。

字母后加分号的快符保留，例如 `e;` 为 `（`、`t;` 为 `【`、`c;` 为 `→`；两个及以上字母后的分号仍二选。虎码 `z` 的重复末字固定二选，连打时优先取未上屏的前一个字，否则取上次提交的末字；`;` 和数字 `2` 都走原生选择。`jj`、`tt` 原样直出仅在小鹤双拼启用，全拼保留简拼。未分配的 `;字母` 仍可原样直出，所有快捷输入均受中文模式及修饰键保护。

四套方案的普通开关在当前 Rime 会话内保留，包括中英文、全半角、标点、Emoji、简繁、虎码读音 / 拆分 / Unicode 提示、简码提醒与记录。`quick_input` 初始化时调用 `schema_switch`，只设置一次首次默认值，切方案后不覆盖；`save_options: []` 不跨重启保存，也不写额外状态文件。桌面保留的同文键盘选项属于 Rime 内部临时选项，仍按方案初始化；手机版不生成这些选项。前端主动切换中英文或创建新会话时仍可能改变状态。

虎码保留 `echo_translator` 的字面候选，避免空码时候选框消失；不再输出 `◌` 或抑制连续空格。正常字词由原生组件提交；仅在选中候选中存在 `raw` 字面分段时，`quick_input` 调用 `tiger.commit_guard` 拦截空格、逗号和句号，丢弃未转换编码，提交连打中的有效分段。合法英文词条不受影响，显式数字选字仍可提交字面编码。

桌面虎码简码提醒与记录由独立 `tiger.simp_tracker` 处理，`simp_hint`、`simp_record` 两个开关默认开启，可在 F4 菜单中独立关闭。输入 `/simpstats` 查看多打编码次数最多的前 20 项。统计保存在 Rime 用户目录的 `tiger-simp-stats.tsv`，不纳入 chezmoi；只追加单字、实际编码、推荐简码、多按键数和时间，不记录整句。固定四码分段无法对应到单字的提交不统计；推荐表由同一生成器从常用字典提取一码、两码首选字，同字取最短编码；随上游码表更新，不提醒常用字集之外的生僻字。通知通过后台 `notify-send` / `osascript` 发出，尚无冷却或合并；文件追加仍在输入线程执行，统计是多打事件次数，并非包含所有输入的错误率。

生成缓存位于 chezmoi 缓存目录的 `rime-tiger/` 中（跟随 `--cache`），只在上游词典或 helper 内容变化时重建；缓存损坏会重建，并发写入采用原子替换。本地扩展词典由模板单独渲染，修改它无需重新生成基础常用字词典。缓存命中时只读取词典并计算指纹，不解压或压缩。

常用方案不再运行常用字 Lua 过滤器；原来的字集开关和 `Ctrl+h` 字集快捷键已移除，改用 `F4` 或 `;s` 切到全字集。保留编码补全，部分短码的补全候选顺序会与旧过滤方式不同。

`chezmoi diff` / `cat` 不会替 Git external 执行 pull，预览使用本地已有的上游版本。首次使用（或只 apply 输入法子目录之前），先准备上游 checkout；需要预览远端新版本时也可以这样更新：

```bash
chezmoi apply --refresh-externals=always ~/.cache/rime-tiger/upstream ~/.cache/rime-ice/upstream
chezmoi diff ~/.local/share/fcitx5/rime
```

确认后按正常流程应用；也可直接完整 `chezmoi apply`，先更新上游再生成词典。需要提前安装 Git 和 `python3`。删除上游目录后需要重新 clone；没有 checkout 时词典模板会报错，不会静默生成空词典。离线时可从现有 checkout 预览或单独应用输入法目录；刷新 Git 上游需要网络。

此机制用于仓库管理的 Linux / macOS Fcitx5 Rime 目录，不写入鼠须管的 `~/Library/Rime`，不会自动重启或重新部署输入法。

重新部署：

```bash
fcitx5-remote -r
```

macOS 使用 Fcitx5.app 时，`~/.local/bin/fcitx5-remote` 是到 app 内二进制的 symlink，仅在 macOS 启用输入法配置时生成。Linux 使用系统安装的 `fcitx5-remote`，不生成此链接。旧配置已在 Linux 留下的链接不会因 ignore 规则自动删除。Linux 用户需手动清理：先用 `readlink ~/.local/bin/fcitx5-remote` 确认目标为 `/Library/Input Methods/Fcitx5.app/Contents/bin/fcitx5-remote`，再运行 `unlink ~/.local/bin/fcitx5-remote`；保留自己安装的程序或 wrapper。

## Proxy And Network

配置共享由 `configShare` 控制，Linux 使用 `config-share.service`，macOS 使用 `config-share` LaunchAgent。`chezmoi init` 的允许客户端 CIDR 默认为 `127.0.0.1/32`，输入为空也使用此值，仅允许本机访问。允许局域网访问时填写实际网段，例如 `192.168.1.0/24`；网段的主机位必须为零，`127.0.0.1/24` 等输入会被拒绝。已有非空配置会保留，需自行修改。

Mihomo 配置在 `dot_config/mihomo/config.yaml.tmpl`：

- 订阅 URL 通过 gopass secret 注入
- Fudan、广告、AI、Apple、Bilibili 等规则 provider
- Linux 通过 user service 或手动启动
- macOS LaunchAgent 直接启动 Mihomo


Geo 使用与 Zsh 相同的 `downloads.preferChezmoi` 选项：

| 设置 | Geo 数据的下载与更新 |
| --- | --- |
| `true`（默认；旧配置缺少该字段时也按 true） | chezmoi external 管理 `GeoIP.dat`、`GeoSite.dat`、`Country.mmdb`，24 小时刷新，使用镜像回退；关闭 Mihomo 自动更新 |
| `false` | external 不声明 Geo 文件；Mihomo 按 `geox-url` 自行下载，并每 24 小时自动更新 |

不再使用专用 Geo 下载 helper、manifest 或启动包装。HTTP 403 等下载错误由 external 按 HTTP 状态处理；`chezmoi apply --keep-going` 可继续其他目标，最终保留失败状态。切换模式不会主动删除已有数据库，复制配置时也可把已有数据库一起复制。

Mihomo 的原生下载不保证使用安装 shell 的 `http_proxy` / `https_proxy`。首次安装需要临时局域网 HTTP 代理下载 Geo 时，使用默认的 chezmoi 模式；选择软件自管模式后，external 完全不下载 Geo，apply 的资源维护脚本调用 `mihomo -t` 让它自行初始化，不偷偷切回 external。临时代理地址只属于安装入口的进程环境，不写入 `geox-url` 或日常代理设置。

Hammerspoon 另有官方收录的 [SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html)，它自身也是需先安装的 Spoon，`hs.loadSpoon()` 只负责加载。当前只使用两个 Spoon，继续由 external 中的小循环管理，暂不为了模式切换再引入管理器。

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
