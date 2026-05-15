---
title: Wine и RLIMIT_NICE
author: Антон Муравьев
date: 2024-04-17T19:48:33+03:00
description: Даём права на управление приоритетом
guid: 6f8a1390-596f-4a60-8ea8-f4efc91d6d51
---

При запуске игр в Lutris я неоднократно замечал следующую строчку в логах:

```
wine: RLIMIT_NICE is <= 20, unable to use setpriority safely
```

Эта строка говорит о том, что `wine` не может устанавливать параметры приоритета
для себя и своих же процессов. Это может сказываться, к примеру, на стабильности
времени ожидания кадра или приводить к проблемам с проигрыванием аудио.

Вот показательное обсуждение на GitHub того, [как дать Wine нужные права]. Там
есть пример, как дать `CAP_SYS_NICE` для `gamescope`. И, действительно, выдача
`CAP_SYS_NICE` для `gamescope` помогает. Но что делать, если `gamescope` мне не
нужен?

Кажется, выдача `CAP_SYS_NICE` для `wine` должна помочь. Но не тут то было. Всё
то же предупреждение про `RLIMIT_NICE` намекнёт, что так не получится.

Одна из альтернатив -- дать возможность самостоятельного управления приоритетом
для **всех** процессов пользователя. Для этого нужно изменить конфигурацию
`limits.conf`. Мне такой вариант не нравится, т.к. это глобальное изменение для
решения локальной проблемы только с `wine`.

На помощь приходит Wine HQ и [страница о переменных окружения для Wine-Staging].
Главное там: `CAP_SYS_NICE` нужен не самому `wine`, а `wineserver`! Применим
команду `setcap` для `wineserver` после перехода в директорию с wine runner'ами:

```shell-session
$ cd ~/.local/share/lutris/runners/wine
$ ls -1

wine-ge-8-22-x86_64
wine-ge-8-26-x86_64

$ sudo find . -type f -name 'wineserver' -exec \
    setcap 'cap_sys_nice=eip' {} \;
```

Комбинация с `find` сразу применит `CAP_SYS_NICE` для всех runner'ов. Для
проверки, есть ли `CAP_SYS_NICE` у нужного `wineserver`, используем `getcap`:

```shell-session
$ sudo find . -type f -name 'wineserver' -exec \
    getcap {} \;

./wine-ge-8-22-x86_64/bin/wineserver cap_sys_nice=eip
./wine-ge-8-26-x86_64/bin/wineserver cap_sys_nice=eip
```

Значит, изменения успешны. Теперь после запуска игр `wine` рапортует о том, что
он может (и будет) самостоятельно менять приоритета процесса:

```
wine: Using setpriority to control niceness in the [-19,19] range
```

Стоит помнить, что при установке новых runner'ов процедуру нужно повторить.

[как дать Wine нужные права]: https://github.com/ValveSoftware/Proton/issues/6141
[страница о переменных окружения для Wine-Staging]: https://wiki.winehq.org/Wine-Staging_Environment_Variables
