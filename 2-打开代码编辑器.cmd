@echo off
chcp 65001 >nul 2>&1
title BusTub Lab - VS Code
cd /d "%~dp0"

echo.
echo   Opening VS Code, connected to WSL (Ubuntu 22.04) ...
echo   Project: /root/bustub
echo.
echo   First run may take 1-2 minutes to download the VS Code Server.
echo.

set "CODE=%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd"
if not exist "%CODE%" set "CODE=%ProgramFiles%\Microsoft VS Code\bin\code.cmd"
if not exist "%CODE%" (
    echo   VS Code not found. Please install it first.
    pause
    exit /b 1
)

call "%CODE%" --remote wsl+Ubuntu-22.04 /root/bustub
