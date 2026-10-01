# SPDX-License-Identifier: MIT
# VAL43 Fix 3.0
# Local helper for the Valorant VAL 43 error. Not affiliated with Riot Games.
# Does not download files, does not ask for a Riot password, does not remove the game.

#Requires -Version 5.1
param(
    [ValidateSet('Diagnose', 'Quick', 'Standard', 'Bonjour', 'Vanguard', 'Full', 'Launch')]
    [string]$Action
)

$ErrorActionPreference = 'Continue'
try { & chcp.com 65001 > $null } catch { }
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Script:Version = '3.0.0'
$Script:LogFile = Join-Path $PSScriptRoot 'logs\val43-fix.log'
$Script:InstalledApps = $null

function Write-Log {
    param([string]$Message)
    $dir = Split-Path -Parent $Script:LogFile
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $Script:LogFile -Value $line -Encoding UTF8
}

function Write-Ok([string]$Message) {
    Write-Host "  [ok] $Message" -ForegroundColor Green
    Write-Log "OK   $Message"
}
function Write-Warn([string]$Message) {
    Write-Host "  [!]  $Message" -ForegroundColor Yellow
    Write-Log "WARN $Message"
}
function Write-Bad([string]$Message) {
    Write-Host "  [x]  $Message" -ForegroundColor Red
    Write-Log "ERR  $Message"
}
function Write-Info([string]$Message) {
    Write-Host "  [i]  $Message" -ForegroundColor Gray
    Write-Log "INFO $Message"
}
function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host ">> $Message" -ForegroundColor Cyan
    Write-Log "STEP $Message"
}

function Test-IsAdmin {
    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Confirm-Action {
    param([string[]]$Lines)
    Write-Host ""
    foreach ($line in $Lines) {
        Write-Host "  $line" -ForegroundColor Yellow
    }
    Write-Host ""
    $answer = Read-Host "Введите ДА или YES, чтобы продолжить"
    $value = if ($answer) { $answer.Trim() } else { '' }
    $accepted = @('ДА', 'да', 'Да', 'YES', 'yes', 'Yes', 'DA', 'da')
    if ($accepted -contains $value) {
        Write-Log "Confirmed: $value"
        return $true
    }
    Write-Info "Отменено. Ничего не изменено."
    return $false
}

function Confirm-YesNo {
    param([string]$Prompt)
    $answer = Read-Host $Prompt
    return ($answer -match '^(y|Y|yes|YES|д|Д|да|ДА)$')
}

function Get-ScText {
    param([string]$Name, [switch]$Config)
    $exe = Join-Path $env:SystemRoot 'System32\sc.exe'
    if ($Config) {
        return (& $exe qc $Name 2>&1 | Out-String)
    }
    return (& $exe query $Name 2>&1 | Out-String)
}

function Get-ScState {
    param([string]$Name)
    $out = Get-ScText -Name $Name
    if ($out -match '1060|FAILED') { return 'missing' }
    if ($out -match 'RUNNING') { return 'running' }
    if ($out -match 'STOPPED') { return 'stopped' }
    return 'unknown'
}

function Get-ScStart {
    param([string]$Name)
    $out = Get-ScText -Name $Name -Config
    if ($out -match 'DISABLED') { return 'disabled' }
    if ($out -match 'AUTO_START') { return 'auto' }
    if ($out -match 'DEMAND_START') { return 'manual' }
    if ($out -match 'SYSTEM_START') { return 'system' }
    if ($out -match 'BOOT_START') { return 'boot' }
    return 'unknown'
}

function Get-InstalledApps {
    param([switch]$Refresh)
    if (-not $Refresh -and $Script:InstalledApps) {
        return $Script:InstalledApps
    }
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $Script:InstalledApps = @(
        foreach ($path in $paths) {
            Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName }
        }
    )
    return $Script:InstalledApps
}

