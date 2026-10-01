@echo off
chcp 65001 >nul
echo ===============================================
echo     VALORANT VAL43 Error Fix Script
echo ===============================================
echo.
echo Этот скрипт выполнит следующие действия:
echo 1. Остановка Riot Client и Valorant
echo 2. Удаление временных файлов настроек Riot
echo 3. Перезапуск службы Vanguard (VGC)
echo 4. Сброс сетевых настроек
echo 5. Очистка DNS кэша
echo.
pause

REM Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ОШИБКА] Запустите скрипт от имени Администратора!
    echo Нажмите ПКМ на файл и выберите "Запуск от имени администратора"
    echo.
    pause
    exit /b 1
)

echo.
echo [1/6] Остановка процессов Riot Client и Valorant...
taskkill /F /IM "RiotClientServices.exe" >nul 2>&1
taskkill /F /IM "Valorant.exe" >nul 2>&1
taskkill /F /IM "VALORANT-Win64-Shipping.exe" >nul 2>&1
timeout /t 2 >nul
echo [OK] Процессы остановлены

echo.
echo [2/6] Остановка службы Vanguard...
net stop vgc >nul 2>&1
timeout /t 2 >nul
echo [OK] Vanguard остановлен

echo.
echo [3/6] Удаление файлов настроек Riot Client...
set "RiotDataPath=%LOCALAPPDATA%\Riot Games\Riot Client\Data"
set "RiotConfigPath=%LOCALAPPDATA%\Riot Games\Riot Client\Config"

if exist "%RiotDataPath%\RiotClientPrivateSettings.yaml" (
    del /F /Q "%RiotDataPath%\RiotClientPrivateSettings.yaml"
    echo [OK] Удален RiotClientPrivateSettings.yaml
) else (
    echo [INFO] RiotClientPrivateSettings.yaml не найден
)

if exist "%RiotConfigPath%\RiotClientSettings.yaml" (
    del /F /Q "%RiotConfigPath%\RiotClientSettings.yaml"
    echo [OK] Удален RiotClientSettings.yaml
) else (
    echo [INFO] RiotClientSettings.yaml не найден
)

if exist "%RiotDataPath%\RiotGamesPrivateSettings.yaml" (
    del /F /Q "%RiotDataPath%\RiotGamesPrivateSettings.yaml"
    echo [OK] Удален RiotGamesPrivateSettings.yaml
) else (
    echo [INFO] RiotGamesPrivateSettings.yaml не найден
)

echo.
echo [4/6] Запуск службы Vanguard...
net start vgc >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Vanguard запущен успешно
) else (
    echo [WARNING] Не удалось запустить Vanguard. Он запустится автоматически при старте игры.
)
timeout /t 2 >nul

echo.
echo [5/6] Сброс сетевых настроек...
echo Сброс Winsock...
netsh winsock reset
echo.
echo Сброс IP настроек...
netsh int ip reset
echo.
echo Освобождение IP адреса...
ipconfig /release
echo.
echo Обновление IP адреса...
ipconfig /renew
echo.
echo Очистка DNS кэша...
ipconfig /flushdns
echo.
echo Сброс прокси...
netsh winhttp reset proxy
echo.
echo Сброс брандмауэра...
netsh advfirewall reset

echo.
echo [6/6] Проверка конфликтующих программ...
echo Проверка на наличие Bonjour (может конфликтовать с Vanguard)...
wmic product where "name like '%%Bonjour%%'" get name 2>nul | find "Bonjour" >nul
if %errorLevel% equ 0 (
    echo [WARNING] Обнаружен Bonjour! Рекомендуется удалить через Панель управления.
) else (
    echo [OK] Bonjour не обнаружен
)

echo.
echo ===============================================
echo     Исправление завершено!
echo ===============================================
echo.
echo ВАЖНО: Для применения изменений требуется перезагрузка ПК!
echo.
echo После перезагрузки:
echo 1. Запустите Riot Client от имени администратора
echo 2. Войдите в аккаунт
echo 3. Запустите Valorant
echo.
echo Хотите перезагрузить компьютер сейчас? (Y/N)
set /p restart="Ваш выбор: "
if /i "%restart%"=="Y" (
    echo Перезагрузка через 10 секунд...
    shutdown /r /t 10
) else (
    echo Не забудьте перезагрузить компьютер вручную!
)

echo.
pause
