---
title: Дедупликация BTRFS
author: Антон Муравьев
date: 2025-06-27T16:09:20+03:00
description: С помощью BEES
guid: 81c038ff-6a1c-4b00-96d7-c1dea41439f6
changelog:
- date: 2026-01-26T22:48:57+03:00
  change: добавил `pkg-config` и `systemd-dev` в список пакетов для установки.
---

Несколько недель назад я начал новый эксперимент по работе с BTRFS. На этот раз
целью стала оффлайн-дедупликация -- довольно сложный и неоднозначный процесс для
файловых систем на основе COW. Ближайший конкурент BTRFS, ZFS, имеет онлайн-вид
дедупликации, встроенный в ФС. В таком случае по умолчанию требуются большие
объёмы RAM. Также дедуп в онлайне увеличивает задержку при записи данных.

В BTRFS изначально было принято решение отказаться от идеи онлайн дедупликации и
надеяться на лучшее. А задачу выявления дубликатов отдать на откуп внешним
инструментам, которые пользователи буду сами использовать по необходимости.

Поработал я с двумя такими инструментами: [duperemove] и [BEES]. Сегодня коротко
расскажу про работу с BEES, т.к. он выглядит для меня куда более интересным и
(концептуально) чуть более простым инструментом, нежели duperemove.

Мой опыт с BEES был на версии 0.10. На днях (22 июня) вышла версия 0.11. Теперь
BEES опирается на более свежие ядра Linux, минимальное рекомендуемая версия ядра
-- 5.7. Из LTS это будет версия 6.1, как и стандартная у Debian Bookworm.

Не буду останавливаться на деталях того, как BEES работает, это замечательно
расписано разработчиком в файле [docs/how-it-works.md] в репозитории на GitHub.
Я же продолжу коротким практическом гайдом: как запускать и что смотреть.

Первым делом нужно выкачать репу с GitHub и перейти в новую папку.

```shell-session
$ git clone https://github.com/Zygo/bees.git

Cloning into 'bees'...
remote: Enumerating objects: 4594, done.
remote: Counting objects: 100% (1203/1203), done.
remote: Compressing objects: 100% (575/575), done.
remote: Total 4594 (delta 689), reused 754 (delta 610), pack-reused 3391 (from 2)
Receiving objects: 100% (4594/4594), 1.37 MiB | 4.41 MiB/s, done.
Resolving deltas: 100% (3134/3134), done.

$ cd bees/
```

Коммиты в основной ветке не являются релизными, поэтому смотрим на теги.

```shell-session
$ git tag | sort -rV | head

v0.11-rc4
v0.11-rc3
v0.11-rc2
v0.11-rc1
v0.11
v0.10
v0.9.3
v0.9.2
v0.9.1
v0.9
```

Версия 0.11 -- последняя, переходим на неё, собираем программу и устанавливаем.

```shell-session
$ git checkout v0.11

[...]

$ sudo apt install -y \
    build-essential \
    btrfs-progs \
    markdown \
    pkg-config \
    systemd-dev

[...]

$ make

[...]

$ sudo make install

[...]
install -Dm755 bin/bees /usr/lib/bees/bees
install -Dm755 scripts/beesd /usr/sbin/beesd
install -Dm644 scripts/beesd.conf.sample /etc/bees/beesd.conf.sample
install -Dm644 scripts/beesd@.service /lib/systemd/system/beesd@.service
```

Как видно, BEES установил бинарник `bees`, скрипт `beesd` и конфиг сервиса. На
этом этапе нужно сформировать конфигурацию для ФС. Пример конфига с базовыми
комментариями BEES положил в `/etc/bees/beesd.conf.sample`. Он полезный, но
многословный, я приведу пример своего `.conf`. Конфиги можно называть как
захочется, у меня он называется `data.conf`, как и BTRFS раздел.

```shell-session
$ cat /etc/bees/data.conf

UUID=bc574c75-0f22-45d1-b43d-13fdb423450e
OPTIONS="--strip-paths --verbose 7 --thread-count 4"
DB_SIZE=$((1*1024*1024*1024)) # 1G in bytes
```

Мне потребовалось установить всего 3 параметра (больше в [docs/options.md]):

- `UUID` -- UUID раздела BTRFS из `sudo btrfs filesystem show`.
- `OPTIONS` -- опции работы BEES:
    - `--strip-paths` -- для настоящих имён файлов в ФС
    - `--verbose 7` -- выводить в логах всё, исключая дебаг (уровень 8)
    - `--thread-count 4` -- ограничить работу 4-я потоками процессора.
- `DB_SIZE` -- размер файла с хэшами, оптимальный рассчитывается как 128M на 1T
данных. У меня раздел на 8Т, я установил 1G (1024M) = 128M * (8T / 1T).

Можно указать любой объём `DB_SIZE`, нужно только учитывать, что файл этого
объёма будет постоянно находится в оперативной памяти при работе BEES.

<blockquote class="warning"><p>

Изменение `DB_SIZE` после того, как BEES уже начал сканировать ФС, приведут к
новому сканированию **с нуля**! Будьте внимательны!

