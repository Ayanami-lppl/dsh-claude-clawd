@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Uninstalling embedded Claude pet V2...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
echo.
echo Restart DeepSeek Harness to unload the client component.
pause
