# VAL43 Fix

Неофициальная утилита для ошибки **VAL 43** в Valorant. Ошибка означает, что сессия Vanguard не поднялась вовремя: служба античита, её драйвер или сеть до серверов Riot.

Это не обход античита. Скрипт приводит Vanguard в рабочее состояние и не выключает его. Проект не связан с Riot Games.

[English](#english) ниже.

## Быстрый старт

1. Скачайте репозиторий или ZIP и распакуйте его.
2. Запустите **`Fix-VAL43.bat`**.
3. Подтвердите запрос Windows на права администратора.
4. Выберите пункт **2**. Это рабочее исправление: удаление файлов Riot в AppData и полный сброс сетевых настроек. Потом перезагрузка и пункт **7**.

Политика выполнения PowerShell для всей системы не меняется. `Fix-VAL43.bat` включает обход политики только для этого окна.

Windows может написать, что издатель неизвестен: проект не подписан сертификатом. Имеет смысл открыть `Fix-VAL43.ps1` и прочитать его до запуска. Скрипт ничего не скачивает и не спрашивает пароль Riot.

## Меню

| Пункт | Когда | Что меняет |
| --- | --- | --- |
| 1. Диагностика | Всегда сначала | Ничего. Пишет, что проверить |
| 2. Исправление VAL 43 | С этого и начинать | Удаляет файлы Riot в AppData и сбрасывает сеть: Winsock, TCP/IP, IP, DNS, прокси, брандмауэр |
| 3. Повторить исправление | Ошибка осталась после пункта 2 | Те же шаги ещё раз |
| 4. Удалить Bonjour | Диагностика нашла Bonjour | Снимает Apple Bonjour и его фильтр mDNS. Нужна перезагрузка |
| 5. Переустановить Vanguard | Служба или драйвер не на месте | Штатный деинсталлятор Riot Vanguard. Игру не удаляет |
| 6. Полное исправление | Остальное не помогло | Пункты 4, 5 и сброс сети одной последовательностью |
| 7. Запустить Valorant | После исправления | Открывает Riot Client уже от администратора |

Разрушительные пункты не стартуют, пока не ввести `ДА` или `YES`. Перезагрузка тоже только после отдельного подтверждения. Отмена запланированной перезагрузки: `shutdown /a`.

Лог пишется в `logs/val43-fix.log` рядом со скриптом. Эту папку можно приложить к issue, если ошибка осталась. В логе нет паролей.

## Обычный порядок

1. Пункт **2**: чистка AppData и сброс сети. Перезагрузка. Пункт **7**.
2. Если диагностика нашла Bonjour — пункт 4, снова перезагрузка, затем пункт 7.
3. Если служба `vgc` или драйвер `vgk` отсутствуют — пункт 5, перезагрузка, пункт 7, дождаться установки Vanguard, перезагрузка ещё раз.
4. Если ошибка всё ещё на месте — пункт 6.

Драйвер `vgk` загружается только при старте Windows. Запуск игры без перезагрузки после переустановки Vanguard снова даёт ту же ошибку.

## Что скрипт не делает

- не удаляет Valorant, League of Legends и папку с игрой;
- не стирает скины, ранг и настройки графики — прогресс лежит на серверах Riot;
- не удаляет файл драйвера `vgk.sys` и не выключает античит;
- не вытирает `%TEMP%`;
- не правит файл `hosts` и не отключает Защитник Windows;
- не запрашивает логин, пароль или код 2FA.

Пункт 2 удаляет в AppData локальные файлы клиента: `RiotClientPrivateSettings.yaml`, `RiotClientSettings.yaml`, `RiotGamesPrivateSettings.yaml`, `RiotClientInstalls.json`, кэш и логи. Папка с игрой остаётся. После этого Riot Client просит войти снова и заново находит установку.

Сброс сети включает Winsock, TCP/IP, `ipconfig /release` и `/renew`, DNS, прокси WinHTTP и возврат брандмауэра к правилам по умолчанию. Сразу после этого для найденных файлов Riot снова ставятся разрешающие правила. VPN и некоторые антивирусы после пункта 2, 4 или 6 могут попросить починку своего сетевого компонента.

## Если игра всё ещё не пускает

- Проверьте [статус серверов Valorant](https://status.riotgames.com/valorant).
- Отключите VPN и системный прокси.
- По возможности используйте кабель, не Wi-Fi.
- В клиенте: настройки Valorant → восстановление установки.
- Поставьте клиент заново только с [playvalorant.com](https://playvalorant.com).
- Напишите в [поддержку Riot](https://support-valorant.riotgames.com/) и приложите `logs/val43-fix.log`.

## Ручные шаги

Тот же результат без скрипта, если хочется сделать всё самому:

1. Параметры Windows → Приложения. Удалите **Bonjour**, если он есть, и **Riot Vanguard**. Саму игру не удаляйте.
2. Перезагрузите компьютер.
3. Удалите файлы клиента в AppData, если они есть:
   - `%LOCALAPPDATA%\Riot Games\Riot Client\Data\RiotClientPrivateSettings.yaml`
   - `%LOCALAPPDATA%\Riot Games\Riot Client\Config\RiotClientSettings.yaml`
   - `%LOCALAPPDATA%\Riot Games\Riot Client\Data\RiotGamesPrivateSettings.yaml`
   - `%LOCALAPPDATA%\Riot Games\Riot Client\Data\RiotClientInstalls.json`
   - папки `Cache`, `Logs` и `Crashpad` внутри `%LOCALAPPDATA%\Riot Games\Riot Client\`
4. В командной строке от администратора:

```bat
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
netsh winhttp reset proxy
netsh advfirewall reset
```

5. Перезагрузите компьютер.
6. Запустите Riot Client от имени администратора, войдите в аккаунт и дождитесь установки Vanguard.
7. Перезагрузите компьютер ещё раз и запустите Valorant.

## Частые вопросы

**Это безопасно?** Скрипт использует команды Windows и штатное удаление программ. Перед пунктами 2–6 он показывает список действий. Гарантии, что ошибка уйдёт в каждом случае, нет: VAL 43 бывает и из-за самой сети Riot.

**Потеряются скины?** Нет. На этом компьютере сбросится только локальный вход в клиент.

**Почему нужен администратор?** Остановка службы Vanguard, удаление Bonjour и сброс Winsock без прав администратора недоступны.

**Можно ли запускать повторно?** Да. Диагностику — сколько угодно. Полное исправление — если более короткие пункты не помогли.

---

## English

Unofficial helper for Valorant's **VAL 43** error (Vanguard session timed out). It is not an anti-cheat bypass and it is not a Riot Games product.

### Start

1. Download the repo and unzip it.
2. Run **`Fix-VAL43.bat`** and accept the administrator prompt.
3. Choose menu item **2**. That is the fix: delete Riot files in AppData and reset the network, then reboot and use item **7**.

The console is in Russian. The menu numbers match the table above:

| Item | Effect |
| --- | --- |
| 1 | Read-only diagnosis |
| 2 | Delete Riot AppData files and reset Winsock, TCP/IP, IP, DNS, proxy, and the firewall |
| 3 | Run that same fix again |
| 4 | Remove Apple Bonjour, then reset Winsock. Reboot |
| 5 | Official Riot Vanguard uninstall. Does not delete the game |
| 6 | Items 4, 5, and the network reset |
| 7 | Launch Riot Client, already elevated |

Type `ДА` or `YES` to confirm a destructive step. Reboot is a separate yes/no. Cancel a scheduled reboot with `shutdown /a`.

A log is written to `logs/val43-fix.log`.

You can also run one action directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Fix-VAL43.ps1 -Action Diagnose
```

`Quick`, `Standard`, `Bonjour`, `Vanguard`, `Full`, and `Launch` are the other actions. Destructive actions still ask for confirmation.

### What it will not do

It does not delete the game, your account progress, or graphics settings. It does not delete `vgk.sys` by hand, edit the hosts file, disable Defender, download anything, or ask for your Riot password. Item 2 does delete the local Riot Client session files in AppData and resets the network, including the firewall back to defaults. Vanguard is removed only through its own uninstaller, then the client installs it again after a reboot.

See [Manual steps](#ручные-шаги) for the same procedure without the script. Command lines there are identical on an English Windows.

## License

[MIT](LICENSE). Use it on your own PC, at your own risk.
