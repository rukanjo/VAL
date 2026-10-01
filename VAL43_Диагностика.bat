@echo off
chcp 65001 >nul
title VAL43 - Диагностика проблемы

echo ═══════════════════════════════════════════════════════
echo     ДИАГНОСТИКА ПРОБЛЕМЫ VAL43
echo ═══════════════════════════════════════════════════════
echo.

REM Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ОШИБКА] Запустите от имени Администратора!
    pause
    exit /b 1
)

echo Сканирование системы на проблемы...
echo.

REM 1. Проверка Bonjour
echo [1] Проверка BONJOUR (главная причина VAL43):
echo ─────────────────────────────────────────────────────
wmic product where "name like '%%Bonjour%%'" get name,version 2>nul | find "Bonjour" >nul
if %errorLevel% equ 0 (
    echo [!!!] НАЙДЕН BONJOUR - ЭТО ПРИЧИНА ОШИБКИ!
    wmic product where "name like '%%Bonjour%%'" get name,version
    echo.
    echo ^>^>^> РЕШЕНИЕ: Удалить Bonjour!
) else (
    echo [OK] Bonjour не обнаружен
)

if exist "%PROGRAMFILES%\Bonjour\mDNSResponder.exe" (
    echo [!!!] ВНИМАНИЕ: Найдены файлы Bonjour в Program Files!
    echo Путь: %PROGRAMFILES%\Bonjour\
    echo ^>^>^> РЕШЕНИЕ: Запустите скрипт удаления Bonjour!
) else (
    if exist "%PROGRAMFILES(x86)%\Bonjour\mDNSResponder.exe" (
        echo [!!!] ВНИМАНИЕ: Найдены файлы Bonjour в Program Files (x86)!
        echo Путь: %PROGRAMFILES(x86)%\Bonjour\
        echo ^>^>^> РЕШЕНИЕ: Запустите скрипт удаления Bonjour!
    )
)

echo.
echo.

REM 2. Проверка службы Vanguard
echo [2] Проверка службы VANGUARD (VGC):
echo ─────────────────────────────────────────────────────
sc query vgc >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Служба Vanguard установлена
    sc query vgc | find "STATE" | find "RUNNING" >nul
    if %errorLevel% equ 0 (
        echo [OK] Служба Vanguard ЗАПУЩЕНА
    ) else (
        echo [WARNING] Служба Vanguard НЕ запущена!
        echo ^>^>^> РЕШЕНИЕ: Запустить VGC или переустановить Vanguard
    )
    
    sc qc vgc | find "START_TYPE" | find "AUTO_START" >nul
    if %errorLevel% equ 0 (
        echo [OK] Vanguard настроен на автозапуск
    ) else (
        echo [WARNING] Vanguard НЕ настроен на автозапуск!
        echo ^>^>^> РЕШЕНИЕ: Изменить тип запуска на "Automatic"
    )
) else (
    echo [ERROR] Служба Vanguard НЕ УСТАНОВЛЕНА!
    echo ^>^>^> РЕШЕНИЕ: Переустановить Valorant/Vanguard
)

echo.
echo.

REM 3. Проверка процессов Riot
echo [3] Проверка процессов RIOT:
echo ─────────────────────────────────────────────────────
tasklist | find "RiotClientServices.exe" >nul
if %errorLevel% equ 0 (
    echo [INFO] Riot Client запущен
) else (
    echo [OK] Riot Client не запущен
)

tasklist | find "Valorant.exe" >nul
if %errorLevel% equ 0 (
    echo [INFO] Valorant запущен
) else (
    echo [OK] Valorant не запущен
)

echo.
echo.

REM 4. Проверка файлов настроек
echo [4] Проверка файлов настроек RIOT:
echo ─────────────────────────────────────────────────────
set "foundFiles=0"

if exist "%LOCALAPPDATA%\Riot Games\Riot Client\Data\RiotClientPrivateSettings.yaml" (
    echo [FOUND] RiotClientPrivateSettings.yaml
    set "foundFiles=1"
)

if exist "%LOCALAPPDATA%\Riot Games\Riot Client\Config\RiotClientSettings.yaml" (
    echo [FOUND] RiotClientSettings.yaml
    set "foundFiles=1"
)

