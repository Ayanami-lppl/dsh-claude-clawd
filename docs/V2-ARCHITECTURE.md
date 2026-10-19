# V2 架构：DSH 内嵌 composer 挂件

## 目标

把 Claude 小人从独立透明窗口迁移为 DeepSeek Harness 输入框内真实存在的装饰组件：

- 待机：正面、无电脑。
- 思考：侧身朝左，灰线小电脑，手部轻敲。
- 其他阶段：正面 idle。
- 仅当前会话；不读标题前缀。
- 不抢焦点、不阻挡输入。

## 前端接入点

`dsh-claude-pet` 是 DSH client plugin：

- `package.json`：
  - `dsh.client.platform = "web"`
  - `exports["./client"] = "./lib/client.js"`
  - Host 侧 `lib/index.js` 是空 `apply()`。
- `lib/client.js` 是 `window.__ModuleLoader__.load({ id, factory })` 格式。
- `export const inject = ['slots', 'sessions']`。
- `ctx.slots.inject('conversation.input.overlay', () => ctx.slots.register(...))`。

`conversation.input.overlay` 由 `dsh-client-ui-conversation` 的 `InputBar` 渲染，位于
`data-composer-overlay` 的零高度绝对定位锚点内。

组件样式：

```css
position:absolute;
right:4px;
top:0;
width:56px;
height:40px;
transform:translateY(-100%);
pointer-events:none;
z-index:30;
```

因此脚底正好在 composer 外壳上边线、整体靠右；身体在上方。不放进 contenteditable，不增加按钮或 Tab 停靠点。

## 状态来源

不使用 V1 的本机 TCP 桥接，也不使用标题前缀。客户端组件直接读取：

```js
const binding = ctx.sessions.binding(sessionId);
const entries = binding.eventSource.getSnapshot().entries;
```

`assistant/live-chunk` 是当前会话的 transient Assistant stream，`event.data.chunk`
包含 `reasoning-delta` / `text-delta` / `tool-call-delta` / `finish`。

`phaseOf()` 从事件窗口末尾向前扫描最多 240 条，遇到当前 turn/step 边界或
assistant 流事件即返回阶段：

| 输入 | 输出 |
|---|---|
| `reasoning-delta` 非空白 | `thinking` |
| `text-delta` 非空白 | `responding` |
| `tool-call-delta` | `tool` |
| `finish` | `finishing` |
| `turn/start` / `step/start` / `request/header` | `requesting` |
| `approval/asked` | `waiting` |
| `turn/end` / `step/end` / `assistant/message` / `assistant/attempt` | `idle` |
| 其它 | 继续向前找；找不到则 idle |

只有 `thinking` 渲染侧身敲击；所有其他阶段渲染正面 idle。

## 会话绑定与清理

- `sessionId` 由 session-scope slot 标准 props 提供。
- `useEffect` 依赖 `[sessionId, sessions]`：切换会话时解除旧 `eventSource` 订阅、重绑新会话。
- 旧会话的 eventSource 订阅被清理，不能把事件带进新组件。
- 如果 binding 暂时不存在，500ms 重试；最终仍无 binding 则 idle。
- 6 秒无新事件自动 idle，防止断线/卡死。
- 不记录推理正文、回复正文、工具参数或密钥；只在本进程内读取 chunk 类型/空白判断。

## 素材与渲染

- 56×40 canvas，脚底锚点 `(34,37)`。
- `idle.png`：正面、无电脑。
- `typing-rest/left/right.png`：同一侧身母版；手部 1px 移动；电脑和脚底不动。
- 循环：`rest → left → rest → right`，140ms/帧。
- `prefers-reduced-motion: reduce` 时只显示 `typing-rest`。
- PNG 以 base64 data URL 嵌入 `client.js`，无运行时网络请求。
- `image-rendering: pixelated`，最近邻缩放。

## 迁移

V2 安装器：

1. 停用/移除 V1 独立 app、桌面/开始菜单快捷方式、Run 项。
2. 移除 V1 `dsh-thinking-widget-bridge` patch 行和 node_modules 目录（归档到 backup）。
3. 安装 `dsh-claude-pet`。
4. patch 增加 `claude-pet-v2` 行。
5. 不创建任何独立程序或快捷方式。

## 版本兼容

- 依据 DSH `0.2.1-rc.2` 的 `conversation.input.overlay`、`sessions.binding`、
  `assistant/live-chunk` 实现。
- 如果未来 slot 名或 transient 事件结构变化，组件会不渲染或回 idle；不会伪造 thinking。
- 不建议用旧版本 DSH；旧版本可能没有该 slot 或 transient 流。
