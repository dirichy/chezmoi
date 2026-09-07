# Dotfiles 审查报告

审查日期：2026-08-27

## 审查范围与方法

我对仓库中除 `.git/` 内部对象以外的文件进行了逐项清点和阅读，覆盖 Chezmoi 模板、Shell/Zsh 脚本、Lua、Python、JSON、TOML、YAML、系统服务文件、Neovim、Hyprland、Hammerspoon、Karabiner、Rime、mpv、yazi、tmux、Waybar 和 wmux 等目录。当前清点到 354 个文件，其中 Lua/Luaa 144 个、Shell 29 个、JSON/JSON 模板 40 个；PNG 等二进制文件无法按文本逐行阅读，因此检查了文件类型、尺寸和它们在配置中的引用关系。

下面的“问题”指已经从代码或配置中能够直接推断出的缺陷；“风险”指需要结合目标机器或运行时才能最终确认的行为。

## 后续改动状态

本报告之后已经完成的相关改动：

- `gopass-safe` 已移至 `tools/gopass-safe`，并更新 Chezmoi 模板调用路径及忽略规则。
- 旧 `kmap` 目录已删除，公共窗口、workspace、应用启动和截图绑定已迁移到 `wmux`。
- wmux 的 Hyprland backend 已支持应用条件、优先级分派和 `createmod` 的 fallback modifier；Karabiner、Hammerspoon、Hyprland 和 keyd backend 使用统一绑定 API。
- `Alt+a/c/v/x` 和终端 `Alt+n` 已移到 `dot_config/hypr/shortcuts.lua`，由 Hyprland 与 keyd 配置共同使用。
- warning 已改为写入 `$XDG_STATE_HOME/wmux/warnings.log` 或 `$HOME/.local/state/wmux/warnings.log`，不再写入 stderr。
- Hyprlua 旧目录、TCP IPC、systemd 服务和命令已删除；因此下列直接针对旧 Hyprlua IPC/初始化/事件总线的条目已通过移除旧实现解决。Waybar 的 Hyprlua 亮度 backend、Sunshine 调用和 Neovim 残留调用也已切换或删除。

以下条目仍然是待处理问题。

## 中优先级问题与条件性风险

### 1. keyd 配置需要确认运行时接入方式

文件：`dot_config/hypr/keyd.lua:8-12`、`dot_config/hypr/hyprland.lua`、`README.md` 的相关说明

`keyd.lua` 现在已使用 wmux 的 keyd backend，并通过 `window.active` 动态执行 `keyd bind reset`。它仍不是 Hyprland 主配置自动加载的模块，必须确认 keyd 服务或启动脚本实际加载 `keyd.lua`；同时应区分静态 `default.conf` 和运行时 `keyd bind` 生成的绑定格式，不能直接把运行时输出当作静态配置语法。

### 1. 安装脚本启用的服务与仓库内容不完全对应

文件：`run_onchange_after_install-packages-archlinux.sh.tmpl` 的 `module_desktop`、`dot_config/systemd/user/`

Arch 安装模块会启用 `hyprpaper`、`hypridle`、`waybar` 等用户服务，但仓库中没有对应的 service 文件，行为依赖系统包是否提供同名 unit。若这些服务是刻意依赖发行版提供，应在脚本中先检测 unit 是否存在并给出清晰提示；若由本仓库管理，则应补充启用逻辑。空的 `module_proxy()` 也被 profile 调用，容易让人误以为代理依赖已经安装。

### 1. 外部资源缺少完整性校验

文件：`.chezmoiexternal.toml:1-45`

Rime 大压缩包、Spoon 和 `fdu-connect` 都依赖网络外部资源，但没有看到对应的 checksum。外部资源被替换或上游内容变化时，部署结果可能无法复现。建议固定版本、记录 checksum，并确认 `ghfast.top` 这类镜像是必要依赖。

### 1. README 与实际仓库状态有漂移

文件：`README.md` 的命令、秘密变量和安装脚本说明；`.chezmoiignore`

已发现两类不一致：

- README 的 Local Commands 列出了 `hyprmonitor`、`tencentqq`，但当前文件清单中没有对应可执行文件。
- README 的 secret 列表没有提到 `dot_config/mihomo/config.yaml.tmpl` 使用的 `maimaiSSpassword`。

## 其他维护性问题

### 注释和遗留标记

