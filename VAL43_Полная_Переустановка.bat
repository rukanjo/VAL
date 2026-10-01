@echo off
chcp 65001 >nul
title ПОЛНАЯ ПЕРЕУСТАНОВКА VANGUARD (Решение VAL43)

color 0E
echo ═══════════════════════════════════════════════════════
echo     ПОЛНАЯ ПЕРЕУСТАНОВКА VANGUARD
echo ═══════════════════════════════════════════════════════
color 07
echo.
echo Этот скрипт выполнит ПОЛНОЕ удаление и переустановку Vanguard.
echo.
echo ЧТО БУДЕТ СДЕЛАНО:
echo 1. Остановка всех процессов Riot
echo 2. Удаление Vanguard через систему
echo 3. Очистка всех файлов и папок Vanguard
echo 4. Удаление временных файлов Riot Client
echo 5. Очистка кэша и настроек
echo 6. Запуск Riot Client для автоустановки Vanguard
echo.
echo ВНИМАНИЕ: Ваш игровой прогресс НЕ будет удален!
echo Все сохранено на серверах Riot.
echo.
echo Процесс займет 5-10 минут.
echo.
pause

REM Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo.
    echo [ОШИБКА] Запустите от имени Администратора!
    color 07
    echo.
    pause
    exit /b 1
)

echo.
echo [СТАРТ] Начинаем процесс переустановки...
echo.

REM 1. Остановка всех процессов
echo [1/9] Остановка процессов Riot и Valorant...
taskkill /F /IM "RiotClientServices.exe" >nul 2>&1
taskkill /F /IM "RiotClientUx.exe" >nul 2>&1
taskkill /F /IM "RiotClientCrashHandler.exe" >nul 2>&1
taskkill /F /IM "Valorant.exe" >nul 2>&1
taskkill /F /IM "VALORANT-Win64-Shipping.exe" >nul 2>&1
taskkill /F /IM "LeagueClient.exe" >nul 2>&1
timeout /t 2 >nul
echo [OK] Процессы остановлены

echo.

REM 2. Остановка службы Vanguard
echo [2/9] Остановка службы Vanguard (VGC)...
net stop vgc >nul 2>&1
sc stop vgc >nul 2>&1
timeout /t 2 >nul
echo [OK] Служба Vanguard остановлена

echo.

REM 3. Удаление Vanguard через систему
echo [3/9] Удаление Vanguard через систему...
echo Это может занять несколько минут...

wmic product where "name='Riot Vanguard'" call uninstall /nointeractive >nul 2>&1

REM Альтернативный метод через реестр
for /f "tokens=1* delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Riot Vanguard" ^| findstr "UninstallString"') do (
    set "uninstallCmd=%%b"
    if defined uninstallCmd (
        echo Запуск деинсталлятора Vanguard...
        start /wait "" !uninstallCmd! /S
    )
)

timeout /t 3 >nul
echo [OK] Vanguard удален из системы

echo.

REM 4. Принудительное удаление службы VGC
echo [4/9] Удаление службы VGC из системы...
sc delete vgc >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Служба VGC удалена
) else (
    echo [INFO] Служба уже удалена
)

echo.

REM 5. Удаление файлов Vanguard
echo [5/9] Удаление файлов и папок Vanguard...

if exist "%PROGRAMFILES%\Riot Vanguard" (
    echo Удаление: %PROGRAMFILES%\Riot Vanguard
    icacls "%PROGRAMFILES%\Riot Vanguard" /grant administrators:F /T >nul 2>&1
    rd /s /q "%PROGRAMFILES%\Riot Vanguard" >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Папка Vanguard удалена
    ) else (
        echo [WARNING] Папка будет удалена после перезагрузки
    )
)

REM Удаление драйвера Vanguard
if exist "%SystemRoot%\System32\drivers\vgk.sys" (
    echo Удаление драйвера vgk.sys...
    del /f /q "%SystemRoot%\System32\drivers\vgk.sys" >nul 2>&1
)

echo.

REM 6. Очистка временных файлов Riot Client
echo [6/9] Очистка временных файлов Riot Client...

set "RiotLocal=%LOCALAPPDATA%\Riot Games"
set "RiotRoaming=%APPDATA%\Riot Games"

REM Удаление файлов настроек (но не самой игры!)
if exist "%RiotLocal%\Riot Client\Data\RiotClientPrivateSettings.yaml" (
    del /f /q "%RiotLocal%\Riot Client\Data\RiotClientPrivateSettings.yaml" >nul 2>&1
    echo [OK] Удален RiotClientPrivateSettings.yaml
)

if exist "%RiotLocal%\Riot Client\Config\RiotClientSettings.yaml" (
    del /f /q "%RiotLocal%\Riot Client\Config\RiotClientSettings.yaml" >nul 2>&1
    echo [OK] Удален RiotClientSettings.yaml
)