</p></blockquote>

После того, как Вы собрали свой `.conf` и положили в `/etc/bees/`, запустить
BEES можно через `systemctl`, а наблюдать за работой через `journalctl`.
Интересная особенность -- для сервиса требуется указывать UUID раздела BTRFS.

```shell-session
$ sudo systemctl start beesd@bc574c75-0f22-45d1-b43d-13fdb423450e

$ sudo journalctl -o cat -f -u beesd@bc574c75-0f22-45d1-b43d-13fdb423450e

2025-06-27 15:23:12 18211.18211<7> bees: context constructed
2025-06-27 15:23:12 18211.18211<7> bees: Parsing option 'no-timestamps'
2025-06-27 15:23:12 18211.18211<7> bees: Parsing option 'strip-paths'
2025-06-27 15:23:12 18211.18211<7> bees: Parsing option 'verbose'
2025-06-27 15:23:12 18211.18211<5> bees: log level set to 7
bees[18211]: setting worker thread pool maximum size to 4
bees[18211]: setting throttle factor to 0
bees[18211]: setting root path to '/run/bees/mnt/bc574c75-0f22-45d1-b43d-13fdb423450e'
bees[18211]: Starting bees main loop...
crawl_writeback[18243]: Using fsync on btrfs because kernel version is 6.12
[...]
```

В логах можно получать статус по состоянию, но проще смотреть в `.status` файл.
BEES обновляет этот файл в директории `/run/bees`. В `.status` есть очень много
информации и читать её тяжело. Для упрощения задачи нас интересует таблица в
самом конце файла, после строки с `PROGRESS:`. `sed`, как и всегда, выручит.

```shell-session
$ sudo sed -n '/PROGRESS:/,$ p' \
    /run/bees/bc574c75-0f22-45d1-b43d-13fdb423450e.status

PROGRESS:
extsz   datasz  point gen_min gen_max this cycle start tm_left   next cycle ETA
----- -------- ------ ------- ------- ---------------- ------- ----------------
  max   5.039T 004263       0  556061 2025-06-27 16:54  7h 47m 2025-06-28 00:43
  32M    1.53T 002409       0  556061 2025-06-27 16:54 13h 48m 2025-06-28 06:44
   8M 368.251G 003183       0  556061 2025-06-27 16:54 10h 26m 2025-06-28 03:22
   2M  84.163G 001566       0  556061 2025-06-27 16:54 21h 15m 2025-06-28 14:11
 512K  89.955G 000899       0  556061 2025-06-27 16:54  1d 13h 2025-06-29 05:58
 128K   1.671G 002137       0  556061 2025-06-27 16:54 15h 33m 2025-06-28 08:30
total   7.101T        gen_now  556066                  updated 2025-06-27 16:56
```

Цель здесь -- чтобы значения `gen_max` во всех строках сошлись со значением в
строке `total`, а в колонке `point` на всех строках было `idle` вместо цифр.
Соблюдение этих условий означает, что раздел ФС был полностью обработан BEES.

Вот так, для сравнения, выглядит `.status` для полностью просканированной ФС.

```shell-session
$ sudo sed -n '/PROGRESS:/,$ p' \
    /run/bees/bc574c75-0f22-45d1-b43d-13fdb423450e.status

PROGRESS:
extsz  datasz point gen_min gen_max this cycle start tm_left   next cycle ETA
----- ------- ----- ------- ------- ---------------- ------- ----------------
  max   5.69T  idle  555955  555957 2025-06-27 15:59       -                -
  32M  1.011T  idle  555955  555957 2025-06-27 15:59       -                -
   8M 307.66G  idle  555955  555957 2025-06-27 15:59       -                -
   2M 55.148G  idle  555955  555957 2025-06-27 15:59       -                -
 512K   37.6G  idle  555955  555957 2025-06-27 15:59       -                -
 128K  8.969G  idle  555955  555957 2025-06-27 15:59       -                -
total  7.101T       gen_now  555957                  updated 2025-06-27 15:59
```

Выключается BEES как и обычный сервис в `systemctl`.

```shell-session
$ sudo systemctl stop beesd@bc574c75-0f22-45d1-b43d-13fdb423450e
```

На этом основные элементы работы с BEES заканчиваются.

В целом, я не скажу, что дедупликация высвободила мне огромное количество места.
Нет, скорее наоборот -- дедуп привёл к росту метаданных, а на первых этапах BEES
и вовсе съел несколько сотен гигабайт, часть которых высвободил только подходя к
финалу полного сканирования раздела BTRFS. Такая себе оптимизация...

Основной эффект от BEES, судя по всему, должен наблюдаться, если использовать
его постоянно и **перед** созданием read-only снимков BTRFS. Подтвердить это
объективными данными мне сложно. Но над экспериментом стоит подумать :)

[duperemove]: https://github.com/markfasheh/duperemove
[bees]: https://github.com/Zygo/bees
[docs/how-it-works.md]: https://github.com/Zygo/bees/blob/master/docs/how-it-works.md
[docs/options.md]: https://github.com/Zygo/bees/blob/master/docs/options.md