`dot_config/tmux/tmux.conf` 中保留了多条 TODO、BUG 和“need test”注释，且后面又有第二组状态栏主题设置覆盖前面的 TokyoNight 设置。建议删除已完成的 TODO，未完成项写成 issue 或明确的测试条件，并合并最终生效的主题配置。

### 依赖与可移植性

多个模块直接写死二进制路径，例如 `/usr/bin/ddcutil`、`/opt/homebrew/bin/socat`、`/usr/local/bin`、`python`、`zen || zen-browser`。建议在启动时探测命令路径，并把“必须存在”和“可选功能”区分开。当前 Arch/macOS 两套安装脚本中也有重复包：macOS 的 `module_shell` 重复安装 `yarn npm`，`module_extra` 和 `module_desktop` 分别安装 `tailscale` 与 `tailscale-app`，应确认是否确实需要两个不同目标。

Rime 中的天文、农历、时间和候选词相关文件体积较大，部分明显属于外部/第三方代码。建议记录来源、版本、许可证和本地改动边界；否则将来升级时很难判断哪些修改是本仓库自己的。

## 建议重构的方向

1. 将显示器、默认应用、服务启用状态放入 Chezmoi host data，Lua/Shell 只读取配置，不在模块中散落硬编码。
1. 统一 Shell 脚本的错误处理、临时目录、日志和命令探测约定；对外部输入全部使用数组或显式参数，不使用 `eval`。
1. 将生成型 Karabiner/wmux 文件区分为“源”和“产物”，提供单一生成入口；或者完全改为部署时生成，避免源和产物长期漂移。
1. 对 Rime 外部代码做 vendored 管理：添加来源清单和升级说明，自己的小型 translator/filter 与第三方算法文件分开。

## 可以增加的功能

1. 增加一个只读自检命令，例如 `bin/dotfiles-check`，执行 `chezmoi execute-template`、Shell/Zsh/Lua/Python 语法检查、JSON/TOML/YAML 校验和外部命令依赖检查。
1. 增加 CI 或 pre-commit：`shellcheck`、`shfmt --diff`、`stylua --check`、`luacheck/selene`、JSON 格式校验，并在 CI 中验证生成文件没有未提交差异。
1. 增加 host profile 示例，覆盖笔记本/桌面、显示器和可选服务；新机器可以从 profile 选择，而不是手工删环境变量。
1. 增加 secrets 审计命令，检查模板中所有 `.chezmoi.password`、`gopass` 和 secret data key 是否都有 README 说明，同时禁止把渲染后的密钥文件写入仓库。
1. 对 brightness、workspace、输入法、窗口焦点等跨进程功能增加最小集成测试或 dry-run 模式，至少覆盖“工具不存在”“返回空 JSON”“显示器不存在”和“服务未启动”。
1. 给生成的 JSON 和外部资源增加来源/版本元数据，便于在 Chezmoi 更新后追踪变化。

## 建议补充注释的地方

- `dot_config/hypr/hyprland.lua`：解释全局 `print` 重载、按 workspace 切换壁纸和输入法初始化状态的设计取舍。
- `dot_config/hypr/window_focus_guard.lua`：说明打开短暂 wofi 窗口是为哪些应用解决焦点问题，以及 `timeout`、wofi 和目标窗口不存在时的行为。
- `dot_config/waybar/scripts/executable_ddcutil.sh`：写明 `ddcutil`/`brightnessctl` backend 的接口契约、亮度值单位和显示器不可用时的降级行为。
- `dot_config/tmux/executable_yank.sh`、`executable_fzfp.sh`：说明远端剪贴板和 tmux popup 临时文件的生命周期，以及为什么某些 backend 需要管道。
- `.chezmoi.toml.tmpl`、`.chezmoiexternal.toml`：列出每个 data key 的来源、是否敏感、默认值是否允许为空，以及外部资源的版本/校验方式。
- 生成的 Karabiner JSON、Rime 第三方 Lua、yazi readonly theme：加来源或“generated/vendor，勿手改”的短注释，减少误修改。

## 已执行的验证

- Shell 脚本执行 `bash -n`：通过。
- Zsh 脚本执行 `zsh -n`：通过语法解析。
- Python 文件执行编译检查：通过。
- JSON 文件逐个解析：通过。
- Lua 文件执行 `luac -p`：通过。
- Git 工作区检查：当前 wmux/keyd 相关文件包含后续迁移改动；本报告本身只记录问题和状态，不应被当作这些实现的测试证明。
