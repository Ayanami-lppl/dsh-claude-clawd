# V2 验收记录（真实 DSH）

日期：2026-10-19（Asia/Shanghai）
目标：DeepSeek Harness 0.2.1-rc.2
范围：仅 DSH；Codex 本轮不在范围内。

> 旧 `legacy-v1/ACCEPTANCE.md` 只证明旧独立浮窗，不能用于证明 V2。本文件是 V2 的记录。

## 真实客户端已验证

| # | 项目 | 结果 | 证据 |
|---|---|---|---|
| 1 | 是 DSH 界面内真实组件，而非独立浮窗 | **真实客户端已验证** | 注册到 `conversation.input.overlay`；旧 exe/快捷方式/进程已移除；见 `docs/evidence/v2-right-idle-composer.png` |
| 2 | 位于输入框右上沿，脚贴边 | **真实客户端已验证** | 小人脚底对齐 composer 外壳上边线，位于输入框右侧；截图 `v2-right-idle-composer.png` |
| 3 | 小巧尺寸 | **真实客户端已验证** | 56×40 CSS px 画布；角色身体约 36px；不再是旧版 128 DIP 浮窗 |
| 4 | 待机正面、无电脑、四短腿 | **真实客户端已验证** | `v2-right-idle-composer.png`；透明帧 `v2-assets/frames/idle.png` |
| 5 | 思考切侧身、灰线电脑出现 | **真实客户端已验证** | 右侧连续帧 7–11 为侧身，角色左前方灰色折线屏幕/底座；`v2-right-thinking-frames.png` |
| 6 | 敲击循环只动双手，电脑/脚底稳定 | **真实客户端已验证** | 侧身帧橙色 bbox 恒为 `x=72..113, y=58..85`；手部橙色像素数在 881/882/885 间变化；电脑和脚底基线不漂移 |
| 7 | 循环不夹正面帧 | **真实客户端已验证** | 侧身阶段帧 7–11 全部为同一侧身母版；正面帧从 12 才开始，属于退出思考 |
| 8 | 思考结束恢复正面且电脑消失 | **真实客户端已验证** | 帧 12 起因状态回 idle，小人恢复正面无电脑；`v2-right-thinking-frames.png` |
| 9 | 状态源为当前会话的前端实时流 | **真实客户端已验证** | 临时 `[PET:<phase>]` 标记来自 `ctx.sessions.binding(sessionId).eventSource` 的 `assistant/live-chunk`；真实序列 `thinking → tool → requesting → thinking…`，见 `docs/evidence/v2-phase-sequence.txt` |
| 10 | 不再使用标题前缀绑定 | **真实客户端已验证** | `sessionId` 来自 slot 标准 props；绑定取当前 Session 的 eventSource；旧 Host bridge/标题前缀代码已移除 |
| 11 | 旧 V1 独立浮窗迁移 | **真实客户端已验证** | V1 桌面/开始菜单快捷方式已删除；`%LOCALAPPDATA%\ClaudeKeyboardWidget\app` 已归档；`ClaudeKeyboardWidget.exe` 未运行 |
| 12 | 旧 V1 Host 桥接移除 | **真实客户端已验证** | `cordis.patch.yml` 中 `thinking-widget-bridge` 行已移除；插件目录已归档到 backup；无 TCP 桥接 |
| 13 | 素材透明、无白底/光晕 | **真实客户端已验证** | 真实 composer 截图中没有白色矩形；透明 PNG 四周 alpha=0；浅色/深色预览见 `docs/evidence/preview-*.png` |
| 14 | 不影响输入区的可点击性 | **代码/样式验证** | wrapper 和 img 都是 `pointer-events:none`，`aria-hidden=true`，无事件处理；未做“点击输入/发送”的真实回归 |
| 15 | 组件随 composer 重挂载 | **部分验证** | HMR/重载后组件仍出现；切换会话后的重挂载尚未用两个真实会话逐项验证 |

## 真实帧证据

连续截帧区域为 composer 右上沿（240×120），每帧约 150ms。

- 帧 0–6：正面 idle，无电脑。
- 帧 7–11：侧身，灰线电脑出现，手部像素数变化；右侧边缘未裁切。
- 帧 12 起：回到正面 idle，电脑消失。

侧身帧橙色 bbox 不变，说明身体、电脑和脚底没有因手部动作漂移。

## 状态映射（V2）

| 事件 | 结果 |
|---|---|
| `assistant/live-chunk` `reasoning-delta` 非空白 | thinking（侧身敲击） |
| `assistant/live-chunk` `text-delta` 非空白 | responding（正面 idle） |
| `assistant/live-chunk` `tool-call-delta` | tool（正面 idle） |
| `approval/asked` | waiting（正面 idle） |
| `turn/end` / `step/end` / `assistant/message` | idle（正面） |
| 6 秒无事件 | idle（防卡死） |
| 组件未挂载/取不到 binding | 不渲染或 idle，不伪造思考 |

`phaseOf()` 只扫描当前 Session eventSource 末尾的 transient/durable 事件；旧 turn 的事件不会覆盖新 turn。

## 尚未验证

以下项目没有做真实复现，不能写成已通过：

- 真实正文输出时是否已切正面 idle（代码路径已实现；V2 最终版没有单独截取 responding 画面）。
- 取消、报错、授权等待、断线；代码路径已实现。
- 同一客户端内切换两个会话、以及同名前缀会话；V2 已改为 sessionId 绑定，但未用两个真实会话测试。
- 输入框多行增高、侧栏开合、窗口缩放、100%/125%/150% DPI、明暗主题切换后的真实布局。
- 重复安装、卸载、重启后的回滚。
- 真实点击输入/发送/附件，确认无遮挡或行为影响。

## 已执行的安装/迁移检查

- `setup.ps1` 退出码 0；最终客户端插件位于：
  `%USERPROFILE%\.dsh\profiles\desktop\node_modules\dsh-claude-pet`
- patch 只保留 `claude-pet-v2` 行；旧 bridge/debug/test 行均不存在。
- 旧 V1 app 已归档到：
  `%LOCALAPPDATA%\ClaudeKeyboardWidget\backup\v2-migration-<时间戳>\v1-app`
- 旧 Host bridge 已归档到同一 backup。

## 仍需用户动作

**完全退出并重开一次 DeepSeek Harness**，确保当前 renderer 里缓存的旧调试模块彻底卸载。V2 的正式源码不含调试标记；当前页面为验证过程保留了隐藏旧节点的兼容样式，重启后会自然消失。

重启后请检查：

1. 输入框右上沿有正面小人，脚贴边，无电脑。
2. 发一条会触发思考的消息，小人变侧身、出现灰线电脑并轻敲。
3. 正文出现时变回正面；工具/授权/取消/错误时也不敲。
4. 切换会话后不显示上一会话的状态。
