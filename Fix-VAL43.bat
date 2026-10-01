@echo off
setlocal
cd /d "%~dp0"
title VAL43 Fix

net session >nul 2>&1
if "%errorlevel%"=="0" goto :run

echo Requesting administrator permission...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
if not "%errorlevel%"=="0" (
    echo Administrator permission was not granted.
    pause
)
exit /b

:run
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-VAL43.ps1"
if not "%errorlevel%"=="0" (
    echo.
    echo The script exited with an error.
    pause
)
