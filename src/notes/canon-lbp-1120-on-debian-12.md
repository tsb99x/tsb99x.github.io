---
title: Canon LBP-1120 на Debian Bookworm
author: Антон Муравьев
date: 2024-06-08T14:49:25+03:00
description: Устанавливаем и настраиваем CAPT
guid: 78614fc2-bc9e-43b2-afbb-26d12b186389
changelog:
- date: 2024-08-22T18:51:57+03:00
  change: добавил включение архитектуры `i386` для `dpkg`.
---

У меня есть принтер Canon LBP-1120. Это старый добрый ч/б лазерник. Своё дело
знает и делает хорошо. Если не ошибаюсь, принтер выпускался в начале 2000-ых,
копирайт в руководстве пользователя датирован 2002 годом. Принтеру уже больше
20 лет!

Этот принтер относится к классу устройств, с которыми нужно немного повозиться,
чтобы они заработали на Linux. Если знать тонкости, то подключить такой принтер
совсем не сложно. Вот как подключить его на Debian Bookworm.

Первым шагом нужно достать драйвер принтера Canon Advanced Printing Technology
(CAPT) последней версии. Сейчас это версия 2.71, релиз датирован 15 мая 2017
года. Вот ссылка на [сайт Canon] с драйверами.
Распаковываю загруженный драйвер.

```shell-session
$ tar xzf linux-capt-drv-v271-uken.tar.gz
```

В распакованном пакете можно увидеть папки с 32-х битными версиями и 64-х
битными. Запустить 64-х битные версии в прошлом у меня без дополнительной работы
не получилось. Скорее всего, есть проблемы с неявными зависимостями от 32-х
битных пакетов. Стоит отметить, что последняя проверенная версия Debian в
документации указана как "Debian GNU/Linux 5.02 32-bit". Устанавливаю 32-х
битную версию, предварительно включив поддержку `i386` у `dpkg`.

```shell-session
$ sudo dpkg --add-architecture i386
$ cd linux-capt-drv-v271-uken/32-bit_Driver/Debian/
$ sudo apt install ./*_i386.deb
```

Установка через `apt` подтянет все необходимые зависимости, даже в виде 32-х
битных пакетов. Одним из основных элементов CAPT является демон CCP. Обновляю
конфигурацию сервисов через `systemctl` и проверяю статус `ccpd.service`.

Обновление сервисов обязательно, т.к. пакеты CAPT не включают Systemd сервисы, а
только скрипты для System V, из которых Systemd сможет сгенерировать свои
сервисы на лету.

```shell-session
$ sudo systemctl daemon-reload
$ sudo systemctl start ccpd
$ systemctl status ccpd.service

● ccpd.service
     Loaded: loaded (/etc/init.d/ccpd; generated)
     Active: active (running) since Sat 2024-06-08 08:59:33 MSK; 4s ago
       Docs: man:systemd-sysv-generator(8)
    Process: 4368 ExecStart=/etc/init.d/ccpd start (code=exited, status=0/SUCCESS)
      Tasks: 1 (limit: 154370)
     Memory: 8.5M
        CPU: 33ms
     CGroup: /system.slice/ccpd.service
             └─4375 /usr/sbin/ccpd
```

Ага, запустилось! Перед добавлением принтера в CUPS нужно узнать имя подходящего
драйвера. Чтобы найти его, можно воспользоваться `lpinfo`.

```shell-session
$ sudo lpinfo -m | grep LBP1120

CNCUPSLBP1120CAPTJ.ppd Canon LBP1120 CAPT ver.1.5
CNCUPSLBP1120CAPTK.ppd Canon LBP1120 CAPT ver.1.5
lsb/usr/CNCUPSLBP1120CAPTJ.ppd Canon LBP1120 CAPT ver.1.5
lsb/usr/CNCUPSLBP1120CAPTK.ppd Canon LBP1120 CAPT ver.1.5
```

