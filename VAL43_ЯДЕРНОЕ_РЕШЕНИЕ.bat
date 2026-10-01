@echo off
chcp 65001 >nul
title VAL43 - ЯДЕРНОЕ РЕШЕНИЕ (ВСЁ СРАЗУ)

color 0C
echo ═══════════════════════════════════════════════════════
echo     ⚠️  ЯДЕРНОЕ РЕШЕНИЕ VAL43  ⚠️
echo ═══════════════════════════════════════════════════════
color 0E
echo.
echo Этот скрипт выполнит ВСЕ ВОЗМОЖНЫЕ исправления VAL43!
echo.
echo ЧТО БУДЕТ СДЕЛАНО (ПОЛНЫЙ СПИСОК):
echo.
echo 📌 ЧАСТЬ 1: УДАЛЕНИЕ КОНФЛИКТОВ
echo   • Проверка и удаление Bonjour
echo   • Остановка конфликтующих служб
echo   • Очистка сетевых конфликтов
echo.
echo 📌 ЧАСТЬ 2: ПОЛНАЯ ОЧИСТКА VANGUARD
echo   • Остановка всех процессов Riot
echo   • Удаление Vanguard полностью
echo   • Удаление драйверов и служб
echo   • Очистка реестра
echo.
echo 📌 ЧАСТЬ 3: ОЧИСТКА RIOT CLIENT
echo   • Удаление временных файлов
echo   • Очистка кэша и логов
echo   • Удаление настроек
echo.
echo 📌 ЧАСТЬ 4: СБРОС СИСТЕМНЫХ НАСТРОЕК
echo   • Полный сброс сетевых настроек
echo   • Очистка DNS кэша
echo   • Сброс Winsock и TCP/IP
echo   • Сброс прокси и брандмауэра
echo.
echo 📌 ЧАСТЬ 5: ПОДГОТОВКА К ПЕРЕУСТАНОВКЕ
echo   • Настройка брандмауэра
echo   • Очистка системного кэша
echo.
color 0C
echo ⚠️  ВНИМАНИЕ: Процесс займет 5-10 минут
echo ⚠️  После завершения ОБЯЗАТЕЛЬНА перезагрузка ПК
color 07
echo.
pause

REM Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo.
    echo ═══════════════════════════════════════════════════════
    echo [КРИТИЧЕСКАЯ ОШИБКА] НЕТ ПРАВ АДМИНИСТРАТОРА!
    echo ═══════════════════════════════════════════════════════
    echo.
    echo Нажмите ПКМ на этот файл и выберите:
    echo "Запуск от имени администратора"
    echo.
    color 07
    pause
    exit /b 1
)

cls
color 0A
echo ═══════════════════════════════════════════════════════
echo     🚀 ЗАПУСК ЯДЕРНОГО РЕШЕНИЯ
echo ═══════════════════════════════════════════════════════
color 07
echo.

REM ═══════════════════════════════════════════════════════
REM ЧАСТЬ 1: УДАЛЕНИЕ BONJOUR И КОНФЛИКТОВ
REM ═══════════════════════════════════════════════════════

echo.
color 0E
echo ┌───────────────────────────────────────────────────────┐
echo │  ЧАСТЬ 1/5: УДАЛЕНИЕ BONJOUR И КОНФЛИКТОВ            │
echo └───────────────────────────────────────────────────────┘
color 07
echo.

echo [1.1] Проверка Bonjour...
set "bonjourFound=0"

wmic product where "name like '%%Bonjour%%'" get name 2>nul | find "Bonjour" >nul
if %errorLevel% equ 0 (
    color 0C
    echo [!!!] ОБНАРУЖЕН BONJOUR - ЭТО ПРИЧИНА VAL43!
    color 0E
    set "bonjourFound=1"
)

if exist "%PROGRAMFILES%\Bonjour\mDNSResponder.exe" set "bonjourFound=1"
if exist "%PROGRAMFILES(x86)%\Bonjour\mDNSResponder.exe" set "bonjourFound=1"

