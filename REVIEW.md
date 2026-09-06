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

以下条目仍然是待处理问题，除非明确标注“已解决”，不能视为已经修复。

## 高优先级问题

### 1. 两个 Rime Lua 文件无法通过 Lua 5.4 语法检查

文件：`dot_local/share/fcitx5/rime/lua/cn_en_spacer.lua:25`、`dot_local/share/fcitx5/rime/lua/executable_search.lua:24`

使用系统 `luac` 检查时分别出现“attempt to assign to const variable `cand`”和“attempt to assign to const variable `i`”。Lua 5.4 中泛型 `for` 的循环变量不可重新赋值；如果当前 Rime 使用的 Lua 版本也是 5.4，这两个文件会直接加载失败。若 Rime 固定使用 5.3，则应在 README 或配置说明中明确这一运行时约束，并在 CI 中使用同版本解释器检查。

## 中优先级问题与条件性风险

### 2. keyd 配置需要确认运行时接入方式

文件：`dot_config/hypr/keyd.lua:8-12`、`dot_config/hypr/hyprland.lua`、`README.md` 的相关说明

`keyd.lua` 现在已使用 wmux 的 keyd backend，并通过 `window.active` 动态执行 `keyd bind reset`。其中 `vitualA` 等名称与现有 keyd 配置保持一致，属于既有层名称拼写，不应单独改名。它仍不是 Hyprland 主配置自动加载的模块，必须确认 keyd 服务或启动脚本实际加载 `keyd.lua`；同时应区分静态 `default.conf` 和运行时 `keyd bind` 生成的绑定格式，不能直接把运行时输出当作静态配置语法。

### 3. tmux 辅助脚本过度依赖 `eval`

文件：`dot_config/tmux/executable_yank.sh:35`、`dot_config/tmux/executable_fzfp.sh:17-19,28-33,57-59`

剪贴板后端字符串和 fzf 的宽高参数都通过 `eval` 执行。部分值来自 tmux option 或调用者参数，当前实现扩大了命令注入和参数拆分的可能性。建议使用 Shell 数组、明确的 `case` 分支和 `printf '%q'`，避免把字符串重新解释为 Shell 代码。`fzfp.sh` 还应检查 `--height`、`--width` 是否缺少值，并用 `mktemp` 创建唯一临时文件。

### 4. session switcher 在脚本顶层使用 `return`

文件：`dot_config/tmux/executable_session_switcher.sh:7-14`

这是一个可执行的 Zsh 脚本，不是明确被 source 的函数文件。顶层 `return` 在不同调用方式下可能报错；这里应使用 `exit 0`，并给目标 session 加引号以避免名称中出现特殊字符时被拆分。

### 5. 安装脚本启用的服务与仓库内容不完全对应

文件：`run_onchange_after_install-pacakges-archlinux.sh.tmpl` 的 `module_desktop`、`dot_config/systemd/user/`

Arch 安装模块会启用 `hyprpaper`、`hypridle`、`waybar` 等用户服务，但仓库中没有对应的 service 文件，行为依赖系统包是否提供同名 unit。若这些服务是刻意依赖发行版提供，应在脚本中先检测 unit 是否存在并给出清晰提示；若由本仓库管理，则应补充启用逻辑。空的 `module_proxy()` 也被 profile 调用，容易让人误以为代理依赖已经安装。

### 6. 外部资源缺少完整性校验，且仓库保留了已过期的长 URL 注释

文件：`.chezmoiexternal.toml:1-45`

Rime 大压缩包、Spoon 和 `fdu-connect` 都依赖网络外部资源，但没有看到对应的 checksum。外部资源被替换或上游内容变化时，部署结果可能无法复现。建议固定版本、记录 checksum，并确认 `ghfast.top` 这类镜像是必要依赖。文件中的 GitHub release-assets URL 注释带有 2026-03-02 的过期时间，在当前审查日期已失效，建议删掉或改为简短的来源说明。

### 7. README 与实际仓库状态有漂移

文件：`README.md` 的命令、秘密变量和安装脚本说明；`.chezmoiignore`

已发现三类不一致：

- README 的 Local Commands 列出了 `hyprmonitor`、`tencentqq`，但当前文件清单中没有对应可执行文件。
- README 的 secret 列表没有提到 `dot_config/mihomo/config.yaml.tmpl` 使用的 `maimaiSSpassword`。
- 安装脚本文件名中的 `pacakges` 拼写错误同时出现在 README 和两个脚本名中。

