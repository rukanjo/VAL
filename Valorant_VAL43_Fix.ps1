# VALORANT VAL43 Error Fix Script
# Версия: 1.0
# Описание: Комплексное исправление ошибки VAL43

# Установка кодировки UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Цвета для вывода
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Заголовок
Clear-Host
Write-ColorOutput "===============================================" "Cyan"
Write-ColorOutput "    VALORANT VAL43 Error Fix Script (Advanced)" "Cyan"
Write-ColorOutput "===============================================" "Cyan"
Write-Host ""

# Проверка прав администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ColorOutput "[ОШИБКА] Скрипт должен быть запущен с правами администратора!" "Red"
    Write-ColorOutput "Нажмите ПКМ на файл и выберите 'Запуск от имени администратора'" "Yellow"
    Write-Host ""
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

Write-ColorOutput "Скрипт запущен с правами администратора" "Green"
Write-Host ""

# Функция для проверки существования процесса
function Stop-ProcessIfRunning {
    param([string]$ProcessName)
    
    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($process) {
        Write-ColorOutput "Остановка процесса: $ProcessName..." "Yellow"
        Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        return $true
    }
    return $false
}

# 1. Остановка процессов
Write-ColorOutput "[1/7] Остановка процессов Riot и Valorant..." "Cyan"
$stopped = $false
$stopped = Stop-ProcessIfRunning "RiotClientServices" -or $stopped
$stopped = Stop-ProcessIfRunning "Valorant" -or $stopped
$stopped = Stop-ProcessIfRunning "VALORANT-Win64-Shipping" -or $stopped
$stopped = Stop-ProcessIfRunning "RiotClientUx" -or $stopped

if ($stopped) {
    Write-ColorOutput "[OK] Процессы остановлены" "Green"
} else {
    Write-ColorOutput "[INFO] Процессы не запущены" "Gray"
}
Start-Sleep -Seconds 2

# 2. Остановка службы Vanguard
Write-Host ""
Write-ColorOutput "[2/7] Остановка службы Vanguard (VGC)..." "Cyan"
try {
    $vgcService = Get-Service -Name "vgc" -ErrorAction SilentlyContinue
    if ($vgcService) {
        if ($vgcService.Status -eq "Running") {
            Stop-Service -Name "vgc" -Force -ErrorAction Stop
            Write-ColorOutput "[OK] Служба Vanguard остановлена" "Green"
        } else {
            Write-ColorOutput "[INFO] Служба Vanguard уже остановлена" "Gray"
        }
    } else {
        Write-ColorOutput "[WARNING] Служба Vanguard не найдена (возможно не установлена)" "Yellow"
    }
} catch {
    Write-ColorOutput "[WARNING] Не удалось остановить Vanguard: $($_.Exception.Message)" "Yellow"
}
Start-Sleep -Seconds 2

# 3. Удаление файлов настроек
Write-Host ""
Write-ColorOutput "[3/7] Удаление временных файлов настроек Riot Client..." "Cyan"

$filesToDelete = @(
    "$env:LOCALAPPDATA\Riot Games\Riot Client\Data\RiotClientPrivateSettings.yaml",
    "$env:LOCALAPPDATA\Riot Games\Riot Client\Config\RiotClientSettings.yaml",
    "$env:LOCALAPPDATA\Riot Games\Riot Client\Data\RiotGamesPrivateSettings.yaml",
    "$env:LOCALAPPDATA\Riot Games\Riot Client\Data\RiotClientInstalls.json"
)

$deletedCount = 0
foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        try {
            Remove-Item -Path $file -Force -ErrorAction Stop
            $fileName = Split-Path $file -Leaf
            Write-ColorOutput "[OK] Удален: $fileName" "Green"
            $deletedCount++
        } catch {
            Write-ColorOutput "[ERROR] Не удалось удалить: $file" "Red"
        }
    }
}

if ($deletedCount -eq 0) {
    Write-ColorOutput "[INFO] Файлы не найдены или уже удалены" "Gray"
}

# 4. Перезапуск службы Vanguard
Write-Host ""
Write-ColorOutput "[4/7] Запуск службы Vanguard..." "Cyan"
try {
    $vgcService = Get-Service -Name "vgc" -ErrorAction SilentlyContinue
    if ($vgcService) {
        Start-Service -Name "vgc" -ErrorAction Stop
        Start-Sleep -Seconds 2
        $vgcService = Get-Service -Name "vgc"
        if ($vgcService.Status -eq "Running") {
            Write-ColorOutput "[OK] Служба Vanguard запущена успешно" "Green"
        } else {
            Write-ColorOutput "[WARNING] Служба Vanguard в состоянии: $($vgcService.Status)" "Yellow"
        }
    }
} catch {
    Write-ColorOutput "[WARNING] Vanguard запустится автоматически при старте игры" "Yellow"
}
Start-Sleep -Seconds 2

