# Hyprlua 迁移与 Chezmoi 改进方案

日期：2026-08-27

## 目标

以 `dot_config/hypr/hyprland.lua`、`dot_config/hypr/shortcuts.lua` 和 wmux 的 Hyprland backend 为新的 Hyprland Lua/键位入口，完整替代已经弃用的 `dot_config/hypr/hyprlua/` 和 `hyprlua` IPC 命令。旧 Hyprlua 目录、旧服务和旧命令已经删除；当前仍需处理少量残留调用和行为差异。

迁移原则：残留外部调用应切换到稳定的 Shell/`hyprctl` 接口，避免用新的任意代码执行接口替代旧的任意代码执行接口。

## 一、功能差异清单

### 已经在 `hyprland.lua` 中覆盖的功能

| 旧功能 | 当前实现 | 结论 |
| --- | --- | --- |
| Hyprland 基础配置、窗口规则 | `hl.config`、`hl.window_rule` | 已覆盖 |
| Super+h/j/k/l 窗口焦点移动 | `wmux.wm.hyprland.focus` | 已迁移，仍需真实会话回归边界和跨 workspace 行为 |
| Super+Shift+h/j/k/l 交换窗口 | `wmux.wm.hyprland.swap_win` | 已迁移，仍需真实会话验证 |
| Super+q/f/v 关闭、全屏、浮动 | `wmux.wm.hyprland` | 已迁移 |
| Super+数字切换 workspace | `wmux.wm.hyprland.move_to_space` | 已迁移 |
| Super+Shift+数字移动窗口 | `wmux.wm.hyprland.move_win_to_space` | 已迁移 |
| 应用启动快捷键 | `wmux.applauncher` + `executable_wmux.lua` | 已迁移；仍需检查目标机器上的应用命令 |
| 输入法的窗口级状态 | fcitx `ShareInputState=No` + Hyprland 初始激活 | 已改由 fcitx 自己管理焦点状态 |
| workspace 切壁纸 | `workspace.active` | 已覆盖，需要增加壁纸不存在时的处理 |
| Sunshine 模块 | `require("sunshine")` + `hyprctl eval` | 已切换到 native Hyprland Lua 入口 |
| 显示器初始缩放 | `require("monitor").setup()` | 已覆盖，但缩放表重复且配置名有拼写问题 |
| DPMS 开关 | `sys_keymap.d/c` | 已覆盖，亮度控制与 DPMS 应拆开 |
| Esc+1/2 截图 | wmux `createmod` + Hyprland fallback modifier | 已迁移；Hyprland 接收 `Ctrl+Shift+Alt+1/2`，仍需真实会话验证 |
| `window_focus_guard` | 直接 require | 已覆盖 |

说明：`dot_local/bin/executable_sunshine_pre` 已经是当前 Sunshine 显示器切换入口，不再经过旧 `hyprlua` 命令。

### wmux 当前相对旧 Hyprlua/当前 `hyprland.lua` 的差异

文件：`scripts/lua/executable_wmux.lua`、`scripts/lua/wmux/bind/hyprland.lua`、`scripts/lua/wmux/wm/hyprland.lua`

wmux 已经覆盖：Super 窗口/工作区焦点、Super+Shift+数字移动窗口、Super+Shift+h/j/k/l 交换窗口、Super+q/f/v、应用启动和 Esc+数字截图，并提供跨平台的 wm/binder 抽象。`hyprland.lua` 已通过 `require("wmux")` 使用公共绑定；Linux 专用的系统键和条件快捷键留在 Hyprland 配置侧。

wmux/Hyprland 仍缺少或未完成的部分：

- Linux 专用的系统快捷键仍在 `hyprland.lua`，尚未迁入 wmux；这是有意保留的平台边界，不属于公共 API 缺失。
- keyd backend 已实现动态条件重绑定，但静态 `default.conf.tmpl` 与运行时 `keyd bind` 的配置格式仍需明确整合方式。
- wmux Hyprland backend 有 `toggle_pin`、`rotate_space` 空实现；它们不是旧 Hyprlua 当前使用的功能，可以明确标记为未支持。

当前结构已经按此原则拆分：`hyprland.lua` 加载 wmux，`shortcuts.lua` 保存 Linux 专用的条件快捷键，公共窗口/workspace/app 绑定在 `executable_wmux.lua`。

#### 2. 输入提示与剪贴板注入

旧文件：`dot_config/hypr/hyprlua/system/input.lua`

该模块提供 wofi prompt，把输入结果写入 `wl-copy` 后模拟 Ctrl+v。它的用途是给不支持输入法的应用输入中文，虽然当前没有静态调用者，但不能仅因未被 `rg` 找到就判定为无用。建议迁移成独立、手动开启的 `features/text_input.lua`：保留 wofi 输入、剪贴板写入和目标窗口粘贴三步，用 native Lua 的 `hl.exec_cmd` 或专用 helper 管理异步进程；为需要它的应用绑定显式快捷键，并处理 wofi、wl-copy、目标应用不存在的错误。确认新功能工作后再删除旧 `system/input.lua`。

## 二、推荐实施顺序

### 阶段 0：建立迁移清单和测试基线

新增一个临时或正式的自检命令，至少能验证：

