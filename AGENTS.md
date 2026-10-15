# AGENTS.md

本文件适用于整个仓库。这里是一个由 chezmoi 管理的跨平台 dotfiles source directory，主要支持 Arch Linux/Hyprland 和 macOS。修改前先阅读相关文件及 `README.md`，保持现有结构和平台条件，不要把它当作普通应用仓库。

## 基本原则

- 直接修改仓库中的 chezmoi source 文件，不要修改真实 `$HOME` 下的生成文件。
- 除非用户明确要求，不要运行 `chezmoi apply`，也不要 reload/restart 用户正在使用的桌面、shell 或服务。
- 允许使用隔离临时目录执行渲染和测试；不得让测试写入真实 home、真实 chezmoi state 或真实配置目录。
- 工作区可能已有用户修改。只改任务相关文件，不要覆盖、回退、格式化或删除无关改动，除非用户明确要求。
- 不要提交真实姓名以外的新个人信息、token、密码、订阅地址、服务器地址、设备标识或其他 secret。需要 secret 时使用现有 `secret` 模板机制和无害默认值。
- 不要为了测试联网下载 `.chezmoiexternal.toml` 中的资源。测试 fixture 应关闭相关 external，或使用 `--refresh-externals=never`。
- 对于在沙箱中不方便执行的命令，需要请求权限时，尽量一次性执行完，只请求一次权限。必要时可以先写一个脚本，然后请求执行这个脚本的权限。
- 对于某些需要特定环境才在执行成功的命令，如需要桌面测试，或需要用包管理器安装时，可以先停下来请求用户执行好，再继续。

## Chezmoi 命名和模板

- `dot_foo` 映射到 `.foo`。
- `private_`、`executable_`、`readonly_` 等前缀具有 chezmoi 属性语义，不要随意移除。
- `*.tmpl` 是 Go template。修改时同时考虑模板渲染结果，而不只是源文件文本。
- `.chezmoi.toml.tmpl` 定义主机数据、profile、feature 和 app 开关。
- `.chezmoiignore` 根据 OS、`features.*` 和 `apps.*` 决定最终文件集合。
- `.chezmoiexternal.toml` 管理外部下载；新增资源时应使用稳定版本，能提供校验值时应固定校验值。
- `.chezmoitemplates/` 存放可复用模板片段。已有公共逻辑应优先复用，避免复制条件表达式。
- 在`ignore/bin`下面有一些shell helper，在写比较复杂的shell逻辑时可以参考实现。

修改 profile、feature、app 或平台条件时，应一起检查：

1. `.chezmoi.toml.tmpl` 中的数据推导；
2. `.chezmoiignore` 中的包含/排除规则；
3. `.chezmoiexternal.toml` 中的下载条件；
4. 安装脚本中的依赖；
5. `ignore/tests` 中对应的行为断言和 fixture。

## 仓库布局

- `dot_config/hypr/`、`dot_config/waybar/`：Linux/Hyprland 桌面配置。
- `dot_hammerspoon/`、`dot_config/private_karabiner/`、`private_Library/`：macOS 配置。
- `dot_config/nvim/`、`dot_config/tmux/`、`dot_config/zsh/`、`dot_config/yazi/`：跨平台终端工具配置。
- `dot_local/bin/`：安装到 `~/.local/bin` 的用户命令。
- `scripts/lua/wmux/`：跨窗口管理器的 Lua 键位和行为抽象。
- `run_onchange_after_install-packages-*.sh.tmpl`：平台依赖安装脚本。
- `ignore/`：保留在仓库中、但不部署到 home 的辅助文件与测试。

新增平台专用文件时，必须确认另一个平台会通过 `.chezmoiignore` 排除它。默认假设 Linux 是 Arch Linux + Hyprland + systemd user services，macOS 是 Apple Silicon + Homebrew，但不要无意中破坏其他 Linux profile。

## 验证要求

完成配置修改后，默认运行：

```bash
./ignore/tests/test.sh
```

该测试使用独立的 destination、cache 和 persistent state，不会修改真实 home。它验证 Linux `desktop`、`headless`、`skip` 的管理文件集合、模板渲染以及 Shell/Lua 语法。

根据改动类型补充以下检查：

- Shell：对非模板文件运行 `bash -n`；若已安装 `shellcheck`，再运行 ShellCheck。
- Lua：运行 `luac -p`；涉及 Neovim 行为时，可在隔离环境下使用 `nvim --headless`。
- JSON/JSONC、YAML、TOML：先渲染模板，再使用对应解析器检查产物。
- Waybar 或其他模板：使用固定 fixture 渲染，不依赖当前机器的实时桌面状态。
- macOS 专用改动：当前 Linux 环境无法完整验证时，明确说明尚未验证的部分，不要假装已通过。

如果修改改变了某个 profile 应生成的关键文件，应在 `ignore/tests/test.sh` 添加或更新 `assert_managed` / `assert_ignored`。如果增加测试数据，放在 `ignore/tests/fixtures/`。

如果修改和配置完全无关，比如加一个小工具，或者是做可行性验证而不是最终版本，可以先不跑测试，等收敛再一起测试。

## 修改风格

- 保持现有文件的语言、缩进、注释和组织方式；不要做与任务无关的大范围格式化。
- 优先做小而明确的改动。跨平台公共行为放到共享层，平台差异留在对应目录或条件模板中。
- Shell 脚本使用安全引用，新增脚本通常应启用 `set -euo pipefail`，但不要机械地加入会破坏现有容错逻辑的选项。
- 外部命令可能不存在。可选集成应先检测命令是否可用，并提供合理 fallback。
- 配置中的命令、路径和服务名发生变化时，同步更新附近注释和 `README.md` 中相关说明。
- 如果你认为目前你负责的部分有内容需要加到tests中或AGENTS.md中，可以向用户提出键议，在获得允许后执行。

## 完成任务时

- 简要说明修改了什么以及影响哪些平台/profile。
- 列出实际执行的验证命令和结果。
- 明确指出由于缺少平台、程序或外部服务而未验证的部分。
- 不要自行 commit、push、安装系统包、下载大型外部资源或应用配置，除非用户明确要求。