function Find-ValorantExe {
    if ($Script:CachedValorantExe -and (Test-Path -LiteralPath $Script:CachedValorantExe)) {
        return $Script:CachedValorantExe
    }
    $candidates = New-Object System.Collections.Generic.List[string]
    $jsonPath = Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Data\RiotClientInstalls.json'
    if (Test-Path -LiteralPath $jsonPath) {
        $text = Get-Content -LiteralPath $jsonPath -Raw -ErrorAction SilentlyContinue
        if ($text) {
            $pattern = '(?i)[A-Za-z]:\\\\(?:[^"\\]|\\\\)*VALORANT\\\\live'
            foreach ($match in [regex]::Matches($text, $pattern)) {
                $root = $match.Value.Replace('\\', '\')
                $candidates.Add((Join-Path $root 'VALORANT.exe'))
            }
        }
    }
    $candidates.Add((Join-Path $env:SystemDrive 'Riot Games\VALORANT\live\VALORANT.exe'))
    foreach ($path in $candidates) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            $Script:CachedValorantExe = $path
            return $path
        }
    }
    return $null
}

function Invoke-UninstallCommand {
    param([string]$Command)
    $Command = if ($Command) { $Command.Trim() } else { '' }
    if (-not $Command) { return $false }

    $exe = $null
    $argLine = ''
    if ($Command.StartsWith('"')) {
        $end = $Command.IndexOf('"', 1)
        if ($end -gt 1) {
            $exe = $Command.Substring(1, $end - 1)
            $argLine = $Command.Substring($end + 1).Trim()
        }
    }
    if (-not $exe) {
        $parts = $Command -split '\s+', 2
        $exe = $parts[0]
        if ($parts.Count -gt 1) { $argLine = $parts[1] }
    }

    $exeExists = Test-Path -LiteralPath $exe
    if (-not $exeExists) {
        $cmd = Get-Command $exe -ErrorAction SilentlyContinue
        if ($cmd) { $exe = $cmd.Source; $exeExists = $true }
    }
    if (-not $exeExists) {
        Write-Warn "Деинсталлятор не найден: $exe"
        return $false
    }

    Write-Info "Запуск официального деинсталлятора: $exe $argLine"
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $exe
    $startInfo.Arguments = $argLine
    $startInfo.UseShellExecute = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $startInfo
    if (-not $proc.Start()) {
        Write-Warn "Не удалось запустить деинсталлятор"
        return $false
    }
    $proc.WaitForExit()
    Write-Log "Uninstaller exit code: $($proc.ExitCode)"
    # 0 = success, 3010 = success but reboot required, 1605 = MSI product already absent
    return ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010 -or $proc.ExitCode -eq 1605)
}

function Get-UninstallCommand {
    param($Entry)
    $cmd = $Entry.QuietUninstallString
    if (-not $cmd) { $cmd = $Entry.UninstallString }
    if (-not $cmd) { return $null }
    if (-not $Entry.QuietUninstallString -and $cmd -match 'msiexec' -and $cmd -notmatch '(?i)(^|\s)/q') {
        $cmd = $cmd + ' /qn /norestart'
    }
    return $cmd
}

function Stop-RiotProcesses {
    $names = @(
        'RiotClientServices',
        'RiotClientUx',
        'RiotClientUxRender',
        'RiotClientCrashHandler',
        'VALORANT',
        'VALORANT-Win64-Shipping',
        'vgtray',
        'LeagueClient',
        'LeagueClientUx',
        'League of Legends'
    )
    $stopped = @()
    foreach ($name in $names) {
        $procs = @(Get-Process -Name $name -ErrorAction SilentlyContinue)
        if ($procs.Count -gt 0) {
            $procs | Stop-Process -Force -ErrorAction SilentlyContinue
            $stopped += $name
        }
    }
    Start-Sleep -Seconds 2
    if ($stopped.Count -gt 0) {
        Write-Ok ("Остановлены процессы: " + ($stopped -join ', '))
    } else {
        Write-Info "Процессы Riot не были запущены"
    }
}