- `hyprland.lua` 加载无 Lua 语法错误。
- Hyprland 启动后关键事件能够触发。
- 每个快捷键可以在目标应用和普通应用下分别验证。
- `hyprctl monitors -j`、`hyprctl clients -j`、`fcitx5-remote`、`ddcutil` 不可用时有可读错误。
- `executable_sunshine_pre` 的现有 start/stop 工作流能够正常运行。

测试结果按“通过/不适用/失败”记录，避免后续清理时遗漏个人工作流。

### 阶段 1：补齐 `hyprland.lua` 的功能

建议新增小模块，避免继续把所有逻辑堆在一个文件中：

- `dot_config/hypr/features/keybindings.lua`：窗口方向、条件发送键、应用启动。
- `dot_config/hypr/features/wallpaper.lua`：workspace 壁纸和 debounce。

`hyprland.lua` 只负责配置加载、模块 require 和全局启动钩子。所有模块使用 native Hyprland Lua API；需要外部执行的动作通过受控 Shell helper 完成。

### 阶段 2：切换所有外部调用点

按以下顺序替换：

1. `dot_config/sunshine/apps.json`、README、systemd 服务和所有脚本删除废弃的 `hyprlua` 文案与路径。
2. 重新执行 Shell/Zsh/Lua/Python/JSON 配置检查，并在真实 Hyprland 会话中完成一次全量快捷键和 Sunshine 回归。

## 三、其余真实问题的具体改进方案

### 1. 外部资源可复现性

修改 `.chezmoiexternal.toml` 的管理方式：固定版本、增加 checksum、记录来源和刷新策略；删除过期长 URL 注释。对 Rime 大压缩包写清楚上游版本和本地补丁，避免更新时覆盖个人修改。

### 2. 安装脚本

统一两个 `run_onchange_after_install-pacakges-*.sh.tmpl` 的命名为 `...packages...`，迁移时确认 Chezmoi 的 run-on-change hash 行为并手动执行一次。随后：

- 删除空的 `module_proxy`，或真正实现代理依赖安装。
- 为 AUR 临时目录增加 `trap` 清理。
- 安装/启用服务前检测 unit 是否存在。
- 去除 macOS 重复包和 `tailscale`/`tailscale-app` 的歧义。

### 3. 路径与主机配置

将显示器名称、Sunshine 分辨率、默认应用和服务开关放入 Chezmoi host data。模板生成时按 host profile 选择，避免仍需要手工修改机器相关配置。

### 4. Shell 安全和临时文件

把 tmux 中的 `eval` 改为数组和 `case`，修复 `session_switcher.sh` 的顶层 `return`，为 popup 临时文件使用 `mktemp`，把 debounce 锁放到 `${XDG_RUNTIME_DIR:-/tmp}/...-$UID`。

### 5. 配置一致性

修正 tmux `C-e` 的 source 路径；修正空 JSON 文件；同步 README 的 secret 列表、Local Commands 和服务说明。生成的 Karabiner JSON 使用稳定格式化，并在文件头标明生成来源。

### 6. 错误处理和日志

将 Hyprland、Hammerspoon、Rime 中的调试输出放到统一 debug 开关下，正常启动不应向通知栏或控制台打印大量内部事件。

### 7. 命名与第三方代码

单独做一次不改变行为的拼写清理：`pacakges`、`applaucher`、`debuger`、`editer`、`Recongize`、`joncon`、`vitualA`、`prefered` 等。对 Rime、yazi theme 和 Karabiner 生成物增加来源、版本、许可证和“勿手改”说明。

## 四、最终删除检查表

- [x] `hyprland.lua` 已切换到 wmux，并实现基础窗口/workspace/应用快捷键。
- [x] wmux Hyprland backend 已支持 application conditions、优先级分派和 fallback modifier。
- [x] Alt+a/c/v/x、终端 Alt+n 已通过共享的 `shortcuts.lua` 接入；仍需真实应用回归。
- [x] `hyprland.lua` 已实现旧的应用鼠标侧键。
- [x] Neovim/Hyprland 方向键联动已决定不再保留，相关 Neovim 模块已删除。
- [x] 输入法已改由 fcitx 自己管理焦点状态，Hyprland 只负责部分初始激活逻辑。
- [x] Waybar 不再探测或调用 `hyprlua`。
- [x] Sunshine 场景脚本已改用 `hyprctl`，`executable_sunshine_pre` 继续使用原生 `hl.sunshine`。
- [x] Neovim 不再执行 `hyprlua` 字符串。
- [x] `rg` 搜索不到运行时 `hyprlua` 调用，只剩迁移文档和审查记录。
- [x] `hyprlua.service`、IPC server、旧命令和旧目录已删除。
- [x] `gopass-safe` 已移动到 `tools/gopass-safe`，且 Chezmoi 忽略规则已同步；仍需在完整 Chezmoi data 环境中验证 secret 模板。
- [x] keyd backend 已加入 wmux，并支持动态窗口条件绑定；仍需确认 keyd 服务实际加载 `dot_config/hypr/keyd.lua`。
- [ ] Shell、Zsh、Lua、Python、JSON 校验通过；当前 Lua 检查需排除 Chezmoi 用的 `symlink_wmux.lua` 伪 Lua 文件，并继续处理仓库原有的 Lua 5.4 检查问题。
- [ ] 在至少一次真实 Hyprland 会话中完成快捷键、输入法、亮度、壁纸、Sunshine 和窗口规则回归测试。