### 8. 空文件被命名为 JSON

文件：`dot_config/nvim/empty_dot_luarc.json`

JSON 校验失败，原因是文件为空。若这是给 LuaLS 的占位文件，应改成合法的 `{}`，或改用能表达“刻意为空”的文件名/扩展名，并在相邻说明中解释用途。空 JSON 文件会让自动校验和编辑器诊断产生误报。

### 9. Hammerspoon/Karabiner 生成逻辑存在未启用、硬编码和明显拼写问题

文件：`dot_hammerspoon/init.lua`、`dot_hammerspoon/karabiner.lua`、`dot_hammerspoon/shottr.lua`、`dot_hammerspoon/space_as_modifier_for_number.lua`、`dot_hammerspoon/vlc.lua`、`dot_config/private_karabiner/`

- `init.lua` 中 `karabiner`、`vlc`、`loop` 等模块被注释掉，但生成文件仍在仓库中，当前启用边界不清晰。
- Karabiner 生成器硬编码 `/Users/dirichy/.config/karabiner/...` 和 `/usr/local/`、`/opt/homebrew/bin`，迁移用户或 Intel/Apple Silicon 环境时会失效。
- `dot_hammerspoon/karabiner.lua` 中存在 `conditionsdatory`、`midifiers` 等字段拼写，且 `M.write` 生成了 manipulators 后没有继续写入文件，像是未完成或废弃代码。
- Shottr 相关文本使用 `Recongize`，变量名使用 `applaucher`；VLC/手柄相关代码使用 `joncon`，应统一为 `Recognize`、`app_launcher`、`Joy-Con`。如果这些字符串对应应用菜单项，拼写错误可能直接导致菜单点击失败。
- `dot_hammerspoon/vlc.lua:214` 在加载时打印完整 JSON；如果该文件未来重新启用，会污染 Hammerspoon 控制台。

建议把生成器与运行时模块分离，路径通过 `os.getenv("HOME")` 和可配置的二进制路径获取；生成前验证 JSON schema，并给生成文件加“不要手工编辑”的头部。

## 其他维护性问题

### 命名、注释和遗留标记

全仓库存在多处拼写或表述问题，例如 `pacakges`、`applaucher`、`debuger`、`editer`、`Nrotree`、`already binded`、`neec test`、`vitualA`、`prefered`。它们有些只是内部名字，有些会影响用户看到的菜单或匹配规则。建议在一次专门的命名清理中处理，不要在普通功能修改时零散更名，以免破坏 Chezmoi 的 `run_onchange` 触发条件或外部引用。

`dot_config/tmux/tmux.conf` 中保留了多条 TODO、BUG 和“need test”注释，且后面又有第二组状态栏主题设置覆盖前面的 TokyoNight 设置。建议删除已完成的 TODO，未完成项写成 issue 或明确的测试条件，并合并最终生效的主题配置。

### 依赖与可移植性

多个模块直接写死二进制路径，例如 `/usr/bin/ddcutil`、`/opt/homebrew/bin/socat`、`/usr/local/bin`、`python`、`zen || zen-browser`。建议在启动时探测命令路径，并把“必须存在”和“可选功能”区分开。当前 Arch/macOS 两套安装脚本中也有重复包：macOS 的 `module_shell` 重复安装 `yarn npm`，`module_extra` 和 `module_desktop` 分别安装 `tailscale` 与 `tailscale-app`，应确认是否确实需要两个不同目标。

Rime 中的天文、农历、时间和候选词相关文件体积较大，部分明显属于外部/第三方代码。建议记录来源、版本、许可证和本地改动边界；否则将来升级时很难判断哪些修改是本仓库自己的。

### 临时文件、日志和并发

`dot_config/tmux/executable_debounce.sh` 使用全局 `/tmp/tmux_debounce` 和固定日志文件。多用户环境可能互相影响，异常退出也可能留下锁。建议优先使用 `${XDG_RUNTIME_DIR:-/tmp}/...-$UID`，并用 `trap` 清理；日志应可通过选项关闭或进入系统日志。类似地，Waybar 和 Hammerspoon 中有较多启动时 `print`，建议增加统一 debug 开关。

