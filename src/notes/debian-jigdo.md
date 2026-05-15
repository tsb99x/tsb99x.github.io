---
title: Загрузка Debian с помощью jigdo
author: Антон Муравьев
date: 2024-01-14T14:12:00+03:00
description: Эффективное обновление релизных ISO
guid: 81bb94cd-115e-414c-955e-4f2ef20d07ab
changelog:
- date: 2024-09-02T13:22:52+03:00
  change: расширил практический пример работы с `jigdo`, уточнил мотивацию.
- date: 2025-03-16T12:10:10+03:00
  change: добавил пример верификации образов.
- date: 2025-05-23T17:10:36+03:00
  change: обновил для Debian 12.11, добавил видео-сопровождение.
---

<iframe
    class="rutube-player"
    src="https://rutube.ru/play/embed/38c011ea691c51f8c8d3e59323cb05a3/"
    frameBorder="0"
    allow="clipboard-write; autoplay"
    webkitAllowFullScreen
    mozallowfullscreen
    allowFullScreen
></iframe>

Один из самых привлекательных аспектов Debian для меня -- возможность загрузить
полноценный снимок `main` репозитория как ISO образ. Подход с использованием
утилиты `jigdo` позволяет это сделать максимально просто и эффективно.

Официальные [образы Debian DLBD] -- это простые ISO образы, предназначенные для
записи на [Dual-Layer Blu-ray Disk (DLBD)] или устройство соответствующего
размера. 3 образа ISO суммарно занимают чуть больше 90G на момент релиза 12.11.

Наличие такого бекапа значит, что Вы всегда сможете достать конкретную версию
определённого пакета из нужного релиза. И, вишенка на торте, обновлять релизные
образы можно без полного выкачивания их снова.

Идея `jigdo` крайне простая -- вместо размещения готового образа размещается
список всех пакетов, которые есть в релизе. В таком случае, всё, что нужно --
скачать к себе пакеты и собрать ISO, чем `jigdo` и занимается.

Одна из мотиваций для использования `jigdo` у самого проекта Debian в том,
чтобы сократить место на серверах проекта Debian. Другая -- сокращение
онлайн-трафика и использование уже существующих у клиентов образов.

Ключевая метрика такова: от релиза к релизу набор пакетов меняется не на все
100%... Это особенно актуально для минорных обновлений, как мы и увидим далее.

Приведу наглядный пример работы с `jigdo`, когда появился новый релиз 12.11.

В первую очередь, устанавливаю пакет `jigdo-file`, он содержит `jigdo-lite`, и
`wget`, он пригодится для загрузи самих Jigdo файлов:

```shell-session
$ sudo apt install jigdo-file wget
```

Создаю рабочую папку для нового релиза и перехожу туда.

```shell-session
$ mkdir debian-12.11.0-amd64-DLBD/
$ cd debian-12.11.0-amd64-DLBD/
```

Загружаю все актуальные файлы для образов и чек-суммы к ним вместе с подписями:

```shell-session
$ wget -q --show-progress \
    https://cdimage.debian.org/debian-cd/current/amd64/jigdo-dlbd/SHA{256,512}SUMS{,.sign}

SHA256SUMS                  100%[=========================================>]     903  --.-KB/s    in 0s
SHA256SUMS.sign             100%[=========================================>]     833  --.-KB/s    in 0s
SHA512SUMS                  100%[=========================================>]   1,44K  --.-KB/s    in 0s
SHA512SUMS.sign             100%[=========================================>]     833  --.-KB/s    in 0s

$ wget -q --show-progress \
    https://cdimage.debian.org/debian-cd/current/amd64/jigdo-dlbd/debian-12.11.0-amd64-DLBD-{1,2,3}.{jigdo,template}

debian-12.11.0-amd64-DLBD-1 100%[=========================================>] 800,01K  2,18MB/s    in 0,4s
debian-12.11.0-amd64-DLBD-1 100%[=========================================>] 114,87M  11,1MB/s    in 11s
debian-12.11.0-amd64-DLBD-2 100%[=========================================>]   1,06M  2,76MB/s    in 0,4s
debian-12.11.0-amd64-DLBD-2 100%[=========================================>]  26,79M  9,74MB/s    in 2,8s
debian-12.11.0-amd64-DLBD-3 100%[=========================================>]  10,38K  --.-KB/s    in 0,005s
debian-12.11.0-amd64-DLBD-3 100%[=========================================>] 372,48K  1,38MB/s    in 0,3s
```

Монтирую образ первого диска (DLBD-1) от старого 12.10:

