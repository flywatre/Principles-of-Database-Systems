@echo off
setlocal
chcp 65001 >nul 2>&1
title BusTub Lab - Build and Test

echo.
echo   ============================================================
echo    BusTub P1  -  build and run tests
echo   ============================================================
echo.

wsl.exe --cd "%~dp0." -- bash "./工具/run-p1.sh" --color
set "result=%errorlevel%"

echo.
echo   ------------------------------------------------------------
pause
exit /b %result%