if exist "%LOCALAPPDATA%\Riot Games\Riot Client\Data\RiotGamesPrivateSettings.yaml" (
    echo [FOUND] RiotGamesPrivateSettings.yaml
    set "foundFiles=1"
)

if %foundFiles% equ 1 (
    echo ^>^>^> РЕШЕНИЕ: Удалить эти файлы через патч
) else (
    echo [OK] Проблемные файлы отсутствуют
)

echo.
echo.

REM 5. Проверка других конфликтующих программ
echo [5] Проверка других конфликтующих программ:
echo ─────────────────────────────────────────────────────

wmic product where "name like '%%National Instruments%%'" get name 2>nul | find "National Instruments" >nul
if %errorLevel% equ 0 (
    echo [WARNING] Найден National Instruments (может конфликтовать)
    wmic product where "name like '%%National Instruments%%'" get name
    echo ^>^>^> РЕКОМЕНДАЦИЯ: Удалить через Панель управления
    echo.
)

wmic product where "name like '%%Guardian Browser%%'" get name 2>nul | find "Guardian Browser" >nul
if %errorLevel% equ 0 (
    echo [WARNING] Найден Guardian Browser (может конфликтовать)
    echo ^>^>^> РЕКОМЕНДАЦИЯ: Удалить через Панель управления
    echo.
)

wmic product where "name like '%%Anti Cheat Expert%%'" get name 2>nul | find "Anti Cheat Expert" >nul
if %errorLevel% equ 0 (
    echo [WARNING] Найден Anti Cheat Expert (может конфликтовать)
    echo ^>^>^> РЕКОМЕНДАЦИЯ: Удалить через Панель управления
    echo.
)

echo.
echo.

REM 6. Проверка установки Valorant
echo [6] Проверка установки VALORANT:
echo ─────────────────────────────────────────────────────
if exist "%LOCALAPPDATA%\Riot Games\Riot Client\RiotClientServices.exe" (
    echo [OK] Riot Client найден
) else (
    echo [ERROR] Riot Client НЕ найден!
    echo ^>^>^> РЕШЕНИЕ: Переустановить Riot Client
)

if exist "%PROGRAMFILES%\Riot Vanguard\vgk.sys" (
    echo [OK] Драйвер Vanguard найден
) else (
    echo [WARNING] Драйвер Vanguard не найден
)

echo.
echo.

REM 7. Тест сетевого подключения
echo [7] Проверка сетевого подключения:
echo ─────────────────────────────────────────────────────
ping -n 1 google.com >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Интернет подключение работает
) else (
    echo [ERROR] Проблемы с интернет подключением!
    echo ^>^>^> РЕШЕНИЕ: Проверьте подключение к интернету
)

echo Проверка DNS...
nslookup playvalorant.com >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] DNS работает
) else (
    echo [WARNING] Проблемы с DNS
    echo ^>^>^> РЕШЕНИЕ: Очистить DNS кэш (ipconfig /flushdns)
)

echo.
echo.

REM 8. Проверка брандмауэра Windows
echo [8] Проверка брандмауэра Windows:
echo ─────────────────────────────────────────────────────
netsh advfirewall show currentprofile | find "State" | find "ON" >nul
if %errorLevel% equ 0 (
    echo [INFO] Брандмауэр Windows включен
    echo ^>^>^> СОВЕТ: Убедитесь что Valorant разрешен в брандмауэре
) else (
    echo [INFO] Брандмауэр Windows выключен
)

echo.
echo ═══════════════════════════════════════════════════════
echo     ИТОГИ ДИАГНОСТИКИ
echo ═══════════════════════════════════════════════════════
echo.
echo Диагностика завершена! Проверьте результаты выше.
echo.
echo НАИБОЛЕЕ ЧАСТЫЕ ПРИЧИНЫ VAL43:
echo 1. BONJOUR установлен (ГЛАВНАЯ ПРИЧИНА!)
echo 2. Служба Vanguard не запущена или не в режиме Automatic
echo 3. Временные файлы настроек Riot
echo 4. Проблемы с сетевыми настройками
echo.
echo РЕКОМЕНДУЕМЫЕ ДЕЙСТВИЯ:
echo 1. Если найден BONJOUR - запустите "VAL43_Удаление_Bonjour.bat"
echo 2. Затем запустите "VAL43_Полная_Переустановка.bat"
echo 3. Перезагрузите компьютер
echo.
pause
