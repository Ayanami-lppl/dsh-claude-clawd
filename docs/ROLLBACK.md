# V2 备份与回滚

## 安装器改什么

`setup.ps1`：

1. 停止并移除 V1 独立 exe（`ClaudeKeyboardWidget.exe`）。
2. 删除 V1 桌面/开始菜单快捷方式「Claude 键盘挂件」。
3. 删除 HKCU Run 项 `ClaudeKeyboardWidget`。
4. 把 V1 app 目录移到：
   `%LOCALAPPDATA%\ClaudeKeyboardWidget\backup\v2-migration-<时间戳>\v1-app`
5. 从 `cordis.patch.yml` 删除 V1 `thinking-widget-bridge` 行。
6. 把旧 Host 插件目录移到同一 backup。
7. 安装 V2 客户端插件到：
   `%USERPROFILE%\.dsh\profiles\desktop\node_modules\dsh-claude-pet`
8. 备份 patch，新增 `claude-pet-v2` 行。

**不会**修改 `C:\deepseek harness` 安装包、`app.asar`、进程注入、代理或聊天记录。

## 回滚 V2

完全退出 DSH，然后：

1. 删除：
   `%USERPROFILE%\.dsh\profiles\desktop\node_modules\dsh-claude-pet`
2. 把 backup 中的 `cordis.patch.yml` 覆盖回：
   `%USERPROFILE%\.dsh\profiles\desktop\cordis.patch.yml`
3. 重启 DSH。

如果只想卸载 V2，双击 `uninstall.cmd`；它会做 1 并移除 patch 行。

## 恢复 V1（不推荐）

V1 独立浮窗已废弃，但备份里仍有 `v1-app`。如确需恢复：

1. 把 `v1-app` 改名/复制回 `%LOCALAPPDATA%\ClaudeKeyboardWidget\app`。
2. 重新创建桌面快捷方式到 `app\ClaudeKeyboardWidget.exe`。
3. 旧 Host bridge 插件目录和 patch 行也在同一 backup；恢复它们会重新启用旧 TCP 桥接。
4. 不要同时启用 V2 和 V1，否则状态源/UI 会冲突。

## 备份位置

```text
%LOCALAPPDATA%\ClaudeKeyboardWidget\backup\v2-migration-<时间戳>\
  cordis.patch.yml
  v1-app\
  dsh-thinking-widget-bridge\
  dsh-claude-pet-old\        (重复安装时)
```

## 最小故障恢复

如果 DSH 启动异常：

1. 任务管理器结束 `DeepSeek Harness.exe`。
2. 用 backup 的 `cordis.patch.yml` 覆盖 profile patch。
3. 删除 `node_modules\dsh-claude-pet`。
4. 重启 DSH。

V2 客户端组件是 fail-open：取不到 slot/binding 时不渲染或回 idle，不会卡住输入。
