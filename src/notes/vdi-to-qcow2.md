---
title: Превращаем VDI в QCOW2
author: Антон Муравьев
date: 2024-01-27T21:40:21+03:00
description: Используем образы из VBox в QEMU
guid: 391a26fe-7628-4e86-baea-eb6d8a26ed13
---

Как бывший пользователь VirtualBox, я храню несколько VDI, которые мне дороги.
На Linux я сейчас пользуюсь Virt-Manager, QEMU и KVM как основными инструментами
для виртуализации. И, поскольку VirtualBox мне больше не нужен, я всё-же решил
конвертировать VDI образы в QCOW2.

В сети можно найти много советов по такой конвертации. Но почти каждый совет
почему-то использует `VBoxManage` для конвертации из VDI в RAW. Потом нужно
использовать `qemu-img` для конвертации из RAW в QCOW2.

Есть нюанс. RAW не поддерживает динамическое выделение пространства. Если диск в
VM мог хранить 128G, а использовано только 32G, то VDI и QCOW2 (в идеале) будут
использовать всего 32G. RAW во всех случаях будет занимать 128G, а сколько было
реально использовано не имеет никакого значения. В результате, для конвертации
нужно больше свободного места на диске. Вот объёмы одного и того же образа в
разных форматах (расширение `.img` отвечает за RAW формат):

```shell-session
$ du -h lubuntu.*

129G    lubuntu.img
40G     lubuntu.qcow2
42G     lubuntu.vdi
```

Подобные советы по конвертации совсем игнорирует поддержку VDI со стороны QEMU.
Хотя для QEMU есть [документированная поддержка VDI]. А ведь QEMU -- не только
интерфейс для эмуляции и запуска VM через CLI, но и другой инструментарий,
включая упомянутый `qemu-img` для работы с образами дисков. Будь это создание,
изменение или конвертация, `qemu-img` поддерживает VDI.

Расставим последние точки над И. Вам не нужно конвертировать VDI образ диска для
перехода с VirtualBox на QEMU. Virt-Manager и CLI QEMU **позволяют** запускать
системы с VDI образов. Никаких проблем при этом я не замечал. Вот пример простой
команды для запуска моего VDI образа с Lubuntu:

```shell-session
$ qemu-system-x86_64 -enable-kvm -m 1G lubuntu.vdi
```

А для конвертации не требуется `VBoxManage`, нужен только `qemu-img`. К примеру,
конвертирую старый образ Lubuntu в QCOW2:

```shell-session
$ qemu-img convert lubuntu.vdi -O qcow2 lubuntu.qcow2
```

Это всё, что требуется. Можно дополнительно проверить, что это действительно
QCOW2, а не RAW:

```shell-session
$ qemu-img info lubuntu.qcow2

image: lubuntu.qcow2
file format: qcow2
virtual size: 128 GiB (137438953472 bytes)
disk size: 40 GiB
cluster_size: 65536
Format specific information:
    compat: 1.1
    compression type: zlib
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
    extended l2: false
```

И, поскольку это действительно QCOW, можно сделать проверку образа на ошибки:

```shell-session
$ qemu-img check lubuntu.qcow2

No errors were found on the image.
654308/2097152 = 31.20% allocated, 0.00% fragmented, 0.00% compressed clusters
Image end offset: 42895933440
```

Никаких дополнительных пакетов или программ, как видите, не требуется. Ну вот,
теперь образы VM полноценно соответствуют линуксоидному "фэншую".

[документированная поддержка VDI]: https://www.qemu.org/docs/master/system/images.html#cmdoption-image-formats-arg-vdi
