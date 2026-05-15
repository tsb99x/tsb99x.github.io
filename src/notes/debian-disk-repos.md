---
title: Дисковые репозитории Debian
author: Антон Муравьев
date: 2024-09-30T17:39:40+03:00
description: Используем `apt-cdrom`
guid: 4e4e1410-ecfa-47f7-8f43-2e03ae4a054c
changelog:
- date: 2024-10-01T20:13:47+03:00
  change: добавил `--show-progress` для `wget` вместо последующего `ls -1`.
---

После установки Debian с диска есть два пути установки программ. Первый -- это
установка и [настройка стандартных сетевых репозиториев]. Второй подразумевает
использование дисков как репозиториев. В этой заметке рассмотрю второй вариант.

Например, хочу установить пакет `btop` на свежей системе, установленной с DLBD:

```shell-session
$ sudo apt install btop

Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  btop
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 0 B/465 kB of archives.
After this operation, 1 416 kB of additional disk space will be used.
Media change: please insert the disc labeled
 'Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-1 with firmware 20240831-10:40'
in the drive '/media/cdrom/' and press [Enter]
```

APT по-умолчанию настроен на использование диска и просит вставить в дисковод
конкретный диск. В данном случае, DLBD-1. Если у Вас есть дисковод, который
позволит читать оптические Blu-Ray диски, то всё становится предельно просто.
Нужно только вставить диск и нажать <kbd>Enter</kbd>.

А вот с USB-дисками всё чуть сложнее, их надо сначала смонтировать. Если это
первое монтирование, то создадим папку `/media/cdrom`. Это общепринятая точка
монтирования для оптических дисков, USB-флешек и даже ISO-образов.

```shell-session
$ mkdir -p /media/cdrom
```

Теперь подключаю флешку и монтирую её в `/media/cdrom`. Чтобы не заморачиваться
с поиском диска, монтирую его по названию. Это позволяет избежать ошибки. И да,
`\x20`, то есть пробелы, именно так и кодированы в `/by-label`.

```shell-session
$ sudo mount -o ro \
    /dev/disk/by-label/Debian\\x2012.7.0\\x20amd64\\x201 \
    /media/cdrom
```

После монтирования просто выполняю ту же операцию `apt install`.

```shell-session
$ sudo apt install btop

Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  btop
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 0 B/465 kB of archives.
After this operation, 1 416 kB of additional disk space will be used.
Get:1 cdrom://[Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-1 with firmware 20240831-10:40] bookworm/main amd64 btop amd64 1.2.13-1 [465 kB]
Selecting previously unselected package btop.
(Reading database ... 28402 files and directories currently installed.)
Preparing to unpack .../b/btop/btop_1.2.13-1_amd64.deb ...
Unpacking btop (1.2.13-1) ...
Setting up btop (1.2.13-1) ...
Processing triggers for mailcap (3.70+nmu1) ...
Processing triggers for man-db (2.11.2-2) ...
```

Установка успешна. А теперь установим, например, `apkverifier`. Сама утилита не
играет роли, но я точно знаю, что она находится на 2-м диске из набора DLBD.



```shell-session
$ sudo apt install apkverifier

Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
E: Unable to locate package apkverifier
```

Ожидаемо, пакет не найден. Если заглянуть в `source.list`, то там будет только
первый диск DLBD:

```shell-session
$ cat /etc/apt/sources.list

deb cdrom:[Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-1 with firmware 20240831-10:40]/ bookworm contrib main non-free-firmware
```

Ага, только `DLBD Binary-1`, т.е. DLBD-1. Чтобы устанавливать пакеты с DLBD-2,
нужно добавить его как репозиторий. Для этого поможет `apt-cdrom`, но сначала
размонтирую DLBD-1 и смонтирую DLBD-2.

```shell-session
$ sudo umount /media/cdrom
$ sudo mount -o ro \
    /dev/disk/by-label/Debian\\x2012.7.0\\x20amd64\\x202 \
    /media/cdrom
```

