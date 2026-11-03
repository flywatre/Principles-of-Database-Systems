@echo off
chcp 65001 >nul 2>&1
title BusTub Lab - Ubuntu 22.04
cd /d "%~dp0"

echo.
echo   ============================================================
echo    BusTub Lab Environment  /  Ubuntu 22.04 on WSL2
echo   ============================================================
echo.
echo    Code   : /root/bustub        (BusTub 2023.1, P1 only)
echo    Build  : /root/bustub/build
echo    Tests  : /root/tools/run-p1.sh
echo.
echo    Inside the shell:
echo      code .                             open project in VS Code
echo      bash /root/tools/run-p1.sh         build + run P1 tests
echo      git status                         see your changes
echo.
echo   ============================================================
echo.

wsl.exe -d Ubuntu-22.04 --cd /root/bustub
if errorlevel 1 (
    echo.
    echo   Failed to start WSL. Is the distro "Ubuntu-22.04" still registered?
    echo   Try:  wsl -l -v
    pause
)