function Clear-RiotClientState {
    param([switch]$IncludeCache)

    $files = @(
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Data\RiotClientPrivateSettings.yaml'),
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Config\RiotClientSettings.yaml'),
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Data\RiotGamesPrivateSettings.yaml'),
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Data\RiotClientInstalls.json')
    )
    foreach ($file in $files) {
        if (Test-Path -LiteralPath $file) {
            Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $file) {
                Write-Warn "Не удалось удалить $file"
            } else {
                Write-Ok ("Удалён файл настроек: " + (Split-Path -Leaf $file))
            }
        }
    }

    if (-not $IncludeCache) { return }

    $dirs = @(
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Cache'),
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Logs'),
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Crashpad'),
        (Join-Path $env:LOCALAPPDATA 'VALORANT\Saved\Logs'),
        (Join-Path $env:LOCALAPPDATA 'VALORANT\Saved\Crashes')
    )
    foreach ($dir in $dirs) {
        if (Test-Path -LiteralPath $dir) {
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Ok "Очищено: $dir"
        }
    }
}

function Reset-NetworkStack {
    Write-Step "Сброс сетевых настроек"
    Write-Info "Winsock, TCP/IP, выданный IP, DNS, прокси WinHTTP и брандмауэр."
    & netsh.exe winsock reset
    $ipLog = Join-Path $env:TEMP 'val43-ip-reset.txt'
    & netsh.exe int ip reset $ipLog
    Write-Info "Освобождение и обновление IP. Связь может пропасть на несколько секунд."
    & ipconfig.exe /release
    & ipconfig.exe /renew
    & ipconfig.exe /flushdns
    & netsh.exe winhttp reset proxy
    & netsh.exe advfirewall reset
    Write-Ok "Сетевые настройки сброшены. Они применятся после перезагрузки."
    Write-Warn "VPN и сетевой фильтр антивируса иногда приходится поставить заново."
}