Методом проб и ошибок я выяснил, что именно CNCUPSLBP1120CAPT**K** является
нужным драйвером. Версия c **J**, похоже, относится к моделям с японского рынка.
Добавляю принтер с указанием драйвера через `lpadmin` под именем LBP1120

```shell-session
$ sudo lpadmin -p LBP1120 -m CNCUPSLBP1120CAPTK.ppd -v ccp://localhost:59687 -E

lpadmin: Printer drivers are deprecated and will stop working in a future version of CUPS.
```

Насчёт использованного адреса `ccp://localhost:59687` -- это стандартный FIFO
path, который мы увидим позже. Следующим шагом узнаю имя `lp`-устройства в
`/dev/`, которое соотносится с моим принтером. У меня один принтер, простого
`ls` хватит. На этом этапе принтер уже должен быть включен и подключен
USB-кабелем к ПК.

```shell-session
$ ls /dev/usb/lp*

/dev/usb/lp5
```

Добавляю новый принтер под именем LBP1120 с устройством `lp5` через `ccpadmin`.

```shell-session
$ sudo ccpdadmin -p LBP1120 -o /dev/usb/lp5

 CUPS_ConfigPath = /etc/cups/
 LOG Path        = None
 UI Port         = 59787

 Entry Num  : Spooler   : Backend       : FIFO path             : Device Path   : Status
 ----------------------------------------------------------------------------
     [0]    : LBP1120   : ccp           : //localhost:59687     : /dev/usb/lp5  : New!!

```

Успех. Принтер добавлен со стандартным FIFO path и нужным Device Path. Печатаю
тестовую страницу CUPS на пробу.

```shell-session
$ lpr /usr/share/cups/data/testprint
```

Если на данном шаге ничего не происходит то, возможно, нужно перезагрузить
`ccpd.service` с помощью `systemctl restart`. В некоторых случаях помогает
отключить-подключить принтер в другой USB-порт. Можно и перезагрузить систему,
главное не забыть потом запустить `ccpd.service` с помощью `systemctl start`.

Такое поведение я наблюдаю только после первого добавления принтера через
`ccpdadmin`. При последующем использовании проблемы с зависанием задания печати
я не увидел. Когда перезапустил `ccpd.service`, снова заново запускаю печать
тестовой страницы. На выходе у принтера получаю ожидаемую эталонную страницу.

Когда всё получилось, имеет смысл сделать автоматический старт `ccpd.service` с
помощью `systemctl enable`.

```shell-session
$ systemctl enable ccpd.service

ccpd.service is not a native service, redirecting to systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable ccpd
update-rc.d: error: ccpd Default-Start contains no runlevels, aborting.
```

Вспоминаю, что демон CCP поставляется только как скрипт инициализации System V в
`/etc/init.d`. Поскольку Systemd авто-генерирует свой сервис из этого скрипта,
мы можем определить запрашиваемые runlevels там. Открываем файл скрипта.

```shell-session
$ sudoedit /etc/init.d/ccpd
```

И добавляем блок `INIT INFO` между двух строк комментариев в самом начале файла.
Остальной файл не трогаем. Начало файла должно выглядеть следующим образом.

    #!/bin/sh
    ### BEGIN INIT INFO
    # Provides: ccpd
    # Default-Start: 2 3 4 5
    # Default-Stop: 0 1 6
    ### END INIT INFO
    # startup script for Canon Printer Daemon for CUPS (ccpd)

Сохраняемся и повторяем процедуру с `systemctl enable`.

```shell-session
$ sudo systemctl enable ccpd.service

ccpd.service is not a native service, redirecting to systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable ccpd
```

Теперь сервис должен автоматически стартовать при загрузке системы. Конечно,
можно настроить правила `udev` на подключение, но это чуть более сложная задача.

[сайт Canon]: https://www.canon.ru/support/consumer/products/printers/laser/lbp-series/laser-shot-lbp1120.html?type=drivers&os=Linux+%2864-bit%29
