---
title: Функция `strlcpy` не найдена
author: Антон Муравьев
date: 2024-07-28T11:41:10+03:00
description: Собираем backport вручную
guid: b8ccfeae-b329-4669-9f36-f1b1054a80fb
changelog:
- date: 2024-08-21T20:51:09+03:00
  change: убрал бесполезное упоминание `fakeroot`.
- date: 2024-10-09T17:35:42+03:00
  change: заменил `ls -l` на `ls -1`, поправил форматирование.
- date: 2024-11-09T12:04:53+03:00
  change: добавил `cd` для перехода в рабочую папку.
---

Debian -- стабильная ОС. Но стабильность версий пакетов иногда необходимо
нарушить. К примеру, при использовании нового железа, имеет смысл использовать
[backport ядра Linux]. Я так и делаю.

На днях я столкнулся с новой проблемой. При обновлении ядра до версии 6.9, я
увидел ошибки DKMS. В частности, ошибки у модуля `v4l2loopback`.

Оказывается, Linux 6.8 больше не имеет функции `strlcpy`, как и ряда других.
В [обсуждении проблемы на GitHub] однозначно озвучивают требование версии ≥13
для `v4l2loopback`. Но такой версии в bookworm (stable) нет, там версия 12.

Нужная версия имеется у Debian только в trixie и sid, но не в backports для
stable. Значит, имеет смысл собрать пакет для stable самостоятельно.

Первым шагом устанавливаем необходимый тулинг.

```shell-session
$ sudo apt install build-essential devscripts
```

Теперь создаём рабочую папку для нового пакета.

```shell-session
$ mkdir v4l2loopback-backport
$ cd v4l2loopback-backport/
```

Идём на страницу пакета [v4l2loopback для trixie]. Там есть ссылки на файлы
`.dsc`, `.orig.tar.gz` и `.debian.tar.xz`. Нас интересует именно `.dsc` файл.
Достаточно скопировать ссылку и скормить её инструменту `dget`.

```shell-session
$ dget http://deb.debian.org/debian/pool/main/v/v4l2loopback/v4l2loopback_0.13.2-1.dsc

dget: retrieving http://deb.debian.org/debian/pool/main/v/v4l2loopback/v4l2loopback_0.13.2-1.dsc
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2375  100  2375    0     0  38990      0 --:--:-- --:--:-- --:--:-- 39583
dget: retrieving http://deb.debian.org/debian/pool/main/v/v4l2loopback/v4l2loopback_0.13.2.orig.tar.gz
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 84819  100 84819    0     0  1030k      0 --:--:-- --:--:-- --:--:-- 1035k
dget: retrieving http://deb.debian.org/debian/pool/main/v/v4l2loopback/v4l2loopback_0.13.2-1.debian.tar.xz
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  9396  100  9396    0     0   186k      0 --:--:-- --:--:-- --:--:--  187k
v4l2loopback_0.13.2-1.dsc:
      Good signature found
   validating v4l2loopback_0.13.2.orig.tar.gz
   validating v4l2loopback_0.13.2-1.debian.tar.xz
All files validated successfully.
gpg: no valid OpenPGP data found.
dpkg-source: info: extracting v4l2loopback in v4l2loopback-0.13.2
dpkg-source: info: unpacking v4l2loopback_0.13.2.orig.tar.gz
dpkg-source: info: unpacking v4l2loopback_0.13.2-1.debian.tar.xz
```

Инструмент `dget` -- это не более, чем скрипт, который
загружает `.dsc`, `.orig.tar.gz` и `.debian.tar.xz`, проверяет их и
распаковывает.

В общем смысле, можно то же самое сделать с помощью `wget` и `dpkg-source -x`,
но проще воспользоваться `dget`.

Переходим в новую папку, в которую `dget` распаковал исходный код.

```shell-session
$ cd v4l2loopback-0.13.2/
```

И запускаем сборку с помощью `debuild`:

```shell-session
$ debuild -b -uc -us

 dpkg-buildpackage -us -uc -ui -b
dpkg-buildpackage: info: source package v4l2loopback
dpkg-buildpackage: info: source version 0.13.2-1
dpkg-buildpackage: info: source distribution unstable
dpkg-buildpackage: info: source changed by IOhannes m zmölnig (Debian/GNU) <umlaeute@debian.org>
 dpkg-source --before-build .
dpkg-buildpackage: info: host architecture amd64
dpkg-checkbuilddeps: error: Unmet build dependencies: help2man
dpkg-buildpackage: warning: build dependencies/conflicts unsatisfied; aborting
dpkg-buildpackage: warning: (Use -d flag to override.)
debuild: fatal error at line 1182:
dpkg-buildpackage -us -uc -ui -b failed
```

Как видим, не хватает зависимостей (`help2man`). Не проблема. Есть возможность
автоматически установить все необходимые зависимости с помощью `apt`.

```shell-session
$ sudo apt build-dep .

Note, using directory '.' to get the build dependencies
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  help2man
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 198 kB of archives.
After this operation, 555 kB of additional disk space will be used.
Do you want to continue? [Y/n] Y
Get:1 http://deb.debian.org/debian bookworm/main amd64 help2man amd64 1.49.3 [198 kB]
Fetched 198 kB in 0s (1 517 kB/s)
Selecting previously unselected package help2man.
(Reading database ... 376690 files and directories currently installed.)
Preparing to unpack .../help2man_1.49.3_amd64.deb ...
Unpacking help2man (1.49.3) ...
Setting up help2man (1.49.3) ...
Processing triggers for man-db (2.11.2-2) ...
Processing triggers for install-info (6.8-6+b1) ...
```

Зависимости успешно установились, запускаем сборку заново. Вывод компилятора
опускаю, т.к. он не представляет интереса.

```shell-session
$ debuild -b -uc -us
```

Опять же, `debuild` -- не более, чем удобный скрипт, как и `dget`. Они призваны
упростить работу по сборке пакетов. При особом желании можно воспользоваться
напрямую `dpkg-buildpackage`.

Выходим из папки с исходным кодом после успешной компиляции и проверяем
наличие `.deb` пакетов.

```shell-session
$ cd ..
$ ls -1 *.deb

v4l2loopback-dkms_0.13.2-1_all.deb
v4l2loopback-source_0.13.2-1_all.deb
v4l2loopback-utils_0.13.2-1_amd64.deb
v4l2loopback-utils-dbgsym_0.13.2-1_amd64.deb
```

Из получившихся пакетов нас интересует только `v4l2loopback-dkms`
и `v4l2loopback-utils`. Устанавливаем их.

```shell-session
$ sudo apt install \
    ./v4l2loopback-dkms_0.13.2-1_all.deb \
    ./v4l2loopback-utils_0.13.2-1_amd64.deb
```

Вот и всё, пакет из trixie теперь и на stable!

---

Стоит отдельно отметить, что, в моём случае с `v4l2loopback`, модуль потребовал
ещё пары действий.

Первое -- требование переустановки модуля, иначе я получал ошибки
вида `WARNING! Diff between built and installed module!` в `dkms status`.

```shell-session
$ sudo dkms install v4l2loopback/0.13.2 --force
```

Второе -- пришлось явно включить загрузку модуля `v4l2loopback`, создав
файл `.conf` в `modules-load.d`.

```shell-session
$ echo 'v4l2loopback' | sudo tee /etc/modules-load.d/v4l2loopback.conf

v4l2loopback
```

После этого `v4l2loopback` работает как предполагается "из коробки".

[backport ядра Linux]: /notes/debian-backports.html
[обсуждении проблемы на GitHub]: https://github.com/umlaeute/v4l2loopback/issues/575
[v4l2loopback для trixie]: https://packages.debian.org/ru/source/trixie/v4l2loopback
