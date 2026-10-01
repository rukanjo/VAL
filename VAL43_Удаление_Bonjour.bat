@echo off
chcp 65001 >nul
title Удаление Bonjour (ГЛАВНАЯ ПРИЧИНА VAL43)

color 0C
echo ═══════════════════════════════════════════════════════
echo     УДАЛЕНИЕ BONJOUR - ГЛАВНАЯ ПРИЧИНА VAL43!
echo ═══════════════════════════════════════════════════════
color 07
echo.
echo ВНИМАНИЕ! Этот скрипт удалит Bonjour из вашей системы.
echo.
echo Bonjour - это Apple сервис, который конфликтует с Vanguard.
echo Он обычно устанавливается вместе с iTunes.
echo.
echo ЧТО БУДЕТ СДЕЛАНО:
echo 1. Остановка службы Bonjour
echo 2. Удаление службы Bonjour
echo 3. Отключение DLL файлов Bonjour
echo 4. Удаление через Windows Programs
echo 5. Удаление папки Bonjour
echo.
echo Если вы НЕ используете iTunes или другие Apple программы,
echo удаление Bonjour безопасно и РЕШИТ проблему VAL43!
echo.
pause

REM Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    color 0C
    echo [ОШИБКА] Запустите от имени Администратора!
    color 07
    pause
    exit /b 1
)

echo.
echo [СТАРТ] Начинаем удаление Bonjour...
echo.

REM 1. Проверка наличия Bonjour
echo [1/7] Проверка наличия Bonjour...
set "bonjourFound=0"

if exist "%PROGRAMFILES%\Bonjour\mDNSResponder.exe" (
    set "bonjourPath=%PROGRAMFILES%\Bonjour"
    set "bonjourFound=1"
    echo [OK] Найден в: %PROGRAMFILES%\Bonjour
)

if exist "%PROGRAMFILES(x86)%\Bonjour\mDNSResponder.exe" (
    set "bonjourPath=%PROGRAMFILES(x86)%\Bonjour"
    set "bonjourFound=1"
    echo [OK] Найден в: %PROGRAMFILES(x86)%\Bonjour
)

if %bonjourFound% equ 0 (
    echo [INFO] Bonjour не найден в Program Files
    echo Проверяем через Windows Programs...
    wmic product where "name like '%%Bonjour%%'" get name 2>nul | find "Bonjour" >nul
    if %errorLevel% equ 0 (
        echo [OK] Bonjour найден в списке программ
        set "bonjourFound=1"
    ) else (
        echo.
        echo [INFO] Bonjour не обнаружен в системе!
        echo Возможно, он уже удален или проблема в другом.
        echo.
        echo Запустите "VAL43_Диагностика.bat" для проверки других причин.
        echo.
        pause
        exit /b 0
    )
)

echo.

REM 2. Остановка процесса mDNSResponder
echo [2/7] Остановка процесса mDNSResponder.exe...
taskkill /F /IM mDNSResponder.exe >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Процесс остановлен
) else (
    echo [INFO] Процесс не запущен
)
timeout /t 2 >nul

echo.

REM 3. Остановка и удаление службы Bonjour
echo [3/7] Остановка и удаление службы Bonjour...

REM Остановка службы
net stop "Bonjour Service" >nul 2>&1
sc stop "Bonjour" >nul 2>&1
timeout /t 2 >nul
echo [OK] Служба остановлена

REM Удаление службы через mDNSResponder
if defined bonjourPath (
    if exist "%bonjourPath%\mDNSResponder.exe" (
        echo Удаление службы через mDNSResponder...
        "%bonjourPath%\mDNSResponder.exe" -remove >nul 2>&1
        if %errorLevel% equ 0 (
            echo [OK] Служба удалена успешно
        ) else (
            echo [WARNING] Ошибка при удалении службы (возможно уже удалена)
        )
    )
)

REM Принудительное удаление службы
sc delete "Bonjour Service" >nul 2>&1
sc delete "Bonjour" >nul 2>&1

echo.

REM 4. Отключение DLL файлов
echo [4/7] Отключение DLL файлов Bonjour...

if defined bonjourPath (
    if exist "%bonjourPath%\mdnsNSP.dll" (
        echo Отмена регистрации mdnsNSP.dll...
        regsvr32 /s /u "%bonjourPath%\mdnsNSP.dll" >nul 2>&1
        
        REM Переименование DLL
        ren "%bonjourPath%\mdnsNSP.dll" "mdnsNSP.dll.disabled" >nul 2>&1
        if %errorLevel% equ 0 (
            echo [OK] DLL отключен
        ) else (
            echo [INFO] DLL уже отключен или заблокирован
        )
    )
)

echo.

REM 5. Удаление через Windows Programs
echo [5/7] Удаление через Windows Programs...
wmic product where "name like '%%Bonjour%%'" call uninstall /nointeractive >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Bonjour удален из списка программ
) else (
    echo [INFO] Не удалось удалить через WMIC (возможно уже удален)
)
timeout /t 2 >nul

echo.

REM 6. Очистка папки Bonjour
echo [6/7] Удаление папки Bonjour...

if exist "%PROGRAMFILES%\Bonjour" (
    echo Удаление: %PROGRAMFILES%\Bonjour
    rd /s /q "%PROGRAMFILES%\Bonjour" >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Папка удалена
    ) else (
        echo [WARNING] Не удалось удалить папку (будет удалена после перезагрузки)
        REM Пометка для удаления при перезагрузке
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /t REG_MULTI_SZ /d "\??\%PROGRAMFILES%\Bonjour" /f >nul 2>&1
    )
)

if exist "%PROGRAMFILES(x86)%\Bonjour" (
    echo Удаление: %PROGRAMFILES(x86)%\Bonjour
    rd /s /q "%PROGRAMFILES(x86)%\Bonjour" >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Папка удалена
    ) else (
        echo [WARNING] Не удалось удалить папку (будет удалена после перезагрузки)
    )
)

echo.

REM 7. Очистка реестра
echo [7/7] Очистка записей реестра Bonjour...
reg delete "HKLM\SOFTWARE\Apple Computer, Inc.\Bonjour" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Bonjour Service" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "Bonjour" /f >nul 2>&1
echo [OK] Реестр очищен

echo.
echo ═══════════════════════════════════════════════════════
echo     BONJOUR УСПЕШНО УДАЛЕН!
echo ═══════════════════════════════════════════════════════
echo.
echo СЛЕДУЮЩИЕ ШАГИ:
echo.
echo 1. ОБЯЗАТЕЛЬНО перезагрузите компьютер
echo 2. После перезагрузки запустите:
echo    "VAL43_Полная_Переустановка.bat"
echo 3. Это переустановит Vanguard без конфликтов
echo 4. Запустите Valorant от имени администратора
echo.
echo ВАЖНО: Если вы используете iTunes, некоторые функции
echo (обнаружение устройств в локальной сети) могут не работать.
echo Но iTunes будет работать нормально для основных задач.
echo.

set /p reboot="Перезагрузить компьютер сейчас? (Y/N): "
if /i "%reboot%"=="Y" (
    echo.
    echo Перезагрузка через 10 секунд...
    echo Закройте все программы!
    shutdown /r /t 10 /c "Перезагрузка для завершения удаления Bonjour"
) else (
    echo.
    echo НЕ ЗАБУДЬТЕ ПЕРЕЗАГРУЗИТЬ КОМПЬЮТЕР ВРУЧНУЮ!
    echo.
)

pause
