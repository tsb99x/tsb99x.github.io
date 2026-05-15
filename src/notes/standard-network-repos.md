---
title: Стандартные сетевые репозитории
author: Антон Муравьев
date: 2024-09-18T19:53:22+03:00
description: Где взять `sources.list`
guid: 5fd73a51-3260-44c9-bdb3-466c4eb0a36b
---

Если Debian был установлен *не* с диска netinst или live версии, то `apt` будет
работать только с тем самым установочным диском. Другими словами, `apt` не будет
использовать репозитории в интернете, а часто нужно использование именно сетевых
репозиториев для получения самых свежих обновлений. В том числе и безопасности.

Индикатором проблемы с `sources.list` станет ошибка при попытке обновления:

```shell-session
$ sudo apt update

Ign:1 cdrom://[Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-1 with firmware 20240831-10:40] bookworm InRelease
Err:2 cdrom://[Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-1 with firmware 20240831-10:40] bookworm Release
  Please use apt-cdrom to make this CD-ROM recognized by APT. apt-get update cannot be used to add new CD-ROMs
Reading package lists... Done
E: The repository 'cdrom://[Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-1 with firmware 20240831-10:40] bookworm Release' does not have a Release file.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
```

Видно, что при обновлении списка доступных пакетов игнорируются диски. Причина
для этого проста -- на дисках не обновляется список пакетов. Т.е., `apt update`
не имеет смысла выполнять на системах, которые обновляются с дисков. Сетевых
репозиториев в выводе нет. Чтобы проверить, какие репозитории используются,
достаточно посмотреть в файл `sources.list`, находящийся в `/etc/apt/`:

```shell-session
$ cat /etc/apt/sources.list

deb cdrom:[Debian GNU/Linux 12.7.0 _Bookworm_ - Official amd64 DLBD Binary-1 with firmware 20240831-10:40]/ bookworm contrib main non-free-firmware
```

Видим один единственный `cdrom://`. Это установочный диск, а больше ничего нет.

В качестве документации к `sources.list` можно почитать [man sources.list].
Искать и добавлять каждый репозиторий можно вручную, но есть более удачный
способ получить готовый список, аналогичный netinst и live установке.

Этот способ разобран в ответе на [вопрос на StackExchange]. Парафразирую:
достаточно скопировать один файл, который уже есть в стандартной установке.

Это файл `sources.list`, находится в `/usr/share/doc/apt/examples`. Посмотрим:

```shell-session
$ cat /usr/share/doc/apt/examples/sources.list

# See sources.list(5) manpage for more information
# Remember that CD-ROMs, DVDs and such are managed through the apt-cdrom tool.
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

# Uncomment if you want the apt-get source function to work
#deb-src http://deb.debian.org/debian bookworm main contrib non-free
#deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free
#deb-src http://deb.debian.org/debian-security bookworm-security main contrib non-free
```

Отлично, как видим, включены все нужные по-умолчанию репозитории. И релизный,
и updates, и security. Просто копирую файл в `/etc/apt/` и делаю `update`:

```shell-session
$ sudo cp /usr/share/doc/apt/examples/sources.list /etc/apt/
$ sudo apt update

Get:1 http://deb.debian.org/debian bookworm InRelease [151 kB]
Get:2 http://deb.debian.org/debian bookworm-updates InRelease [55,4 kB]
Get:3 http://deb.debian.org/debian-security bookworm-security InRelease [48,0 kB]
Get:4 http://deb.debian.org/debian bookworm/main amd64 Packages [8 787 kB]
Get:5 http://deb.debian.org/debian bookworm/main Translation-en [6 109 kB]
Get:6 http://deb.debian.org/debian bookworm/contrib amd64 Packages [54,1 kB]
Get:7 http://deb.debian.org/debian bookworm/contrib Translation-en [48,8 kB]
Get:8 http://deb.debian.org/debian bookworm/non-free amd64 Packages [97,3 kB]
Get:9 http://deb.debian.org/debian bookworm/non-free Translation-en [67,0 kB]
Get:10 http://deb.debian.org/debian bookworm/non-free-firmware amd64 Packages [6 236 B]
Get:11 http://deb.debian.org/debian bookworm/non-free-firmware Translation-en [20,9 kB]
Get:12 http://deb.debian.org/debian bookworm-updates/main amd64 Packages [2 468 B]
Get:13 http://deb.debian.org/debian bookworm-updates/main Translation-en [2 928 B]
Get:14 http://deb.debian.org/debian bookworm-updates/contrib amd64 Packages [768 B]
Get:15 http://deb.debian.org/debian bookworm-updates/contrib Translation-en [408 B]
Get:16 http://deb.debian.org/debian bookworm-updates/non-free amd64 Packages [12,8 kB]
Get:17 http://deb.debian.org/debian bookworm-updates/non-free Translation-en [7 744 B]
Get:18 http://deb.debian.org/debian bookworm-updates/non-free-firmware amd64 Packages [616 B]
Get:19 http://deb.debian.org/debian bookworm-updates/non-free-firmware Translation-en [384 B]
Get:20 http://deb.debian.org/debian-security bookworm-security/main amd64 Packages [182 kB]
Get:21 http://deb.debian.org/debian-security bookworm-security/main Translation-en [110 kB]
Get:22 http://deb.debian.org/debian-security bookworm-security/contrib amd64 Packages [644 B]
Get:23 http://deb.debian.org/debian-security bookworm-security/contrib Translation-en [372 B]
Get:24 http://deb.debian.org/debian-security bookworm-security/non-free-firmware amd64 Packages [688 B]
Get:25 http://deb.debian.org/debian-security bookworm-security/non-free-firmware Translation-en [472 B]
Fetched 15,8 MB in 7s (2 173 kB/s)
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
7 packages can be upgraded. Run 'apt list --upgradable' to see them.
```

На этот раз список пакетов успешно обновился из сетевых репозиториев, как нужно.
К слову, eсли у Вас Ubuntu, то аналогичный подход [применим и к Ubuntu].

[man sources.list]: https://manpages.debian.org/bookworm/apt/sources.list.5.en.html
[вопрос на StackExchange]: https://unix.stackexchange.com/questions/671655/how-do-i-restore-the-default-sources-list-file-on-debian-11-bullseye
[применим и к Ubuntu]: https://askubuntu.com/questions/701732/how-do-i-revert-my-source-list-from-the-source-list-backup
