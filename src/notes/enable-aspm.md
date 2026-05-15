---
title: Включаем ASPM
author: Антон Муравьев
date: 2024-08-20T19:37:21+03:00
description: Снижаем энергопотребление PCIe
guid: 432e592e-251d-4bce-a410-0a46235f3484
---

Повышенный нагрев PCIe устройств в ПК -- не самая приятная вещь. Особенно в тех
случаях, когда нагрев приводит к троттлингу. Недавно я заметил, что некоторые
устройства у меня нагреваются даже в состоянии "покоя", что навело на мысли о
проблемах с настройками энергосбережения.

В этой заметке -- мои шаги для включения [Active-state power management (ASPM)].
Этот механизм позволяет PCIe устройствам снижать потребление энергии по указанию
от ОС.

Отдельно отмечу, что некоторые производители материнских плат отключают
управление ASPM для ОС. В моём случае (с MSI) потребовалось принудительно
установить параметр BIOS под названием `ASPM Control for CPU PCIe` в состояние
`L0s And L1 Entry`.

В ОС воспользуемся командой `lspci`, чтобы проверить поддержку ASPM у устройств

```shell-session
$ sudo lspci -vv | grep 'LnkCtl:'

LnkCtl: ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
LnkCtl: ASPM Disabled; Disabled- CommClk+
LnkCtl: ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
```

Если большинство строк в выводе имеют `Disabled`, а не `Enabled`, то стоит дать
ядру Linux явное указание к сохранению энергии путём установки флагов CMDLINE.

Но сначала проверим поддержку ASPM у ядра.

```shell-session
$ sudo journalctl -b | grep 'ASPM'

kernel: acpi PNP0A08:00: _OSC: OS supports [ExtendedConfig ASPM ClockPM Segments MSI HPX-Type3]
```

Хорошо, тут видно, что OS поддерживает ASPM. Проверим, какая политика ASPM
установлена сейчас.

```shell-session
$ cat /sys/module/pcie_aspm/parameters/policy

[default] performance powersave powersupersave
```

`default` -- по умолчанию, стоит внести ясность и явно включить режим
`powersave`.

Отредактируем конфигурацию GRUB и внесём релевантную опцию загрузки в CMDLINE.

```shell-session
$ sudoedit /etc/default/grub
```

Нужно только добавить `pcie_aspm.policy=powersave` в конец строки с CMDLINE.

<pre>GRUB_CMDLINE_LINUX_DEFAULT="quiet splash noresume <b>pcie_aspm.policy=powersave</b>"</pre>

Теперь запустим обновление конфигурации GRUB, чтобы он "увидел" изменение
CMDLINE.

```shell-session
$ sudo update-grub
```

Перезагружаемся. После перезагрузки проверяем CMDLINE.

```shell-session
$ sudo journalctl -b | grep 'Kernel command line'

kernel: Kernel command line: [...] pcie_aspm.policy=powersave
```

Здесь видим, что новая опция передана ядру, отлично! Проверим политику ASPM.

```shell-session
$ cat /sys/module/pcie_aspm/parameters/policy

default performance [powersave] powersupersave
```

И новая политика тоже заработала. Финальный аккорд -- проверяем состояние PCIe.

```shell-session
$ sudo lspci -vv | grep 'LnkCtl:'

LnkCtl: ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
LnkCtl: ASPM L0s L1 Enabled; Disabled- CommClk+
LnkCtl: ASPM L1 Enabled; RCB 64 bytes, Disabled- CommClk+
```

Как видно, часть устройств теперь имеют включенный ASPM, но не все, что
нормально. Для корректной работы ASPM нужна поддержка не только от ОС, но и от
железа.

В моём случае, я увидел явное снижение температур в простое для самых
энергоёмких устройств, чего и хотел добиться.

[Active-state power management (ASPM)]: https://en.wikipedia.org/wiki/Active_State_Power_Management
