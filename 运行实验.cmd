@echo off
chcp 65001 >nul 2>&1
title BusTub Lab - Build and Test
cd /d "%~dp0"

echo.
echo   ============================================================
echo    BusTub P1  -  build and run tests
echo   ============================================================
echo.

wsl.exe -d Ubuntu-22.04 -u root --cd /root/bustub -- bash /root/tools/run-p1.sh --color

echo.
echo   ------------------------------------------------------------
pause
