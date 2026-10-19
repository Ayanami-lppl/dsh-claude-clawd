$ErrorActionPreference = 'Continue'
$profileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
$target = Join-Path $profileDir 'node_modules\dsh-claude-pet\lib\client.js'
$patch = Join-Path $profileDir 'cordis.patch.yml'
$desktop = [Environment]::GetFolderPath('Desktop')
$oldShortcut = Join-Path $desktop 'Claude 键盘挂件.lnk'
Write-Host '=== Claude Pet V2 / DeepSeek Harness 验证 ===' -ForegroundColor Cyan
Write-Host ("1. 内嵌客户端插件: " + $(if (Test-Path $target) { 'OK  ' + $target } else { '缺失  ' + $target }))
$patchText = if (Test-Path $patch) { Get-Content $patch -Raw -Encoding UTF8 } else { '' }
Write-Host ("2. V2 patch 行: " + $(if ($patchText -match 'claude-pet-v2') { 'OK' } else { '缺失' }))
Write-Host ("3. 旧独立挂件快捷方式: " + $(if (Test-Path $oldShortcut) { '仍存在（需要移除）' } else { '已移除' }))
Write-Host ("4. 旧 Host 桥接行: " + $(if ($patchText -match 'thinking-widget-bridge') { '仍存在（需要迁移）' } else { '已移除' }))
$proc = Get-Process ClaudeKeyboardWidget -ErrorAction SilentlyContinue
Write-Host ("5. 旧独立挂件进程: " + $(if ($proc) { '仍在运行（需要停止）' } else { '未运行' }))
Write-Host '6. 视觉验收请直接看 DSH 输入框左上沿：正面无电脑 = idle；侧身灰线电脑 = thinking。' -ForegroundColor Gray
Write-Host '7. 若看不到小人，完全退出 DSH 再重开，然后检查 patch 行与插件文件。' -ForegroundColor Gray
