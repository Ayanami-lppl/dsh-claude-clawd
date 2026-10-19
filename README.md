# Claude 小人 V2（DeepSeek Harness 内嵌版）

按你确认的录屏方向重做：**不再是独立透明浮窗**，而是 DeepSeek Harness 输入框右上沿真实存在的 React 组件。

- 待机：橙色方块小人正面站立，双臂向左右伸出，四条短腿，**没有电脑**。
- 思考：同一小人转向左侧，身前出现一条灰色折线小电脑，轻轻敲键盘。
- 思考结束/正文/工具/授权/取消/错误/状态未知：恢复正面待机，电脑消失。
- 位置：输入框外壳右上沿，脚底贴输入框上边线，随输入框布局。
- 尺寸：56×40 CSS px（角色身体约 36px，整体含电脑约 56px）。
- 鼠标 `pointer-events: none`，`aria-hidden`，不抢焦点、不加 Tab 停靠点。
- 仅当前会话的 reasoning 状态生效；不再用标题前缀匹配。

## 当前状态

| 项目 | 状态 |
|---|---|
| 真实嵌入 DSH composer 右上沿 | **真实客户端已验证**（截图见 `docs/evidence/`） |
| 正面 idle 无电脑 | **真实客户端已验证** |
| 真实 thinking 切侧身 + 灰线电脑 | **真实客户端已验证**（右侧连续帧 7–11 为侧身，12 起回正面） |
| 手部交替、电脑/脚底稳定 | **真实客户端已验证**（侧身帧橙色 bbox 不变，手部像素数变化） |
| 正文/工具回到 idle | 状态源已验证；最终组件视觉上已捕捉到 thinking 后回 idle |
| 会话绑定 | 使用 `ctx.sessions.binding(sessionId)` 的当前会话事件源，不再用标题前缀 |
| 旧 V1 独立浮窗 | 已停止并移除快捷方式/安装目录/patch 行 |
| 旧 V1 Host 桥接 | 已从 profile 移除并归档 |
| 取消/报错/授权等待/同名前缀切换 | 代码路径已完成，尚未做真实事故复现 |
| 多行输入增高/侧栏开合/100/125/150% DPI/明暗主题 | 素材预览已做，真实布局逐项待补测 |

> 旧 V1 的验收记录只说明 V1 浮窗，不用于证明 V2。V2 的逐项证据见 `ACCEPTANCE.md`。

## 安装 / 迁移

双击：

```text
setup.cmd
```

安装器是用户级的，不需要管理员权限，会：

1. 停用并移除 V1 独立浮窗（桌面/开始菜单快捷方式、Run 项、旧 app 目录）；
2. 移除 V1 `dsh-thinking-widget-bridge` Host 插件与 patch 行；
3. 安装 V2 客户端插件到：
   `%USERPROFILE%\.dsh\profiles\desktop\node_modules\dsh-claude-pet`
4. 备份并更新 `cordis.patch.yml`；
5. 不安装任何独立 exe，不创建快捷方式，不启用开机自启。

安装/迁移后**完全退出并重开一次 DeepSeek Harness**，确保旧客户端模块卸载、V2 干净加载。之后 V2 会出现在输入框右上沿。

## 使用

- 不需要启动其他程序；打开 DeepSeek Harness 即生效。
- 待机时是正面无电脑。
- 当前会话进入明确 reasoning 阶段时，侧身出现灰线电脑并轻敲。
- 正文/工具/授权/取消/错误/断线/过期时立刻回正面 idle。
- 没有任何点击、拖拽、托盘或菜单；这是界面装饰层。

## 状态来源

V2 **不使用**旧的本机 TCP 桥接，也不读标题前缀。客户端组件从当前会话的
`ctx.sessions.binding(sessionId).eventSource` 读取：

- `assistant/live-chunk` 的 `reasoning-delta`（非空白）→ thinking
- `assistant/live-chunk` 的 `text-delta`（非空白）→ responding（idle）
- `assistant/live-chunk` 的 `tool-call-delta` → tool（idle）
- `approval/asked` → waiting（idle）
- `turn/end` / `step/end` / `assistant/message` → idle
- 6 秒没有新事件 → idle（防卡死）

`sessionId` 由 slot 标准 props 提供，切换会话时组件重绑/清理，后台会话事件不会进入当前组件。

## 素材

- 运行时透明 PNG：`v2-assets/frames/`
  - `idle.png`（正面无电脑）
  - `typing-rest.png` / `typing-left.png` / `typing-right.png`（同一侧身母版，仅手部变化）
- `v2-assets/frames.json`：56×40 画布、脚底锚点、循环帧序、140ms。
- 预览：
  - `v2-assets/preview-light.png`
  - `v2-assets/preview-dark.png`
  - `v2-assets/preview-thinking.gif`
- 源素材：
  - `v2-assets/source/claude-pose-source.png`
  - `v2-assets/source/video-pose-reference.png`
- 用户提供的原始录屏参考（含真实界面）不随公开仓库分发；透明帧和源底图足以复现素材处理。
- 生成脚本：`tools/make_v2_assets.py`
  - 白底抠除、有限色量化、统一 56×40 网格、脚底基线；
  - 用一张侧身母版生成三个手部帧，不直接裁四格轮播；
  - 可重复生成与当前 PNG 完全一致的帧。

## 代码结构

```text
dsh-claude-pet/
  setup.cmd / setup.ps1             V2 安装与 V1 迁移
  uninstall.cmd / uninstall.ps1     V2 卸载
  verify.ps1                        V2 安装检查
  v2-plugin/
    package.json                    dsh.client platform web
    lib/index.js                    Host 空壳（客户端插件需要可加载的 node 行）
    lib/client.js                   DSH 前端 slot 组件（内嵌图片 data URL）
    client.template.js              可维护的客户端源码模板
  v2-assets/                        透明帧、预览、源素材
  tools/
    make_v2_assets.py               素材生成
    build_v2_client.py              把 PNG 嵌入客户端 bundle
  docs/                             V2 架构与回滚
```

## 卸载 / 回滚

双击 `uninstall.cmd`。它会移除 `dsh-claude-pet` patch 行和插件目录，恢复 patch 备份，并提示重启 DSH。

备份在：

```text
%LOCALAPPDATA%\ClaudeKeyboardWidget\backup\v2-migration-<时间戳>\
```

包含旧 `cordis.patch.yml`、V1 app 目录、旧 Host 插件目录。手动回滚见 `docs/ROLLBACK.md`。

## 已知限制

- 首次安装/迁移后需要**完全重启 DSH**，因为当前客户端插件是页面模块；仅刷新不一定能清掉旧模块。
- 尚未在真实 DSH 上逐项测试：取消、报错、授权等待、多个同名前缀会话切换、多行输入增高、侧栏开合、100/125/150% DPI、明暗主题切换、卸载后重装。
- 客户端 slot 和 `assistant/live-chunk` 事件基于 DSH **0.2.1-rc.2**；未来版本若改 slot 名/transient 事件格式，需要更新插件。失败时组件不渲染或回 idle，不会伪造思考。
- 小人属于界面装饰层，不能点击；它不改变输入、发送、附件或选择行为。

## 验收

- 真实客户端证据与逐项状态：`ACCEPTANCE.md`
- 架构、状态映射、兼容性：`docs/V2-ARCHITECTURE.md`
- 备份与回滚：`docs/ROLLBACK.md`
