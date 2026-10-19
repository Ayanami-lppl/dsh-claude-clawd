$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$source = Join-Path $root 'v2-plugin'
$profileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
$target = Join-Path $profileDir 'node_modules\dsh-claude-pet'
$patch = Join-Path $profileDir 'cordis.patch.yml'
$localRoot = Join-Path $env:LOCALAPPDATA 'ClaudeKeyboardWidget'
$backupRoot = Join-Path $localRoot ('backup\v2-migration-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$log = Join-Path $localRoot 'v2-install.log'
$begin = '# BEGIN Claude pet v2'
$end = '# END Claude pet v2'
$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
function L([string]$s) { New-Item -ItemType Directory -Path (Split-Path $log) -Force | Out-Null; Add-Content -LiteralPath $log -Value "$(Get-Date -Format o) $s" -Encoding UTF8; Write-Host $s }
function Remove-Marked([string]$text, [string]$b, [string]$e) {
  return [regex]::Replace($text, '(?ms)^' + [regex]::Escape($b) + '.*?^' + [regex]::Escape($e) + '\s*\r?\n?', '')
}
try {
  New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
  L "V2 setup start; backup=$backupRoot"

  # Stop and remove the obsolete standalone V1 widget. V2 is embedded in DSH.
  Get-Process ClaudeKeyboardWidget -ErrorAction SilentlyContinue | Stop-Process -Force
  foreach ($lnk in @((Join-Path $desktop 'Claude 键盘挂件.lnk'), (Join-Path $startMenu 'Claude 键盘挂件.lnk'))) {
    if (Test-Path $lnk) { Remove-Item $lnk -Force; L "removed old shortcut $lnk" }
  }
  try {
    $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (Test-Path $runKey) { Remove-ItemProperty -Path $runKey -Name 'ClaudeKeyboardWidget' -ErrorAction SilentlyContinue }
  } catch { }
  $oldApp = Join-Path $localRoot 'app'
  if (Test-Path $oldApp) { Move-Item $oldApp (Join-Path $backupRoot 'v1-app'); L 'archived old standalone app' }
  $oldBridge = Join-Path $localRoot 'bridge.json'
  if (Test-Path $oldBridge) { Remove-Item $oldBridge -Force }

  # Install the embedded client package.
  if (Test-Path $target) { Move-Item $target (Join-Path $backupRoot 'dsh-claude-pet-old') }
  New-Item -ItemType Directory -Path $target -Force | Out-Null
  Copy-Item (Join-Path $source 'package.json') $target -Force
  Copy-Item (Join-Path $source 'lib') $target -Recurse -Force
  L "installed embedded client plugin at $target"

  # Remove the obsolete Host bridge and any debug/test rows.
  $text = Get-Content $patch -Raw -Encoding UTF8
  $text = Remove-Marked $text '# BEGIN Claude keyboard widget bridge' '# END Claude keyboard widget bridge'
  $text = Remove-Marked $text '# BEGIN Claude pet test' '# END Claude pet test'
  $text = Remove-Marked $text '# BEGIN Claude pet debug' '# END Claude pet debug'
  $text = Remove-Marked $text $begin $end
  foreach ($old in @('dsh-thinking-widget-bridge', 'dsh-claude-pet-test', 'dsh-claude-pet-debug')) {
    $oldPath = Join-Path $profileDir ('node_modules\' + $old)
    if (Test-Path $oldPath) { Move-Item $oldPath (Join-Path $backupRoot $old); L "archived obsolete plugin $old" }
  }
  if (-not $text.EndsWith("`n")) { $text += "`r`n" }
  $text += "$begin`r`n- insert:`r`n    - id: claude-pet-v2`r`n      name: dsh-claude-pet`r`n$end`r`n"
  $text = [regex]::Replace($text, '(?m)^# reload .*\r?\n?', '')
  $text = $text.TrimEnd() + "`r`n# reload " + (Get-Date -Format 'yyyyMMdd-HHmmss') + "`r`n"
  Copy-Item $patch (Join-Path $backupRoot 'cordis.patch.yml') -Force
  [System.IO.File]::WriteAllText($patch, $text, (New-Object System.Text.UTF8Encoding($false)))
  L 'patch updated: removed V1 bridge, added dsh-claude-pet'
  L 'V2 setup done. Fully restart DeepSeek Harness to cleanly unload any old client module.'
} catch {
  L ("ERROR " + $_.Exception.Message)
  exit 1
}