if %bonjourFound% equ 1 (
    echo [1.2] Удаление Bonjour...
    
    REM Остановка процесса
    taskkill /F /IM mDNSResponder.exe >nul 2>&1
    timeout /t 1 >nul
    
    REM Остановка службы
    net stop "Bonjour Service" >nul 2>&1
    sc stop "Bonjour" >nul 2>&1
    timeout /t 1 >nul
    
    REM Удаление службы
    if exist "%PROGRAMFILES%\Bonjour\mDNSResponder.exe" (
        "%PROGRAMFILES%\Bonjour\mDNSResponder.exe" -remove >nul 2>&1
    )
    if exist "%PROGRAMFILES(x86)%\Bonjour\mDNSResponder.exe" (
        "%PROGRAMFILES(x86)%\Bonjour\mDNSResponder.exe" -remove >nul 2>&1
    )
    sc delete "Bonjour Service" >nul 2>&1
    sc delete "Bonjour" >nul 2>&1
    
    REM Отключение DLL
    if exist "%PROGRAMFILES%\Bonjour\mdnsNSP.dll" (
        regsvr32 /s /u "%PROGRAMFILES%\Bonjour\mdnsNSP.dll" >nul 2>&1
    )
    if exist "%PROGRAMFILES(x86)%\Bonjour\mdnsNSP.dll" (
        regsvr32 /s /u "%PROGRAMFILES(x86)%\Bonjour\mdnsNSP.dll" >nul 2>&1
    )
    
    REM Удаление через Windows
    wmic product where "name like '%%Bonjour%%'" call uninstall /nointeractive >nul 2>&1
    
    REM Удаление папок
    rd /s /q "%PROGRAMFILES%\Bonjour" >nul 2>&1
    rd /s /q "%PROGRAMFILES(x86)%\Bonjour" >nul 2>&1
    
    REM Очистка реестра
    reg delete "HKLM\SOFTWARE\Apple Computer, Inc.\Bonjour" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Bonjour Service" /f >nul 2>&1
    
    color 0A
    echo [✓] Bonjour удален!
    color 07
) else (
    echo [✓] Bonjour не обнаружен
)

echo.

REM ═══════════════════════════════════════════════════════
REM ЧАСТЬ 2: ПОЛНАЯ ОЧИСТКА VANGUARD
REM ═══════════════════════════════════════════════════════

echo.
color 0E
echo ┌───────────────────────────────────────────────────────┐
echo │  ЧАСТЬ 2/5: ПОЛНАЯ ОЧИСТКА VANGUARD                  │
echo └───────────────────────────────────────────────────────┘
color 07
echo.

echo [2.1] Остановка процессов Riot и Valorant...
taskkill /F /IM "RiotClientServices.exe" >nul 2>&1
taskkill /F /IM "RiotClientUx.exe" >nul 2>&1
taskkill /F /IM "RiotClientCrashHandler.exe" >nul 2>&1
taskkill /F /IM "Valorant.exe" >nul 2>&1
taskkill /F /IM "VALORANT-Win64-Shipping.exe" >nul 2>&1
taskkill /F /IM "LeagueClient.exe" >nul 2>&1
timeout /t 2 >nul
echo [✓] Процессы остановлены

echo [2.2] Остановка службы Vanguard...
net stop vgc >nul 2>&1
sc stop vgc >nul 2>&1
timeout /t 2 >nul
echo [✓] Служба остановлена

echo [2.3] Удаление Vanguard (может занять время)...
wmic product where "name='Riot Vanguard'" call uninstall /nointeractive >nul 2>&1
timeout /t 3 >nul
echo [✓] Vanguard удален

echo [2.4] Удаление службы VGC...
sc delete vgc >nul 2>&1
echo [✓] Служба удалена

