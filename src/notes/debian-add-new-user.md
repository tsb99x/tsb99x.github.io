---
title: Добавление пользователя в Debian
author: Антон Муравьев
date: 2024-10-03T21:01:42+03:00
description: Программы `useradd` и `usermod`
guid: 23510639-8125-4afd-85a5-479b9c675dd4
changelog:
- date: 2024-10-28T19:00:13+03:00
  change: добавил информацию о группе `users`.
---

Добавление пользователя в Debian -- достаточно простая задача. В зависимости от
целей, можно создать пользователя с кастомной домашней директорией, с особым
комментарием или с нужной оболочкой. Читать [man useradd] и [man usermod].

Обычно мне достаточно создавать пользователя a-la стандартного. Такого же,
какого создаст Debian в процессе установки. Простой пример выглядит так.

```shell-session
$ sudo useradd bob -m -c 'Bob,,,' -s /bin/bash
$ sudo usermod -a -G users bob
```

Первая команда создаст пользователя `bob` с домашней директорией в `/home/bob`,
установит комментарий как `Bob,,,` и shell как `/bin/bash`. Также по-умолчанию
будет создана группа `bob`, в которую будет включен один пользователь `bob`.

Комментарий содержит три запятых, т.к. он выполнен в стандарте [GECOS].

Вторая команда добавит `bob` в группу `users`. Наличие этой группы у обычного
пользователя -- старая традиция. На практике общая группа полезна для передачи
файлов между пользователями через папку в ФС. Достаточно такой папке указать
группу владельца как `users` и дать права всей группе на чтение.

Проверить как выглядят новые данные о пользователе можно с помощью `getent`.
Можно заглядывать и в `/etc/passwd` вместе с `/etc/group`, но эти файлы не
отражают полную картину мира в случае, если нужно работать с LDAP и иными
сервисами. Правилом хорошего тона является использование именно `getent`.

```shell-session
$ getent passwd | grep bob

bob:x:1001:1001:Bob,,,:/home/bob:/bin/bash

$ getent group | grep bob

users:x:100:vm,bob
bob:x:1001:
```

После создания пользователя имеет смысл сразу задать для него пароль.

```shell-session
$ sudo passwd bob
```

Если при создании были забыты какие-то поля, то можно использовать `usermod`.

```shell-session
$ sudo usermod -m -d /tmp/bob bob
$ sudo usermod -c 'NotBob,,,' bob
$ sudo usermod -s /bin/dash bob
$ getent passwd | grep bob

bob:x:1001:1001:NotBob,,,:/tmp/bob:/bin/dash
```

Первая команда **переместит** домашнюю директорию в `/tmp/bob`, вторая заменит
комментарий, а третья изменит shell по-умолчанию на `/bin/dash`.

Конечно, если новый пользователь должен что-то администрировать, то его нужно
добавить в группу `sudo`, иначе `sudo` не разрешит исполнение команд.

```shell-session
$ sudo usermod -a -G sudo bob
$ getent group | grep bob

sudo:x:27:vm,bob
users:x:100:vm,bob
bob:x:1001:
```

Для удаления пользователя из группы можно использовать флаг `-r`.

```shell-session
$ sudo usermod -r -G sudo bob
$ getent group | grep bob

users:x:100:vm,bob
bob:x:1001:
```

Это основные сценарии работы с пользователями. Есть и ряд других инструментов,
например, `chsh`. Но в сейчас они дублируют возможности `useradd` и `usermod`.

[man useradd]: https://manpages.debian.org/bookworm/passwd/useradd.8.en.html
[man usermod]: https://manpages.debian.org/bookworm/passwd/usermod.8.en.html
[GECOS]: https://en.wikipedia.org/wiki/Gecos_field
