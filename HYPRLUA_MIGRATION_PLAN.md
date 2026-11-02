# Hyprlua 迁移与 Chezmoi 改进方案

日期：2026-08-27

#### 2. 输入提示与剪贴板注入

旧文件：`dot_config/hypr/hyprlua/system/input.lua`

该模块提供 wofi prompt，把输入结果写入 `wl-copy` 后模拟 Ctrl+v。它的用途是给不支持输入法的应用输入中文，虽然当前没有静态调用者，但不能仅因未被 `rg` 找到就判定为无用。建议迁移成独立、手动开启的 `features/text_input.lua`：保留 wofi 输入、剪贴板写入和目标窗口粘贴三步，用 native Lua 的 `hl.exec_cmd` 或专用 helper 管理异步进程；为需要它的应用绑定显式快捷键，并处理 wofi、wl-copy、目标应用不存在的错误。确认新功能工作后再删除旧 `system/input.lua`。