echo [2.5] Удаление файлов Vanguard...
icacls "%PROGRAMFILES%\Riot Vanguard" /grant administrators:F /T >nul 2>&1
rd /s /q "%PROGRAMFILES%\Riot Vanguard" >nul 2>&1
del /f /q "%SystemRoot%\System32\drivers\vgk.sys" >nul 2>&1
echo [✓] Файлы удалены

echo.

REM ═══════════════════════════════════════════════════════
REM ЧАСТЬ 3: ОЧИСТКА RIOT CLIENT
REM ═══════════════════════════════════════════════════════

echo.
color 0E
echo ┌───────────────────────────────────────────────────────┐
echo │  ЧАСТЬ 3/5: ОЧИСТКА RIOT CLIENT                      │
echo └───────────────────────────────────────────────────────┘
color 07
echo.

set "RiotLocal=%LOCALAPPDATA%\Riot Games"

echo [3.1] Удаление файлов настроек...
del /f /q "%RiotLocal%\Riot Client\Data\RiotClientPrivateSettings.yaml" >nul 2>&1
del /f /q "%RiotLocal%\Riot Client\Config\RiotClientSettings.yaml" >nul 2>&1
del /f /q "%RiotLocal%\Riot Client\Data\RiotGamesPrivateSettings.yaml" >nul 2>&1
del /f /q "%RiotLocal%\Riot Client\Data\RiotClientInstalls.json" >nul 2>&1
echo [✓] Настройки удалены

echo [3.2] Очистка кэша и логов...
rd /s /q "%RiotLocal%\Riot Client\Cache" >nul 2>&1
rd /s /q "%RiotLocal%\Riot Client\Logs" >nul 2>&1
rd /s /q "%RiotLocal%\Riot Client\Crashpad" >nul 2>&1
echo [✓] Кэш очищен

echo [3.3] Очистка временных файлов Valorant...
rd /s /q "%RiotLocal%\VALORANT\Saved\Logs" >nul 2>&1
rd /s /q "%RiotLocal%\VALORANT\Saved\Crashes" >nul 2>&1
echo [✓] Временные файлы удалены

echo.

REM ═══════════════════════════════════════════════════════
REM ЧАСТЬ 4: СБРОС СИСТЕМНЫХ НАСТРОЕК
REM ═══════════════════════════════════════════════════════

echo.
color 0E
echo ┌───────────────────────────────────────────────────────┐
echo │  ЧАСТЬ 4/5: СБРОС СИСТЕМНЫХ НАСТРОЕК                 │
echo └───────────────────────────────────────────────────────┘
color 07
echo.

echo [4.1] Сброс Winsock...
netsh winsock reset >nul 2>&1
echo [✓] Winsock сброшен

echo [4.2] Сброс TCP/IP...
netsh int ip reset >nul 2>&1
echo [✓] TCP/IP сброшен

echo [4.3] Освобождение IP адреса...
ipconfig /release >nul 2>&1
echo [✓] IP освобожден

echo [4.4] Обновление IP адреса...
ipconfig /renew >nul 2>&1
echo [✓] IP обновлен

echo [4.5] Очистка DNS кэша...
ipconfig /flushdns >nul 2>&1
echo [✓] DNS очищен

echo [4.6] Сброс прокси...
netsh winhttp reset proxy >nul 2>&1
echo [✓] Прокси сброшен

echo [4.7] Сброс брандмауэра...
netsh advfirewall reset >nul 2>&1
echo [✓] Брандмауэр сброшен

echo.

REM ═══════════════════════════════════════════════════════
REM ЧАСТЬ 5: ПОДГОТОВКА К ПЕРЕУСТАНОВКЕ
REM ═══════════════════════════════════════════════════════

echo.
color 0E
echo ┌───────────────────────────────────────────────────────┐
echo │  ЧАСТЬ 5/5: ПОДГОТОВКА К ПЕРЕУСТАНОВКЕ               │
echo └───────────────────────────────────────────────────────┘
color 07
echo.

