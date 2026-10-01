@echo off
chcp 65001 >nul
title VALORANT VAL43 Quick Fix

REM Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Запустите от имени Администратора!
    pause
    exit /b 1
)

echo Быстрое исправление VAL43...
echo.

REM Остановка процессов
taskkill /F /IM "RiotClientServices.exe" >nul 2>&1
taskkill /F /IM "Valorant.exe" >nul 2>&1
echo [1/4] Процессы остановлены

REM Удаление файлов
set "RiotData=%LOCALAPPDATA%\Riot Games\Riot Client\Data"
del /F /Q "%RiotData%\RiotClientPrivateSettings.yaml" >nul 2>&1
del /F /Q "%RiotData%\RiotGamesPrivateSettings.yaml" >nul 2>&1
echo [2/4] Файлы удалены

REM Перезапуск Vanguard
net stop vgc >nul 2>&1
timeout /t 1 >nul
net start vgc >nul 2>&1
echo [3/4] Vanguard перезапущен

REM Очистка DNS
ipconfig /flushdns >nul 2>&1
echo [4/4] DNS очищен

echo.
echo Готово! Запустите Valorant от имени администратора.
echo.
pause