if exist "%RiotLocal%\Riot Client\Data\RiotGamesPrivateSettings.yaml" (
    del /f /q "%RiotLocal%\Riot Client\Data\RiotGamesPrivateSettings.yaml" >nul 2>&1
    echo [OK] Удален RiotGamesPrivateSettings.yaml
)

if exist "%RiotLocal%\Riot Client\Data\RiotClientInstalls.json" (
    del /f /q "%RiotLocal%\Riot Client\Data\RiotClientInstalls.json" >nul 2>&1
    echo [OK] Удален RiotClientInstalls.json
)

REM Очистка кэша
if exist "%RiotLocal%\Riot Client\Cache" (
    rd /s /q "%RiotLocal%\Riot Client\Cache" >nul 2>&1
    echo [OK] Кэш очищен
)

if exist "%RiotLocal%\Riot Client\Logs" (
    rd /s /q "%RiotLocal%\Riot Client\Logs" >nul 2>&1
    echo [OK] Логи удалены
)

echo.

REM 7. Сброс сетевых настроек
echo [7/9] Сброс сетевых настроек...
netsh winsock reset >nul 2>&1
netsh int ip reset >nul 2>&1
ipconfig /flushdns >nul 2>&1
netsh winhttp reset proxy >nul 2>&1
echo [OK] Сетевые настройки сброшены

echo.

REM 8. Настройка брандмауэра
echo [8/9] Настройка правил брандмауэра...

REM Удаление старых правил
netsh advfirewall firewall delete rule name="Valorant" >nul 2>&1
netsh advfirewall firewall delete rule name="Riot Client" >nul 2>&1
netsh advfirewall firewall delete rule name="Riot Vanguard" >nul 2>&1

REM Добавление новых правил
if exist "%RiotLocal%\Riot Games\Riot Client\RiotClientServices.exe" (
    netsh advfirewall firewall add rule name="Riot Client" dir=in action=allow program="%RiotLocal%\Riot Games\Riot Client\RiotClientServices.exe" enable=yes >nul 2>&1
    netsh advfirewall firewall add rule name="Riot Client" dir=out action=allow program="%RiotLocal%\Riot Games\Riot Client\RiotClientServices.exe" enable=yes >nul 2>&1
    echo [OK] Правила брандмауэра обновлены
)

echo.

REM 9. Проверка установки Riot Client
echo [9/9] Проверка установки Riot Client...

set "RiotClientExe=%RiotLocal%\Riot Games\Riot Client\RiotClientServices.exe"

if exist "%RiotClientExe%" (
    echo [OK] Riot Client найден
    echo.
    echo ═══════════════════════════════════════════════════════
    echo     ПОДГОТОВКА ЗАВЕРШЕНА!
    echo ═══════════════════════════════════════════════════════
    echo.
    echo СЛЕДУЮЩИЕ ШАГИ:
    echo.
    echo 1. ОБЯЗАТЕЛЬНО ПЕРЕЗАГРУЗИТЕ КОМПЬЮТЕР!
    echo 2. После перезагрузки запустите Riot Client ОТ АДМИНИСТРАТОРА
    echo 3. Войдите в свой аккаунт
    echo 4. Riot Client автоматически установит Vanguard
    echo 5. Снова перезагрузите ПК после установки Vanguard
    echo 6. Запустите Valorant
    echo.
    echo ВАЖНО: Для автоматического запуска используйте файл:
    echo "Запуск_Valorant_Админ.bat"
    echo.
    
    set /p openClient="Открыть Riot Client сейчас? (N - рекомендуется перезагрузка) (Y/N): "
    if /i "!openClient!"=="Y" (
        echo.
        echo Запуск Riot Client...
        start "" "%RiotClientExe%"
        echo.
        echo После установки Vanguard ОБЯЗАТЕЛЬНО перезагрузите ПК!
    ) else (
        echo.
        echo Отлично! Перезагрузите ПК и запустите Riot Client.
    )
    
) else (
    echo [ERROR] Riot Client не найден!
    echo.
    echo Riot Client не установлен или установлен в нестандартной папке.
    echo.
    echo РЕШЕНИЕ:
    echo 1. Скачайте Valorant с официального сайта:
    echo    https://playvalorant.com
    echo 2. Установите игру
    echo 3. Vanguard установится автоматически
    echo 4. Перезагрузите компьютер
    echo.
)

echo.
set /p reboot="Перезагрузить компьютер сейчас? (Y/N): "
if /i "%reboot%"=="Y" (
    echo.
    echo Перезагрузка через 15 секунд...
    echo Сохраните все открытые файлы!
    shutdown /r /t 15 /c "Перезагрузка для завершения переустановки Vanguard"
) else (
    echo.
    echo НЕ ЗАБУДЬТЕ ПЕРЕЗАГРУЗИТЬ КОМПЬЮТЕР!
)

echo.
pause
