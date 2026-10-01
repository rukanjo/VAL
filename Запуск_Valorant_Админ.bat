@echo off
chcp 65001 >nul
title Запуск Valorant от Администратора

echo ═══════════════════════════════════════════
echo   Запуск Valorant от имени администратора
echo ═══════════════════════════════════════════
echo.

REM Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ОШИБКА] Запустите этот файл от имени администратора!
    echo Нажмите ПКМ и выберите "Запуск от имени администратора"
    echo.
    pause
    exit /b 1
)

echo [1/3] Проверка службы Vanguard...
sc query vgc | find "RUNNING" >nul
if %errorLevel% neq 0 (
    echo [INFO] Запуск службы Vanguard...
    net start vgc >nul 2>&1
    timeout /t 2 >nul
)
echo [OK] Vanguard работает

echo.
echo [2/3] Поиск Riot Client...

REM Поиск Riot Client
set "RiotClientPath=%LOCALAPPDATA%\Riot Games\Riot Client\RiotClientServices.exe"

if exist "%RiotClientPath%" (
    echo [OK] Riot Client найден
    echo.
    echo [3/3] Запуск Riot Client...
    start "" "%RiotClientPath%" --launch-product=valorant --launch-patchline=live
    echo.
    echo [OK] Riot Client запущен!
    echo.
    echo Войдите в свой аккаунт и запустите Valorant.
    echo Окно закроется через 5 секунд...
    timeout /t 5 >nul
) else (
    echo [ОШИБКА] Riot Client не найден по пути:
    echo %RiotClientPath%
    echo.
    echo Возможно, Valorant установлен в другой папке.
    echo Запустите Riot Client вручную от имени администратора.
    echo.
    pause
)