Отдельно отмечу цифру 2 в конце строки `/dev/disk/by-label`. Это точно 2-й диск.

Теперь воспользуемся `apt-cdrom` для добавления информации о репозитории.

```shell-session
$ sudo apt-cdrom add -m

Using CD-ROM mount point /media/cdrom/
Identifying... [c41cb969b7649d0341d77b739680f305-2]
Scanning disc for index files...
Found 3 package indexes, 0 source indexes, 0 translation indexes and 0 signatures
Found label 'Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-2 with firmware 20240831-10:40'
This disc is called:
'Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-2 with firmware 20240831-10:40'
Reading Package Indexes... Done
Writing new source list
Source list entries for this disc are:
deb cdrom:[Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-2 with firmware 20240831-10:40]/ bookworm contrib main non-free-firmware
Repeat this process for the rest of the CDs in your set.
```

Диск добавлен! Флаг `-m` нужен для того, чтобы `apt-cdrom` не (раз)монтировал
диски по своей прихоти. Мне удобнее работать именно с ним. Дополнительную
информацию о флагах, как и всегда, можно найти в [man apt-cdrom].

Проверяю, что теперь `apkverifier` устанавливается.

```shell-session
$ sudo apt install apkverifier

Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  apkverifier
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 0 B/1 122 kB of archives.
After this operation, 3 151 kB of additional disk space will be used.
Get:1 cdrom://[Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-2 with firmware 20240831-10:40] bookworm/main amd64 apkverifier amd64 0.0~git20191015.7330a51-11+b4 [1 122 kB]
Selecting previously unselected package apkverifier.
(Reading database ... 28440 files and directories currently installed.)
Preparing to unpack .../apkverifier_0.0~git20191015.7330a51-11+b4_amd64.deb ...
Unpacking apkverifier (0.0~git20191015.7330a51-11+b4) ...
Setting up apkverifier (0.0~git20191015.7330a51-11+b4) ...
Processing triggers for man-db (2.11.2-2) ...
```

Всё получилось. Чтобы не гадать, где именно на дисках располагается пакет, можно
прибегнуть, опять же, к 2-м путям. Первый -- добавить все 3 диска релиза с
помощью `apt-cdrom`. Тогда `apt` сам подскажет, какой диск нужно смонтировать.

Второй более мудрёный. Если Вы уверены, что нужный пакет где-то на дисках, то
проверить где он поможет [онлайн-утилита для поиска пакетов]. У меня эта утилита
работает через раз, поэтому покажу альтернативной подход.

Вот [список пакетов на дисках DLBD]. Скачаем все списки и проверим, где именно
находится пакет `apkverifier`:

```shell-session
$ wget -q --show-progress \
    https://cdimage.debian.org/debian-cd/current/amd64/list-dlbd/debian-12.7.0-amd64-DLBD-{1,2,3}.list.gz

debian-12.7.0-amd64 100%[===================>] 233,65K  --.-KB/s    in 0,1s
debian-12.7.0-amd64 100%[===================>] 334,60K  --.-KB/s    in 0,04s
debian-12.7.0-amd64 100%[===================>]   1,79K  --.-KB/s    in 0s

$ zgrep apkverifier *.gz

debian-12.7.0-amd64-DLBD-2.list.gz:apkverifier_0.0~git20191015.7330a51-11+b4_amd64.deb
debian-12.7.0-amd64-DLBD-2.list.gz:golang-github-avast-apkverifier-dev_0.0~git20191015.7330a51-11_all.deb
```

Таким образом подтверждаем, что он есть на DLBD-2.

[настройка стандартных сетевых репозиториев]: /notes/standard-network-repos.html
[man apt-cdrom]: https://manpages.debian.org/bookworm/apt/apt-cdrom.8.en.html
[онлайн-утилита для поиска пакетов]: https://cdimage-search.debian.org
[список пакетов на дисках DLBD]: https://cdimage.debian.org/debian-cd/current/amd64/list-dlbd/