```shell-session
$ cd ../debian-12.10.0-amd64-DLBD/

$ udisksctl loop-setup -f debian-12.10.0-amd64-DLBD-1.iso

Mapped file debian-12.10.0-amd64-DLBD-1.iso as /dev/loop0.

$ lsblk -f /dev/loop0

NAME      FSTYPE FSVER  LABEL                  UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0     iso966 Joliet Debian 12.10.0 amd64 1 2025-03-15-11-22-52-00
├─loop0p1 iso966 Joliet Debian 12.10.0 amd64 1 2025-03-15-11-22-52-00
└─loop0p2 vfat   FAT16                         DEB0-0001

$ udisksctl mount -b /dev/loop0p1

Mounted /dev/loop0p1 at /media/tsb99x/Debian 12.10.0 amd64 1

$ cd -

/home/tsb99x/Projects/debian-jigdo/debian-12.11.0-amd64-DLBD
```

Далее нужно запускать `jigdo-lite`. Сделать это можно в 2-ух режимах:
интерактивном и полностью автоматическом. В первый раз рекомендую интерактивный
режим.

```shell-session
$ jigdo-lite debian-12.11.0-amd64-DLBD-1.jigdo

[...]

Files to scan: /media/tsb99x/Debian 12.10.0 amd64 1

Not downloading .template file - `debian-12.11.0-amd64-DLBD-1.template' already present
Found 26138 of the 27192 files required by the template
Copied input files to temporary file `debian-12.11.0-amd64-DLBD-1.iso.tmp' - repeat command and supply more files to continue
```

Jigdo спросит, нужно ли просканировать какие-либо файлы. Поскольку у меня есть
образ старого релиза и он смонтирован в `/media/tsb99x/Debian 12.10.0 amd64 1`,
то я даю этот путь. Большая часть пакетов уже имеется. Нужно загрузить только
1054 пакета, чтобы получить ISO первого диска для нового релиза 12.11.

При следующем предложении просканировать файлы просто ввожу пустую строку. То же
делаю и при выборе зеркала для загрузки, это оставит его по умолчанию.