### 生成文件与源文件关系

Karabiner 的多个 JSON 是单行生成结果，审查差异和定位规则都很困难。建议保留稳定格式化输出，并在 CI 中从 Lua 源重新生成后比较工作树。wmux、Hammerspoon 和 Karabiner 之间存在重复的“键位描述 -> 目标系统规则”转换逻辑，也适合以后抽成一个带平台后端的公共数据模型。

## 建议重构的方向

1. 将显示器、默认应用、服务启用状态放入 Chezmoi host data，Lua/Shell 只读取配置，不在模块中散落硬编码。
2. 将 Neovim 的超大插件配置文件，尤其是 `dot_config/nvim/lua/plugins/utils.lua`、`neotree.lua` 和 `luasnip.lua`，按功能拆成独立模块；每个插件只保留依赖、配置和键位，减少一次加载时的隐式副作用。
3. 统一 Shell 脚本的错误处理、临时目录、日志和命令探测约定；对外部输入全部使用数组或显式参数，不使用 `eval`。
4. 将生成型 Karabiner/wmux 文件区分为“源”和“产物”，提供单一生成入口；或者完全改为部署时生成，避免源和产物长期漂移。
5. 对 Rime 外部代码做 vendored 管理：添加来源清单和升级说明，自己的小型 translator/filter 与第三方算法文件分开。

## 可以增加的功能

1. 增加一个只读自检命令，例如 `bin/dotfiles-check`，执行 `chezmoi execute-template`、Shell/Zsh/Lua/Python 语法检查、JSON/TOML/YAML 校验和外部命令依赖检查。
2. 增加 CI 或 pre-commit：`shellcheck`、`shfmt --diff`、`stylua --check`、`luacheck/selene`、JSON 格式校验，并在 CI 中验证生成文件没有未提交差异。
3. 增加 host profile 示例，覆盖笔记本/桌面、显示器和可选服务；新机器可以从 profile 选择，而不是手工删环境变量。
4. 增加 secrets 审计命令，检查模板中所有 `.chezmoi.password`、`gopass` 和 secret data key 是否都有 README 说明，同时禁止把渲染后的密钥文件写入仓库。
5. 对 brightness、workspace、输入法、窗口焦点等跨进程功能增加最小集成测试或 dry-run 模式，至少覆盖“工具不存在”“返回空 JSON”“显示器不存在”和“服务未启动”。
6. 给生成的 JSON 和外部资源增加来源/版本元数据，便于在 Chezmoi 更新后追踪变化。

## 建议补充注释的地方

- `dot_config/hypr/hyprland.lua`：解释全局 `print` 重载、按 workspace 切换壁纸和输入法初始化状态的设计取舍。
- `dot_config/hypr/window_focus_guard.lua`：说明打开短暂 wofi 窗口是为哪些应用解决焦点问题，以及 `timeout`、wofi 和目标窗口不存在时的行为。
- `dot_config/waybar/scripts/executable_ddcutil.sh`：写明 `ddcutil`/`brightnessctl` backend 的接口契约、亮度值单位和显示器不可用时的降级行为。
- `dot_config/tmux/executable_yank.sh`、`executable_fzfp.sh`：说明远端剪贴板和 tmux popup 临时文件的生命周期，以及为什么某些 backend 需要管道。
- `.chezmoi.toml.tmpl`、`.chezmoiexternal.toml`：列出每个 data key 的来源、是否敏感、默认值是否允许为空，以及外部资源的版本/校验方式。
- 生成的 Karabiner JSON、Rime 第三方 Lua、yazi readonly theme：加来源或“generated/vendor，勿手改”的短注释，减少误修改。

## 已执行的验证

- Shell 脚本执行 `bash -n`：通过。
- Zsh 脚本执行 `zsh -n`：通过语法解析；`session_switcher` 的顶层 `return` 仍属于运行方式问题，静态语法检查不会捕获。
- Python 文件执行编译检查：通过。
- JSON 文件逐个解析：除刻意为空的 `dot_config/nvim/empty_dot_luarc.json` 外通过。
- Lua 文件执行 `luac -p`：发现上文列出的两个 Lua 5.4 const assignment 错误。
- Git 工作区检查：当前 wmux/keyd 相关文件包含后续迁移改动；本报告本身只记录问题和状态，不应被当作这些实现的测试证明。
