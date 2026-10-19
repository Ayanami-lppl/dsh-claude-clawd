$ErrorActionPreference = 'Stop'
$profileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
$target = Join-Path $profileDir 'node_modules\dsh-claude-pet'
$patch = Join-Path $profileDir 'cordis.patch.yml'
$localRoot = Join-Path $env:LOCALAPPDATA 'ClaudeKeyboardWidget'
$backupRoot = Join-Path $localRoot ('backup\v2-uninstall-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$log = Join-Path $localRoot 'v2-uninstall.log'
$desktop = [Environment]::GetFolderPath('Desktop')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
function L([string]$s) { New-Item -ItemType Directory -Path (Split-Path $log) -Force | Out-Null; Add-Content -LiteralPath $log -Value "$(Get-Date -Format o) $s" -Encoding UTF8; Write-Host $s }
try {
  New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
  L "V2 uninstall start; backup=$backupRoot"
  Get-Process ClaudeKeyboardWidget -ErrorAction SilentlyContinue | Stop-Process -Force
  foreach ($lnk in @((Join-Path $desktop 'Claude 键盘挂件.lnk'), (Join-Path $startMenu 'Claude 键盘挂件.lnk'))) {
    if (Test-Path $lnk) { Remove-Item $lnk -Force; L "removed $lnk" }
  }
  if (Test-Path $target) { Move-Item $target (Join-Path $backupRoot 'dsh-claude-pet'); L 'archived dsh-claude-pet' }
  if (Test-Path $patch) {
    $text = Get-Content $patch -Raw -Encoding UTF8
    $text = [regex]::Replace($text, '(?ms)^' + [regex]::Escape('# BEGIN Claude pet v2') + '.*?^' + [regex]::Escape('# END Claude pet v2') + '\s*\r?\n?', '')
    $text = [regex]::Replace($text, '(?ms)^' + [regex]::Escape('# BEGIN Claude pet debug') + '.*?^' + [regex]::Escape('# END Claude pet debug') + '\s*\r?\n?', '')
    $text = [regex]::Replace($text, '(?ms)^' + [regex]::Escape('# BEGIN Claude pet test') + '.*?^' + [regex]::Escape('# END Claude pet test') + '\s*\r?\n?', '')
    $text = [regex]::Replace($text, '(?m)^# reload .*\r?\n?', '')
    Copy-Item $patch (Join-Path $backupRoot 'cordis.patch.yml') -Force
    [System.IO.File]::WriteAllText($patch, $text.TrimEnd() + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
    L 'removed Claude pet rows from cordis.patch.yml'
  }
  L 'V2 uninstall done. Restart DeepSeek Harness.'
} catch {
  L ("ERROR " + $_.Exception.Message)
  exit 1
}
