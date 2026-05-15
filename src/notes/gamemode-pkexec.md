---
title: Gamemode не переключает governor
author: Антон Муравьев
date: 2024-11-25T17:34:59+03:00
description: Исправляем отсутствие `pkexec`
guid: 97093765-f97b-42ba-988d-ccf3bec5583b
---

Обкатывая на Debian 12 свежий backport пакета Linux версии 6.11.5, я решил
наконец-то заняться сбором статистики с помощью MangoHud. После настройки
`output_folder` для MangoHud, можно запустить сбор метрик в файлы CSV
комбинацией клавиш <kbd>SHIFT + F2</kbd>.

Собирая метрики, я увидел, что CPU governor указан как powersave. Это странно.
Ведь я использую Gamemode, а он должен переключать CPU governor из powersave в
performance при запуске игр.

При запущенной игре проверяю что CPU governor это действительно powersave.

```shell-session
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

powersave
```

Как видим, действительно `powersave`. Теперь проверим, что `gamemoded` работает.

```shell-session
$ systemctl --user status gamemoded.service

● gamemoded.service - gamemoded
     Loaded: loaded (/usr/lib/systemd/user/gamemoded.service; disabled; preset: enabled)
     Active: active (running) since Sat 2024-11-09 18:27:46 MSK; 4h 33min ago
   Main PID: 2649 (gamemoded)
     Status: "GameMode is now active."
      Tasks: 2 (limit: 154386)
     Memory: 1.7M
        CPU: 164ms
     CGroup: /user.slice/user-1000.slice/user@1000.service/app.slice/gamemoded.service
             └─2649 /usr/bin/gamemoded
```

Всё действительно так, `active`. Поиск в интернете не дал значительных ответов,
самым полезным мне показалась [переписка на GitHub], в которой рекомендовали
добавлять пользователя в группу `gamemode`. Окей, на всякий случай добавляю.

```shell-session
$ getent group | grep gamemode

gamemode:x:993:

$ sudo usermod -a -G gamemode $USER
$ getent group | grep gamemode

gamemode:x:993:tsb99x
```

Теперь перезапускаю игру... И... Ничего, CPU governor не поменялся. В той же
переписке на GitHub упомянут механизм тестирования для Gamemode, флаг `-t`.

Выхожу из игры и пробую запустить тест работоспособности.

```shell-session
$ gamemoded -t

: Loading config
Loading config file [/usr/share/gamemode/gamemode.ini]
: Running tests

:: Basic client tests
:: Passed

:: Dual client tests
gamemode request succeeded and is active
Quitting by request...
:: Passed

:: Gamemoderun and reaper thread tests
...Waiting for child to quit...
...Waiting for reaper thread (reaper_frequency set to 5 seconds)...
:: Passed

:: Supervisor tests
:: Passed

:: Feature tests
::: Verifying CPU governor setting
ERROR: Governor was not set to performance (was actually powersave)!
::: Failed!
::: Verifying Scripts
::: Passed (no scripts configured to run)
::: Verifying GPU Optimisations
::: Passed (gpu optimisations not configured to run)
::: Verifying renice
::: Passed (no renice configured)
::: Verifying ioprio
::: Passed
ERROR: :: Failed!
: Tests Failed!
```

Ага! Тест действительно не проходит, осталось узнать почему. Почитаем логи.

```shell-session
$ sudo journalctl -b | grep gamemode

[...]

gamemoded[2543]: ERROR: Failed to update cpu governor policy
gamemoded[6839]: ERROR: Failed to execute external process: pkexec No such file or directory
gamemoded[2543]: ERROR: External process failed with exit code 1
gamemoded[2543]: ERROR: Output was:  was initially set to [powersave]

[...]
```

Ругается на отсутствие `pkexec`, неужели у меня нет компонента PolicyKit?

```shell-session
$ pkexec date

bash: pkexec: command not found
```

А есть он в зависимостях у пакетов `gamemode`?

```shell-session
$ apt-cache show gamemode-daemon | grep -E 'Depends|Recommends|Suggests'

Depends: init-system-helpers (>= 1.52), libc6 (>= 2.34), libinih1 (>= 40), libsystemd0 (>= 243)

$ apt-cache show gamemode | grep -E 'Depends|Recommends|Suggests'

Depends: libc6 (>= 2.34), gamemode-daemon, libgamemode0, libgamemodeauto0
Recommends: libgamemode0:i386, libgamemodeauto0:i386
Suggests: gnome-shell-extension-gamemode
```

Интересно, `pkexec` нет... Ну что же, устанавливаем сами.

```shell-session
$ sudo apt install pkexec

[...]

The following NEW packages will be installed:
  pkexec
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.

[...]
```

И сразу попробуем протестировать Gamemode.

```shell-session
$ gamemoded -t

: Loading config
Loading config file [/usr/share/gamemode/gamemode.ini]
: Running tests

:: Basic client tests
:: Passed

:: Dual client tests
gamemode request succeeded and is active
Quitting by request...
...Waiting for child to quit...
:: Passed

:: Gamemoderun and reaper thread tests
...Waiting for child to quit...
...Waiting for reaper thread (reaper_frequency set to 5 seconds)...
:: Passed

:: Supervisor tests
:: Passed

:: Feature tests
::: Verifying CPU governor setting
::: Passed
::: Verifying Scripts
::: Passed (no scripts configured to run)
::: Verifying GPU Optimisations
::: Passed (gpu optimisations not configured to run)
::: Verifying renice
::: Passed (no renice configured)
::: Verifying ioprio
::: Passed
:: Passed

: All Tests Passed!
```

Отлично, при запуске игры CPU governor также установился как performance.

[переписка на GitHub]: https://github.com/FeralInteractive/gamemode/issues/452