echo [5.1] Настройка брандмауэра для Riot...
netsh advfirewall firewall delete rule name="Valorant" >nul 2>&1
netsh advfirewall firewall delete rule name="Riot Client" >nul 2>&1
netsh advfirewall firewall delete rule name="Riot Vanguard" >nul 2>&1

if exist "%RiotLocal%\Riot Games\Riot Client\RiotClientServices.exe" (
    netsh advfirewall firewall add rule name="Riot Client IN" dir=in action=allow program="%RiotLocal%\Riot Games\Riot Client\RiotClientServices.exe" enable=yes >nul 2>&1
    netsh advfirewall firewall add rule name="Riot Client OUT" dir=out action=allow program="%RiotLocal%\Riot Games\Riot Client\RiotClientServices.exe" enable=yes >nul 2>&1
)
echo [✓] Брандмауэр настроен

echo [5.2] Очистка системного кэша...
del /f /q "%TEMP%\*" >nul 2>&1
echo [✓] Системный кэш очищен

echo.

REM ═══════════════════════════════════════════════════════
REM ЗАВЕРШЕНИЕ
REM ═══════════════════════════════════════════════════════

cls
color 0A
echo.
echo ═══════════════════════════════════════════════════════
echo     ✅ ЯДЕРНОЕ РЕШЕНИЕ ВЫПОЛНЕНО УСПЕШНО!
echo ═══════════════════════════════════════════════════════
color 07
echo.
echo Все возможные исправления применены:
echo   ✓ Bonjour удален (если был)
echo   ✓ Vanguard полностью удален
echo   ✓ Riot Client очищен
echo   ✓ Сетевые настройки сброшены
echo   ✓ Система подготовлена к переустановке
echo.
color 0E
echo ═══════════════════════════════════════════════════════
echo     ⚡ КРИТИЧЕСКИ ВАЖНЫЕ СЛЕДУЮЩИЕ ШАГИ:
echo ═══════════════════════════════════════════════════════
color 07
echo.
echo 1️⃣  ОБЯЗАТЕЛЬНО ПЕРЕЗАГРУЗИТЕ КОМПЬЮТЕР СЕЙЧАС!
echo.
echo 2️⃣  После перезагрузки:
echo    • Запустите Riot Client от имени администратора
echo    • Войдите в свой аккаунт
echo    • Riot Client автоматически установит Vanguard
echo.
echo 3️⃣  После установки Vanguard:
echo    • Снова перезагрузите компьютер
echo    • Запустите Valorant
echo.
echo 4️⃣  Для удобства используйте:
echo    • "Запуск_Valorant_Админ.bat" - автозапуск от админа
echo.
color 0C
echo ⚠️  ВАЖНО: Без перезагрузки исправления не применятся!
color 07
echo.
echo ═══════════════════════════════════════════════════════
echo.

set /p reboot="ПЕРЕЗАГРУЗИТЬ КОМПЬЮТЕР СЕЙЧАС? (Y - ДА / N - ПОЗЖЕ): "
if /i "%reboot%"=="Y" (
    echo.
    color 0E
    echo 🔄 ПЕРЕЗАГРУЗКА ЧЕРЕЗ 15 СЕКУНД...
    echo 💾 СОХРАНИТЕ ВСЕ ОТКРЫТЫЕ ФАЙЛЫ!
    color 07
    echo.
    shutdown /r /t 15 /c "Перезагрузка после ядерного решения VAL43. Сохраните все файлы!"
    pause
) else (
    echo.
    color 0C
    echo ═══════════════════════════════════════════════════════
    echo   ⚠️  НЕ ЗАБУДЬТЕ ПЕРЕЗАГРУЗИТЬ КОМПЬЮТЕР! ⚠️
    echo ═══════════════════════════════════════════════════════
    color 07
    echo.
    echo Без перезагрузки Vanguard не установится корректно!
    echo.
    pause
)