# 5. Сброс сетевых настроек
Write-Host ""
Write-ColorOutput "[5/7] Сброс сетевых настроек (это может занять время)..." "Cyan"

Write-Host "Сброс Winsock..."
netsh winsock reset | Out-Null

Write-Host "Сброс TCP/IP..."
netsh int ip reset | Out-Null

Write-Host "Освобождение IP адреса..."
ipconfig /release | Out-Null

Write-Host "Обновление IP адреса..."
ipconfig /renew | Out-Null

Write-Host "Очистка DNS кэша..."
ipconfig /flushdns | Out-Null

Write-Host "Сброс прокси..."
netsh winhttp reset proxy | Out-Null

Write-Host "Сброс брандмауэра Windows..."
netsh advfirewall reset | Out-Null

Write-ColorOutput "[OK] Сетевые настройки сброшены" "Green"

# 6. Проверка конфликтующих программ
Write-Host ""
Write-ColorOutput "[6/7] Проверка конфликтующих программ..." "Cyan"

$conflictingApps = @(
    "Bonjour",
    "National Instruments",
    "Guardian Browser",
    "Anti Cheat Expert"
)

$foundConflicts = @()
foreach ($app in $conflictingApps) {
    $installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$app*" } -ErrorAction SilentlyContinue
    if ($installed) {
        $foundConflicts += $app
        Write-ColorOutput "[WARNING] Обнаружена программа: $app" "Yellow"
    }
}

if ($foundConflicts.Count -eq 0) {
    Write-ColorOutput "[OK] Конфликтующие программы не обнаружены" "Green"
} else {
    Write-ColorOutput "[INFO] Рекомендуется удалить эти программы через Панель управления" "Yellow"
}

# 7. Диагностическая информация
Write-Host ""
Write-ColorOutput "[7/7] Сбор диагностической информации..." "Cyan"

Write-Host "Путь установки Valorant:"
$valorantPath = "$env:LOCALAPPDATA\Riot Games\Riot Client"
if (Test-Path $valorantPath) {
    Write-ColorOutput "[OK] Riot Client найден: $valorantPath" "Green"
} else {
    Write-ColorOutput "[WARNING] Riot Client не найден по стандартному пути" "Yellow"
}

Write-Host ""
Write-Host "Статус службы Vanguard:"
$vgcService = Get-Service -Name "vgc" -ErrorAction SilentlyContinue
if ($vgcService) {
    Write-ColorOutput "Статус: $($vgcService.Status)" "Cyan"
    Write-ColorOutput "Тип запуска: $($vgcService.StartType)" "Cyan"
} else {
    Write-ColorOutput "[WARNING] Служба не найдена" "Yellow"
}

# Завершение
Write-Host ""
Write-ColorOutput "===============================================" "Cyan"
Write-ColorOutput "     Исправление завершено!" "Green"
Write-ColorOutput "===============================================" "Cyan"
Write-Host ""

Write-ColorOutput "ВАЖНЫЕ ИНСТРУКЦИИ:" "Yellow"
Write-Host "1. Перезагрузите компьютер для применения всех изменений"
Write-Host "2. После перезагрузки запустите Riot Client от имени администратора"
Write-Host "3. Войдите в свой аккаунт"
Write-Host "4. Запустите Valorant"
Write-Host ""

if ($foundConflicts.Count -gt 0) {
    Write-ColorOutput "ВНИМАНИЕ: Обнаружены конфликтующие программы:" "Red"
    foreach ($app in $foundConflicts) {
        Write-Host "  - $app"
    }
    Write-Host "Рекомендуется удалить их для предотвращения проблем в будущем"
    Write-Host ""
}

# Предложение перезагрузки
$restart = Read-Host "Хотите перезагрузить компьютер сейчас? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Write-ColorOutput "Перезагрузка через 10 секунд..." "Yellow"
    shutdown /r /t 10
} else {
    Write-ColorOutput "Не забудьте перезагрузить компьютер вручную!" "Yellow"
}

Write-Host ""
Read-Host "Нажмите Enter для выхода"
