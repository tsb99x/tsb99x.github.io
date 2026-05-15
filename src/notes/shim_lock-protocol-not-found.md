---
title: Протокол shim_lock не найден
author: Антон Муравьев
date: 2024-04-21T19:38:17+03:00
description: Проблема в Grub после обновления BIOS
guid: 3696d6d2-7131-4ce0-be09-1ab8dfe83752
---

Очередное обновление BIOS от MSI вместе с успешным обновлением AGESA снесло мне
все настройки, включая настройки Secure Boot. При первом запуске после установки
я увидел довольно необычные строки в GRUB:

```
Loading Linux 6.6.13+bpo-amd64 ...
error: shim_lock protocol not found.
Loading initial ramdisk ...
error: you need to load the kernel first.

Press any key to continue...
```

Обычно очистка ключей для Secure Boot выражается другими ошибками. Тем не менее
отключение Secure Boot в BIOS позволяет загрузиться в систему. Попробовал решить
проблему путём добавления `shimx64.efi` и `grubx64.efi` как доверенных файлов
для исполнения, но это не сработало, та же ошибка.

Поискал и наткнулся на интересный [вопрос на AskUbuntu] о проблеме `shim_lock`.
Ответы на вопрос навели на мысль, что есть проблемы именно с порядком загрузки,
ведь сообщение об ошибке явно говорит "you need to load the kernel first".
Возможно, `shimx64.efi` не загружается вовсе? Проверим опции загрузки:

```shell-session
$ efibootmgr -v

BootCurrent: 0001
Timeout: 1 seconds
BootOrder: 0001
Boot0001* debian        HD(1,GPT,f3fca44d-3df9-42f9-b351-a868c5830d9a,0x1000,0x96000)/File(\EFI\DEBIAN\GRUBX64.EFI)
```

Интересно, `shimx64.efi` действительно нет в очереди загрузки. Давайте попробуем
переконфигурировать `shim-signed` для добавления `shimx64.efi` в очередь
загрузки EFI:

```shell-session
$ sudo dpkg-reconfigure -f noninteractive shim-signed

Installing for x86_64-efi platform.
Installation finished. No error reported.
```

Посмотрим на опции и порядок загрузки после реконфигурации:

```shell-session
$ efibootmgr -v

BootCurrent: 0001
Timeout: 1 seconds
BootOrder: 0001
Boot0001* debian        HD(1,GPT,f3fca44d-3df9-42f9-b351-a868c5830d9a,0x1000,0x96000)/File(\EFI\debian\shimx64.efi)
```

Отлично, перезагружаемся в BIOS и включаем Secure Boot. Успешно загружаемся в
систему без ошибки с `shim_lock`. Посмотрим на вывод `efibootmgr` ради праздного
интереса:

```shell-session
$ efibootmgr -v

BootCurrent: 0001
Timeout: 1 seconds
BootOrder: 0001,0002
Boot0001* debian        HD(1,GPT,f3fca44d-3df9-42f9-b351-a868c5830d9a,0x1000,0x96000)/File(\EFI\DEBIAN\SHIMX64.EFI)
Boot0002* debian        HD(1,GPT,f3fca44d-3df9-42f9-b351-a868c5830d9a,0x1000,0x96000)/File(\EFI\DEBIAN\GRUBX64.EFI)..BO
```

Ага, значит дело было действительно в отсутствии `shimx64.efi` в очереди
загрузки *перед* `grubx64.efi`. Если Вам не помогло и это, то имеет смысл
переустановить Grub целиком:

```shell-session
$ sudo apt reinstall grub-efi-amd64
```

Это не только переустановит Grub, но и обновит все доступные опции загрузки и
сконфигурирует все зависимости, включая `shim-signed`.

Кроме порядка загрузки обновление BIOS сбросило и ключи, которые я использовал
для подписи сторонних модулей ядра. Эх, будем добавлять снова. Но это совсем
другая история...

[вопрос на AskUbuntu]: https://askubuntu.com/questions/1473389/error-shim-lock-protocol-not-found-in-grub-while-secure-boot-is-enabled#comment2652071_1473390