function Add-RiotFirewallRules {
    $targets = @()
    $client = Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\RiotClientServices.exe'
    if (Test-Path -LiteralPath $client) { $targets += $client }

    $valorant = Find-ValorantExe
    if ($valorant) { $targets += $valorant }

    $vgc = Join-Path $env:ProgramFiles 'Riot Vanguard\vgc.exe'
    if (Test-Path -LiteralPath $vgc) { $targets += $vgc }

    if ($targets.Count -eq 0) {
        Write-Info "Файлы Riot не найдены, правила брандмауэра не добавлялись"
        return
    }

    foreach ($exe in $targets) {
        $leaf = Split-Path -Leaf $exe
        foreach ($dir in @('IN', 'OUT')) {
            $rule = "VAL43 $leaf $dir"
            $direction = if ($dir -eq 'IN') { 'in' } else { 'out' }
            & netsh.exe advfirewall firewall delete rule "name=$rule" | Out-Null
            & netsh.exe advfirewall firewall add rule "name=$rule" "dir=$direction" "action=allow" "program=`"$exe`"" "enable=yes" | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Warn "Не удалось добавить правило брандмауэра: $rule"
            }
        }
        Write-Ok "Разрешено в брандмауэре: $leaf"
    }
}

function Restart-VanguardService {
    if ((Get-ScState 'vgc') -eq 'missing') {
        Write-Warn "Служба vgc не установлена. Её поставит Riot Client после входа в игру."
        return
    }
    # "start= auto" must stay one token. PowerShell otherwise splits it and sc.exe rejects the call.
    & cmd.exe /c "sc config vgc start= auto" | Out-Null
    & cmd.exe /c "sc stop vgc" | Out-Null
    Start-Sleep -Seconds 1
    & cmd.exe /c "sc start vgc" | Out-Null
    Start-Sleep -Seconds 2
    $state = Get-ScState 'vgc'
    if ($state -eq 'running') {
        Write-Ok "Служба vgc запущена, автозапуск включён"
    } else {
        Write-Warn "vgc сейчас в состоянии «$state». Часто это проходит после перезагрузки."
    }
}

function Get-BonjourState {
    $dirs = New-Object System.Collections.Generic.List[string]
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $path = Join-Path $root 'Bonjour'
        if (Test-Path -LiteralPath $path) { $dirs.Add($path) | Out-Null }
    }

    $apps = @(Get-InstalledApps | Where-Object { $_.DisplayName -like '*Bonjour*' })
    $service = Get-ScState 'Bonjour Service'
    $present = ($dirs.Count -gt 0) -or ($apps.Count -gt 0) -or ($service -ne 'missing')
    return [pscustomobject]@{
        Present = [bool]$present
        Dirs    = @($dirs)
        Apps    = @($apps)
        Service = $service
    }
}

function Remove-Bonjour {
    $state = Get-BonjourState
    if (-not $state.Present) {
        Write-Info "Bonjour не найден"
        return $false
    }

    Get-Process -Name 'mDNSResponder' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    $sc = Join-Path $env:SystemRoot 'System32\sc.exe'
    foreach ($name in @('Bonjour Service', 'Bonjour')) {
        & $sc stop $name | Out-Null
    }

    foreach ($app in $state.Apps) {
        $cmd = Get-UninstallCommand $app
        if ($cmd) { Invoke-UninstallCommand $cmd | Out-Null }
    }

    foreach ($name in @('Bonjour Service', 'Bonjour')) {
        & $sc delete $name | Out-Null
    }

    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $dir = Join-Path $root 'Bonjour'
        if (Test-Path -LiteralPath $dir) {
            Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $dir) {
                Write-Warn "Папка занята и удалится после перезагрузки: $dir"
            } else {
                Write-Ok "Удалена папка: $dir"
            }
        }
    }

    $keys = @(
        'HKLM:\SOFTWARE\Apple Computer, Inc.\Bonjour',
        'HKLM:\SOFTWARE\WOW6432Node\Apple Computer, Inc.\Bonjour',
        'HKLM:\SYSTEM\CurrentControlSet\Services\Bonjour Service'
    )
    foreach ($key in $keys) {
        if (Test-Path -LiteralPath $key) {
            Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction SilentlyContinue
            Write-Ok "Удалена запись реестра: $key"
        }
    }
    $runKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    if (Get-ItemProperty -Path $runKey -Name 'Bonjour' -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $runKey -Name 'Bonjour' -ErrorAction SilentlyContinue
    }

    Get-InstalledApps -Refresh | Out-Null
    $left = Get-BonjourState
    if ($left.Present) {
        Write-Warn "Следы Bonjour ещё есть. Перезагрузите ПК и запустите этот пункт ещё раз."
    } else {
        Write-Ok "Bonjour удалён"
    }
    return $true
}

function Uninstall-VanguardOfficial {
    $apps = @(Get-InstalledApps -Refresh | Where-Object { $_.DisplayName -like 'Riot Vanguard*' })
    if ($apps.Count -eq 0) {
        $folder = Join-Path $env:ProgramFiles 'Riot Vanguard'
        if (Test-Path -LiteralPath $folder) {
            Write-Warn "Папка Vanguard есть, а запись удаления не найдена: $folder"
            Write-Warn "Удалите «Riot Vanguard» через Параметры Windows → Приложения и перезагрузите ПК."
        } else {
            Write-Info "Riot Vanguard не установлен. Клиент поставит его при запуске игры."
        }
        return
    }

    Stop-RiotProcesses
    $sc = Join-Path $env:SystemRoot 'System32\sc.exe'
    & $sc stop vgc | Out-Null

    $ok = $false
    foreach ($app in $apps) {
        $cmd = Get-UninstallCommand $app
        if ($cmd -and (Invoke-UninstallCommand $cmd)) { $ok = $true }
    }

    Get-InstalledApps -Refresh | Out-Null
    $still = @(Get-InstalledApps | Where-Object { $_.DisplayName -like 'Riot Vanguard*' })
    if ($still.Count -eq 0) {
        Write-Ok "Vanguard удалён штатным деинсталлятором. Драйвер снимет перезагрузка."
    } elseif ($ok) {
        Write-Warn "Деинсталлятор отработал, но запись ещё видна. Перезагрузите ПК."
    } else {
        Write-Bad "Не удалось удалить Vanguard автоматически."
        Write-Info "Параметры Windows → Приложения → Riot Vanguard → Удалить."
    }
    Write-Info "Папка игры VALORANT и прогресс аккаунта не удалялись."
}

function Request-Reboot {
    param([string]$Reason)
    Write-Host ""
    Write-Host $Reason -ForegroundColor Yellow
    if (Confirm-YesNo "Перезагрузить компьютер сейчас? / Reboot now? [Y/N]") {
        Write-Log "Reboot scheduled"
        Write-Host "Перезагрузка через 30 секунд. Отмена: shutdown /a" -ForegroundColor Yellow
        & shutdown.exe /r /t 30 /c "VAL43 Fix: reboot to apply changes. Cancel with: shutdown /a"
    } else {
        Write-Warn "Перезагрузите компьютер вручную до запуска игры."
    }
}

function Invoke-Diagnose {
    Write-Step "Диагностика (только чтение)"
    $advice = New-Object System.Collections.Generic.List[string]

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) { Write-Info ("Система: {0} ({1})" -f $os.Caption, $os.Version) }

    $vgc = Get-ScState 'vgc'
    $vgk = Get-ScState 'vgk'
    $vgcStart = Get-ScStart 'vgc'
    switch ($vgc) {
        'running' { Write-Ok "Служба vgc работает, запуск: $vgcStart" }
        'stopped' { Write-Warn "Служба vgc остановлена, запуск: $vgcStart" }
        'missing' { Write-Bad "Служба vgc не установлена" }
        default { Write-Warn "Состояние vgc прочитать не удалось" }
    }
    switch ($vgk) {
        'running' { Write-Ok "Драйвер vgk загружен" }
        'stopped' { Write-Warn "Драйвер vgk не загружен. Он стартует только вместе с Windows." }
        'missing' { Write-Bad "Драйвер vgk не установлен" }
        default { Write-Warn "Состояние vgk прочитать не удалось" }
    }
    if ($vgc -eq 'missing' -or $vgk -eq 'missing') {
        $advice.Add("Переустановите Vanguard пунктом 5, перезагрузите ПК, затем запустите игру пунктом 7 и перезагрузитесь ещё раз.") | Out-Null
    } elseif ($vgk -eq 'stopped' -or $vgcStart -eq 'disabled') {
        $advice.Add("Перезагрузите ПК. Если vgk снова не поднимется, переустановите Vanguard пунктом 5.") | Out-Null
    }

    $bonjour = Get-BonjourState
    if ($bonjour.Present) {
        Write-Bad "Найден Bonjour. Его сетевой фильтр mDNS часто даёт VAL 43."
        if ($bonjour.Dirs.Count -gt 0) { Write-Info ("Папки: " + ($bonjour.Dirs -join ', ')) }
        foreach ($app in $bonjour.Apps) { Write-Info ("Программа: " + $app.DisplayName) }
        $advice.Add("Удалите Bonjour пунктом 4. iTunes для обычной синхронизации после этого работает, локальное обнаружение устройств — нет.") | Out-Null
    } else {
        Write-Ok "Bonjour не найден"
    }

    $patterns = @(
        '*National Instruments*',
        '*Guardian Browser*',
        '*Anti Cheat Expert*',
        '*AntiCheatExpert*'
    )
    $conflicts = @(Get-InstalledApps | Where-Object {
            $name = $_.DisplayName
            foreach ($pattern in $patterns) {
                if ($name -like $pattern) { return $true }
            }
            return $false
        } | Select-Object -ExpandProperty DisplayName -Unique)
    if ($conflicts.Count -gt 0) {
        foreach ($name in $conflicts) { Write-Warn "Возможный конфликт: $name" }
        $advice.Add("Удалите перечисленные программы через Параметры Windows → Приложения. Скрипт их сам не удаляет.") | Out-Null
    } else {
        Write-Ok "Других известных конфликтующих программ не найдено"
    }

    $client = Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\RiotClientServices.exe'
    if (Test-Path -LiteralPath $client) { Write-Ok "Riot Client: $client" }
    else {
        Write-Bad "Riot Client не найден по стандартному пути"
        $advice.Add("Поставьте клиент заново с https://playvalorant.com") | Out-Null
    }

    $valorant = Find-ValorantExe
    if ($valorant) { Write-Ok "Valorant: $valorant" }
    else { Write-Warn "VALORANT.exe не найден. Клиент может докачать игру после входа." }

    $settings = @(
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Data\RiotClientPrivateSettings.yaml'),
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Config\RiotClientSettings.yaml'),
        (Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\Data\RiotGamesPrivateSettings.yaml')
    ) | Where-Object { Test-Path -LiteralPath $_ }
    if ($settings.Count -gt 0) {
        Write-Info "Локальные файлы клиента на месте ($($settings.Count)). Их снимает пункт 2 или 3, после этого нужен повторный вход."
    } else {
        Write-Ok "Файлы локального входа клиента уже отсутствуют"
    }

    $proxy = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
    if ($proxy -and $proxy.ProxyEnable -eq 1) {
        Write-Warn "В Windows включён прокси: $($proxy.ProxyServer)"
        $advice.Add("Выключите прокси и VPN, затем проверьте игру ещё раз.") | Out-Null
    } else {
        Write-Ok "Системный прокси пользователя выключен"
    }

    try {
        $adapters = @(Get-NetAdapter -ErrorAction Stop | Where-Object {
                $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'VPN|TAP-Windows|Wintun|WireGuard|OpenVPN|NordLynx|PANGP|Fortinet|Tailscale|Cisco AnyConnect'
            })
        foreach ($adapter in $adapters) {
            Write-Warn "Похоже на VPN-адаптер: $($adapter.Name) / $($adapter.InterfaceDescription)"
        }
        if ($adapters.Count -gt 0) {
            $advice.Add("Отключите VPN и повторите запуск. VAL 43 часто оказывается таймаутом сессии Vanguard.") | Out-Null
        }
    } catch {
        Write-Info "Список сетевых адаптеров прочитать не удалось"
    }

    $hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
    $hostHits = @(Select-String -Path $hostsPath -Pattern 'riotgames|valorant|riotcdn' -ErrorAction SilentlyContinue |
            Where-Object { $_.Line -notmatch '^\s*#' })
    if ($hostHits.Count -gt 0) {
        Write-Bad "В файле hosts есть строки про Riot ($($hostHits.Count)). Скрипт этот файл не меняет."
        $advice.Add("Сделайте копию $hostsPath и уберите строки про Riot.") | Out-Null
    } else {
        Write-Ok "Файл hosts не блокирует Riot"
    }

    $dnsOk = $false
    try {
        Resolve-DnsName 'playvalorant.com' -ErrorAction Stop | Out-Null
        $dnsOk = $true
        Write-Ok "DNS резолвит playvalorant.com"
    } catch {
        Write-Bad "DNS не резолвит playvalorant.com"
        $advice.Add("Смените DNS на 1.1.1.1 или 8.8.8.8 и выполните пункт 2.") | Out-Null
    }
    $pingOk = $false
    try { $pingOk = [bool](Test-Connection -ComputerName 1.1.1.1 -Count 1 -Quiet -ErrorAction Stop) } catch { }
    if ($pingOk) { Write-Ok "Есть ответ от 1.1.1.1" }
    elseif (-not $dnsOk) { Write-Warn "Нет ответа от 1.1.1.1" }

    Write-Host ""
    Write-Host "Что делать дальше" -ForegroundColor Cyan
    if ($advice.Count -eq 0) {
        Write-Host "  Явной причины не видно. Запустите пункт 2: он удалит файлы Riot в AppData и сбросит сеть."
        Write-Host "  Если ошибка останется — пункт 6, затем два раза перезагрузка, как написано в конце."
    } else {
        $n = 1
        foreach ($item in $advice) {
            Write-Host "  $n. $item"
            $n++
        }
    }
    Write-Info "Статус серверов: https://status.riotgames.com/valorant"
}

function Invoke-CoreFix {
    $ok = Confirm-Action @(
        "Рабочее исправление VAL 43:",
        "- закрыть Riot, Valorant и League of Legends",
        "- удалить в AppData файлы Riot Client: настройки, кэш, логи и RiotClientInstalls.json",
        "- сбросить Winsock, TCP/IP, выданный IP, DNS и прокси",
        "- вернуть брандмауэр к настройкам по умолчанию и снова разрешить Riot",
        "- перезапустить службу Vanguard, если она установлена",
        "",
        "Сама игра, скины и настройки графики остаются. Клиент попросит войти заново.",
        "После этого нужна перезагрузка."
    )
    if (-not $ok) { return }
    Write-Step "Исправление VAL 43"
    Find-ValorantExe | Out-Null
    Stop-RiotProcesses
    Clear-RiotClientState -IncludeCache
    Restart-VanguardService
    Reset-NetworkStack
    Add-RiotFirewallRules
    Request-Reboot "Сброс сети применится после перезагрузки. Затем запустите пункт 7."
}

function Invoke-QuickFix { Invoke-CoreFix }
function Invoke-StandardFix { Invoke-CoreFix }

function Invoke-BonjourRemoval {
    $state = Get-BonjourState
    if (-not $state.Present) {
        Write-Info "Bonjour не найден. Удалять нечего."
        return
    }
    $ok = Confirm-Action @(
        "Будет удалён Apple Bonjour (служба mDNS).",
        "Это частая причина VAL 43, когда Bonjour ставится вместе с iTunes.",
        "Локальное обнаружение устройств Apple перестанет работать.",
        "Обычная библиотека iTunes останется на месте.",
        "Затем сеть сбросится целиком: Winsock, IP, DNS, прокси и брандмауэр. Нужна перезагрузка."
    )
    if (-not $ok) { return }
    Write-Step "Удаление Bonjour"
    Remove-Bonjour | Out-Null
    Reset-NetworkStack
    Request-Reboot "Bonjour и Winsock применятся после перезагрузки."
}

function Invoke-VanguardReinstall {
    $ok = Confirm-Action @(
        "Будет запущен официальный деинсталлятор Riot Vanguard.",
        "Драйвер вручную не удаляется и античит не отключается.",
        "Игра VALORANT, скины и настройки графики остаются.",
        "",
        "Дальше вручную:",
        "1. Перезагрузить ПК",
        "2. Запустить Riot Client от администратора (пункт 7)",
        "3. Дождаться, пока клиент сам поставит Vanguard",
        "4. Перезагрузить ПК ещё раз и только потом заходить в матч"
    )
    if (-not $ok) { return }
    Write-Step "Переустановка Vanguard"
    Uninstall-VanguardOfficial
    Request-Reboot "Перезагрузка нужна, чтобы драйвер Vanguard снялся. Потом запустите пункт 7."
}

function Invoke-FullFix {
    $ok = Confirm-Action @(
        "Полное исправление, по порядку:",
        "- закрыть Riot и League of Legends",
        "- удалить Bonjour, если он есть",
        "- удалить Vanguard его штатным деинсталлятором",
        "- очистить локальные настройки и кэш клиента, не трогая игру",
        "- сбросить Winsock, TCP/IP, выданный IP, DNS, прокси и брандмауэр",
        "- снова разрешить найденные файлы Riot в брандмауэре",
        "",
        "Игра не удаляется. Пароль не запрашивается. Ничего не скачивается.",
        "",
        "После перезагрузки запустите пункт 7, дождитесь установки Vanguard",
        "и перезагрузите компьютер ещё раз."
    )
    if (-not $ok) { return }

    Write-Step "Полное исправление"
    Find-ValorantExe | Out-Null
    Stop-RiotProcesses
    if ((Get-BonjourState).Present) {
        Remove-Bonjour | Out-Null
    } else {
        Write-Info "Bonjour нет, шаг пропущен"
    }
    Uninstall-VanguardOfficial
    Clear-RiotClientState -IncludeCache
    Reset-NetworkStack
    Add-RiotFirewallRules
    Write-Host ""
    Write-Host "После двух перезагрузок (до установки Vanguard и после неё) запустите пункт 7." -ForegroundColor White
    Request-Reboot "Сначала эта перезагрузка. Клиент до неё не запускайте."
}

function Start-ValorantClient {
    $client = Join-Path $env:LOCALAPPDATA 'Riot Games\Riot Client\RiotClientServices.exe'
    if (-not (Test-Path -LiteralPath $client)) {
        Write-Bad "Riot Client не найден: $client"
        Write-Info "Скачайте игру с https://playvalorant.com и установите её обычным способом."
        return
    }
    if ((Get-ScState 'vgk') -eq 'stopped') {
        Write-Warn "Драйвер vgk не загружен. Перезагрузите ПК: этот драйвер не стартует без перезагрузки."
    }
    if ((Get-ScState 'vgc') -ne 'missing') {
        Restart-VanguardService
    }
    Start-Process -FilePath $client -ArgumentList @(
        '--launch-product=valorant',
        '--launch-patchline=live'
    )
    Write-Ok "Riot Client запущен. Если попросит — войдите в аккаунт."
    Write-Info "Клиент уже запущен от администратора, отдельно повышать его не нужно."
}

function Show-Menu {
    Clear-Host
    Write-Host "VAL43 Fix  $Script:Version" -ForegroundColor Cyan
    Write-Host "Локальная помощь с ошибкой Valorant VAL 43. Это не продукт Riot Games." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  1   Диагностика                 ничего не меняет"
    Write-Host "  2   Исправление VAL 43          AppData и полный сброс сети"
    Write-Host "  3   Повторить исправление       те же шаги ещё раз"
    Write-Host "  4   Удалить Bonjour             частая причина VAL 43"
    Write-Host "  5   Переустановить Vanguard     только штатный деинсталлятор"
    Write-Host "  6   Полное исправление          пункты 4 + 5 + сеть"
    Write-Host "  7   Запустить Valorant          клиент уже от администратора"
    Write-Host "  0   Выход"
    Write-Host ""
}

function Invoke-Choice {
    param([string]$Choice)
    switch ($Choice) {
        '1' { Invoke-Diagnose }
        '2' { Invoke-QuickFix }
        '3' { Invoke-StandardFix }
        '4' { Invoke-BonjourRemoval }
        '5' { Invoke-VanguardReinstall }
        '6' { Invoke-FullFix }
        '7' { Start-ValorantClient }
        default { Write-Warn "Нет такого пункта: $Choice" }
    }
}

if (-not (Test-IsAdmin)) {
    Write-Host "Запустите Fix-VAL43.bat и подтвердите запрос администратора." -ForegroundColor Red
    Read-Host "Enter"
    exit 1
}

Write-Log "===== VAL43 Fix $Script:Version ====="

if ($Action) {
    switch ($Action) {
        'Diagnose' { Invoke-Diagnose }
        'Quick' { Invoke-QuickFix }
        'Standard' { Invoke-StandardFix }
        'Bonjour' { Invoke-BonjourRemoval }
        'Vanguard' { Invoke-VanguardReinstall }
        'Full' { Invoke-FullFix }
        'Launch' { Start-ValorantClient }
    }
    Write-Host ""
    Write-Host "Лог: $Script:LogFile" -ForegroundColor DarkGray
    exit 0
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Пункт"
    if ($choice -eq '0' -or $choice -eq 'q' -or $choice -eq 'Q') {
        exit 0
    }
    try {
        Invoke-Choice $choice.Trim()
    } catch {
        Write-Bad $_.Exception.Message
        Write-Log ("EXCEPTION " + $_.ScriptStackTrace)
    }
    Write-Host ""
    Write-Host "Лог: $Script:LogFile" -ForegroundColor DarkGray
    Read-Host "Enter — вернуться в меню"
}
