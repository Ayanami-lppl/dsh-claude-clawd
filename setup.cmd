@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Installing embedded Claude pet V2 for DeepSeek Harness...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
echo.
echo Please fully exit and reopen DeepSeek Harness once.
pause
