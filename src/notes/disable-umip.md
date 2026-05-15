---
title: Отключаем функции UMIP
author: Антон Муравьев
date: 2024-08-21T18:55:24+03:00
description: Применяем опцию `clearcpuid`
guid: c0508cbe-c8e3-45e3-90c8-727e80a9e9f0
---

Начиная с ядра Linux версии 5.4 и выше [появилась поддержка User-Mode
Instruction Prevention (UMIP)]. Существует определенный набор операций, который не
должен исполнятся как есть, а должен поддерживаться через механизмы эмуляции,
спуфинга и/или виртуализации.

Несмотря на решение части проблем, UMIP и сегодня бьёт по старым играм и [мешает
Wine их исполнять]. Выглядит это как экстренное завершение процесса игры и Wine.
Пока разработчики Wine и ядра Linux ищут эффективное решение, UMIP можно просто
отключить.

Чтобы понять, является ли комбинация Вашего железа/системы/игры подверженной
проблеме с UMIP, достаточно поискать релевантные строчки в логах. В моём случае
той самой проблемной игрой являлся [Split/Second]:

```shell-session
$ sudo journalctl | grep -i umip

kernel: x86/cpu: User Mode Instruction Prevention (UMIP) activated
kernel: umip: SplitSecond.exe[19872] ip:12d14f7 sp:235c4a4: SIDT instruction cannot be used by applications.
kernel: umip: SplitSecond.exe[19872] ip:12d14f7 sp:235c4a4: For now, expensive software emulation returns the result.
kernel: umip: SplitSecond.exe[19872] ip:12d14fd sp:235c4a4: SLDT instruction cannot be used by applications.
kernel: umip: SplitSecond.exe[19872] ip:12d14fd sp:235c4a4: For now, expensive software emulation returns the result.
kernel: umip: SplitSecond.exe[19872] ip:12d1503 sp:235c4a4: SGDT instruction cannot be used by applications.
```

Достаточно указать ядру новый параметр для отключения UMIP. Откроем конфигурацию
`grub`:

```shell-session
$ sudoedit /etc/default/grub
```

Добавим параметр `clearcpuid=514` в строку `GRUB_CMDLINE_LINUX_DEFAULT`. К
примеру:

<pre>GRUB_CMDLINE_LINUX_DEFAULT="quiet splash noresume <b>clearcpuid=514</b>"</pre>

Обновляем конфигурацию `grub` и перезагружаемся:

```shell-session
$ sudo update-grub
$ sudo reboot
```

Посмотрим на свежие логи этой загрузки и увидим, что UMIP был отключен:

```shell-session
$ sudo journalctl -b | grep -i umip

kernel: Clearing CPUID bits: umip
```

Проблема с UMIP всё ещё охватывает много старых игр и даже "цепляет" новые.
Поговаривают, что одной из новых игр, которая просто не запускается без
отключения UMIP, стала Hogwarts Legacy 2023 года выпуска. Выходит, проблема
актуальна как никогда и не только для старых игр...

[появилась поддержка User-Mode Instruction Prevention (UMIP)]: https://www.phoronix.com/news/Linux-5.4-UMIP-Spoofing
[мешает Wine их исполнять]: https://www.phoronix.com/news/Nuclear-Strike-SGDT-Wine
[Split/Second]: https://ru.wikipedia.org/wiki/Split/Second
