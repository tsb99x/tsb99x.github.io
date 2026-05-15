---
title: Вытаскиваем данные из VDI
author: Антон Муравьев
date: 2024-10-04T17:34:40+03:00
description: Монтирование образов с `offset`
guid: 4a652ca4-919c-45dd-b634-82a1d64c4f45
---

Подчищая старые виртуалки, споткнулся о проблему запуска виртуальной машины с
Windows XP на Virt-Manager. Создавалась эта виртуалка с помощью VirtualBox. В
прошлом я делал [конвертацию VDI в QCOW2]. Но на этот раз ВМ не загружалась.

Основной целью запустить виртуалку было простое желание вытащить из неё полезные
данные и удалить, чтобы она не занимала лишнего места. Диск у ВМ не шифровался.
Логичная мысль -- нужно просто вытащить данные с образа диска без запуска ВМ.

Первым шагом конвертирую VDI в RAW, т.к. `.img` можно будет смонтировать.

```shell-session
$ qemu-img convert XP.vdi -O raw XP.img
$ qemu-img info XP.img

image: XP.img
file format: raw
virtual size: 32 GiB (34359738368 bytes)
disk size: 22.3 GiB
```

Конвертация успешна, можно даже посмотреть таблицу разделов.

```shell-session
$ sudo fdisk -l XP.img

Disk XP.img: 32 GiB, 34359738368 bytes, 67108864 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xa941a941

Device     Boot Start      End  Sectors Size Id Type
XP.img1    *       63 67087439 67087377  32G  7 HPFS/NTFS/exFAT
```

Но если попробовать смонтировать образ "в лоб", то получаю ошибку.

```shell-session
$ mkdir /tmp/XP-mount
$ sudo mount XP.img /tmp/XP-mount/

mount: /tmp/XP-mount: wrong fs type, bad option, bad superblock on /dev/loop0, missing codepage or helper program, or other error.
       dmesg(1) may have more information after failed mount system call.
```

[Подсказка на AskUbuntu] поможет собрать головоломку с помощью `offset`. Идея в
том, чтобы смонтировать не весь `.img`, а только часть, пропустив секторы.

Чтобы посчитать, какой нужен `offset`, смотрим на вывод `fdisk -l`. Размер
сектора установлен как 512 байт. Первый раздел стартует с 63 сектора. Путём
перемножения получаем 63 * 512 = 32256 байт. Такое значение и устанавливаю.

```shell-session
$ sudo mount -o offset=32256 XP.img /tmp/XP-mount/
```

У такого подхода есть плюс в виде универсальности, но считать `offset` вручную
неудобно. Кроме того, в образе может быть множество разделов.

В прошлом я искал способы монтирования `.iso` образов без root-прав. Основная
альтернатива для `mount` там `udisksctl`. Тут он тоже применим, попробуем.

```shell-session
$ udisksctl loop-setup -f XP.img

Mapped file XP.img as /dev/loop0.

$ udisksctl mount -b /dev/loop0p1

Mounted /dev/loop0p1 at /media/user/96380D99380D798F
```

Отмечу отдельно: никакой необходимости пользоваться `sudo` нет. При монтировании
достаточно указать нужный раздел с помощью суффикса `p1` для устройства `loop0`.
А ещё не требуется создавать папку для точки монтирования. Чтобы размонтировать:

```shell-session
$ udisksctl unmount -b /dev/loop0p1

Unmounted /dev/loop0p1.

$ udisksctl loop-delete -b /dev/loop0
```

Во всех вариантах монтирования я увидел ФС бывшей XP. Запаковал нужные данные, а
после размонтировал `.img` и удалил вместе с исходным VDI. В будущем буду знать
и пользоваться `udisksctl`, если придётся монтировать RAW образы виртуалок.

[конвертацию VDI в QCOW2]: /notes/vdi-to-qcow2.html
[Подсказка на AskUbuntu]: https://askubuntu.com/questions/483009/mounting-disk-image-in-raw-format