```shell-session
[...]

Files to scan:

-----------------------------------------------------------------
The jigdo file refers to files stored on Debian mirrors. Please
choose a Debian mirror as follows: Either enter a complete URL
pointing to a mirror (in the form
`ftp://ftp.debian.org/debian/'), or enter any regular expression
for searching through the list of mirrors: Try a two-letter
country code such as `de', or a country name like `United
States', or a server name like `sunsite'.
Debian mirror [http://deb.debian.org/debian]:

```

Теперь `jigdo-lite` начнёт загрузку. Он будет подгружать пакеты группами, а
затем соберёт диск релиза и сверит MD5-суммы.

```shell-session
[...]

FINISHED --2025-05-23 15:57:23--
Total wall clock time: 0,8s
Downloaded: 4 files, 2,5M in 0,5s (4,61 MB/s)
Found 4 of the 4 files required by the template
Successfully created `debian-12.11.0-amd64-DLBD-1.iso'

-----------------------------------------------------------------
Finished!
The fact that you got this far is a strong indication that `debian-12.11.0-amd64-DLBD-1.iso'
was generated correctly. I will perform an additional, final check,
which you can interrupt safely with Ctrl-C if you do not want to wait.

MD5 from template: iypLbkvUqW91WpgoqJsjWw
MD5 from image:    iypLbkvUqW91WpgoqJsjWw
OK: MD5 Checksums match, image is good!
WARNING: MD5 is not considered a secure hash!
WARNING: It is recommended to verify your image in other ways too!
```

Вот, у нас есть DLBD-1 от нового релиза.

Второй и третий диск давайте обновим уже в полностью автоматическом режиме.
Предварительно размонтируем DLBD-1 от релиза 12.10, а место него смонтируем
DLBD-2.

```shell-session
$ cd ../debian-12.10.0-amd64-DLBD/

$ udisksctl unmount -b /dev/loop0p1

Unmounted /dev/loop0p1.

$ udisksctl loop-delete -b /dev/loop0

$ udisksctl loop-setup -f debian-12.10.0-amd64-DLBD-2.iso

Mapped file debian-12.10.0-amd64-DLBD-2.iso as /dev/loop0.

$ lsblk -f /dev/loop0

NAME  FSTYPE FSVER      LABEL                  UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0 iso966 Joliet Ext Debian 12.10.0 amd64 2 2025-03-15-11-22-51-00

$ udisksctl mount -b /dev/loop0

Mounted /dev/loop0 at /media/tsb99x/Debian 12.10.0 amd64 2

$ cd -

/home/tsb99x/Projects/debian-jigdo/debian-12.11.0-amd64-DLBD

$ jigdo-lite --noask \
    --scan /media/tsb99x/Debian\ 12.10.0\ amd64\ 2/ \
    debian-12.11.0-amd64-DLBD-2.jigdo

[...]

FINISHED --2025-05-23 16:36:57--
Total wall clock time: 15s
Downloaded: 25 files, 51M in 14s (3,65 MB/s)
Found 25 of the 25 files required by the template
Successfully created `debian-12.11.0-amd64-DLBD-2.iso'

-----------------------------------------------------------------
Finished!
The fact that you got this far is a strong indication that `debian-12.11.0-amd64-DLBD-2.iso'
was generated correctly. I will perform an additional, final check,
which you can interrupt safely with Ctrl-C if you do not want to wait.

MD5 from template: AhK4piK-XmOBnzrDLrV_KA
MD5 from image:    AhK4piK-XmOBnzrDLrV_KA
OK: MD5 Checksums match, image is good!
WARNING: MD5 is not considered a secure hash!
WARNING: It is recommended to verify your image in other ways too!
```

На этот раз `jigdo-lite` не спросит вопросов, опции `--noask` и `--scan`
позволяют передать ответы при запуске программы.

Обновление третьего диска производиться по примеру второго.

После формирования новых ISO удаляем `/dev/loop0` и оставшийся файл с кешами:

```shell-session
$ udisksctl unmount -b /dev/loop0

Unmounted /dev/loop0.

$ udisksctl loop-delete -b /dev/loop0

$ rm jigdo-file-cache.db
```

Вот и всё, опционально рекомендую проверить SHA-256 и SHA-512 суммы. По желанию
можно верифицировать подлинность с помощью `gpg --verify`:

```shell-session
$ sha256sum -c SHA256SUMS

debian-12.11.0-amd64-DLBD-1.iso: OK
debian-12.11.0-amd64-DLBD-1.jigdo: OK
debian-12.11.0-amd64-DLBD-1.template: OK
debian-12.11.0-amd64-DLBD-2.iso: OK
debian-12.11.0-amd64-DLBD-2.jigdo: OK
debian-12.11.0-amd64-DLBD-2.template: OK
debian-12.11.0-amd64-DLBD-3.iso: OK
debian-12.11.0-amd64-DLBD-3.jigdo: OK
debian-12.11.0-amd64-DLBD-3.template: OK

$ sha512sum -c SHA512SUMS

debian-12.11.0-amd64-DLBD-1.iso: OK
debian-12.11.0-amd64-DLBD-1.jigdo: OK
debian-12.11.0-amd64-DLBD-1.template: OK
debian-12.11.0-amd64-DLBD-2.iso: OK
debian-12.11.0-amd64-DLBD-2.jigdo: OK
debian-12.11.0-amd64-DLBD-2.template: OK
debian-12.11.0-amd64-DLBD-3.iso: OK
debian-12.11.0-amd64-DLBD-3.jigdo: OK
debian-12.11.0-amd64-DLBD-3.template: OK

$ gpg --verify SHA256SUMS.sign

gpg: assuming signed data in 'SHA256SUMS'
gpg: Signature made Сб 17 мая 2025 20:55:57 MSK
gpg:                using RSA key DF9B9C49EAA9298432589D76DA87E80D6294BE9B
gpg: Good signature from "Debian CD signing key <debian-cd@lists.debian.org>" [full]

$ gpg --verify SHA512SUMS.sign

gpg: assuming signed data in 'SHA512SUMS'
gpg: Signature made Сб 17 мая 2025 20:55:57 MSK
gpg:                using RSA key DF9B9C49EAA9298432589D76DA87E80D6294BE9B
gpg: Good signature from "Debian CD signing key <debian-cd@lists.debian.org>" [full]
```

Если у Вас ещё нет публичного ключа Debian, то загрузить его можно так:

```shell-session
$ gpg --keyserver keyring.debian.org \
    --recv-keys DF9B9C49EAA9298432589D76DA87E80D6294BE9B

gpg: key DA87E80D6294BE9B: "Debian CD signing key <debian-cd@lists.debian.org>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
```

Отдельно стоит подчеркнуть, что система `jigdo`-загрузок позволяет Вам
"расширять" образ релиза при желании. Пример: я загрузил с помощью HTTP обычный
ISO от DVD-версии с нужным мне окружением рабочего стола. Потом, когда буду
готов поэкспериментировать больше, могу обновить DVD-версию до версии для 16G
флэш-накопителей. В свою очередь, 16G обновляется в BD (Blu-ray Disk), а уже он
может быть расширен в набор упомянутых DLBD.

Где сияет система `jigdo`, так это для загрузок минорных обновлений. Степень
переиспользования версий пакетов тут, очевидно, значительно выше, чем в мажорных
релизах. На примере обновления с 12.10 до 12.11, я вижу, что загрузил всего 2007
из 63823 пакетов. Т.е., чуть более 3% от общего количества пакетов.

Совместив гибкость такой системы загрузок/обновлений с возможностью держать
локальный архив репозитория Debian (по крайней мере, `main` часть), и для меня
ясно, что это один из лучших способов архивирования и обновления релизов Debian.

[образы Debian DLBD]: https://cdimage.debian.org/debian-cd/current/amd64/jigdo-dlbd/
[Dual-Layer Blu-ray Disk (DLBD)]: https://ru.wikipedia.org/wiki/Blu-ray_Disc
