---
title: Testcontainers, Podman и Debian
author: Антон Муравьев
date: 2024-02-10T21:27:02+03:00
description: Интеграционные тесты без Docker
guid: 5a9d5d74-3264-49a3-8e22-a3cb98200989
---

На прошедшей неделе я столкнулся с неожиданной проблемой. [Testcontainers] для
JVM наотрез отказался работать с Podman. Но с Docker всё же успешно работало!
Сколько гайдов и подсказок я не видел, ничего не дало ожидаемых результатов.
Постоянно повторялась одна и та же ошибка:

```
Caused by: com.github.dockerjava.api.exception.InternalServerErrorException: Status 500: {
    "cause": "OCI runtime error",
    "message": "runc: runc create failed: unable to start container process: can't get final child's PID from pipe: EOF: OCI runtime error",
    "response": 500
}
```

[Релевантное обсуждение на GitHub] не дало ответов на все вопросы. Покопался,
стало ясно: проблема не в том, что именно запускается (я подозревал Ryuk), а то,
какой именно стек используется.

Оказывается, Podman по-умолчанию поставляется с `runc` в Debian, а для
устранения ошибки нужен `crun`. А ведь именно с ним и описана установка Podman
на [Wiki Debian о Podman]. Установил `crun` и удалил `runc`:

```shell-session
$ sudo apt install crun
$ sudo apt purge runc --auto-remove
```

Если коротко, то `crun` -- это совместимая с `runc` альтернатива OCI runtime.
`crun` несколько быстрее `runc` и лучше, согласно [утверждениям экспертов из
RedHat], подходит для использования с Podman в контексте rootless
контейнеризации. Как бы там не было, они должны быть взаимозаменяемы, но это
первый случай у меня в практике, когда потребовалось использовать `crun`.

В результате, для успешного запуска, кроме установки `crun`, потребовалась
следующая последовательность команд:

```shell-session
$ systemctl --user start podman.socket
$ export DOCKER_HOST=unix:///run/user/${UID}/podman/podman.sock
$ ./gradlew integrationTest
```

Никаких дополнительных переменных окружения для Ryuk и других инструментов
Testcontainers не потребовалось. Не потребовалось ни указание полного имени
используемого образа (к примеру, `docker.io/library/mysql` вместо `mysql`), ни
добавление `docker.io` в `unqualified-search-registries`.

Это разительно отличается от моего прошлого опыта перевода `docker-compose.yml`
в вариант для `podman-compose`. Самое главное -- не потребовалось никаких
изменений в исходном коде, супер!

Если в Вашем случае нужно постоянно использовать интеграционные тесты, то могу
порекомендовать сделать автоматический запуск `podman.socket` для пользователя:

```shell-session
$ systemctl --user enable podman.socket --now
```

Переменную окружения `DOCKER_HOST`, в таком случае, имеет смысл добавить в
конфигурацию запуска IDE для интеграционных тестов или, к примеру, добавить на
постоянной основе в ENV одним из сотен доступных способов, будь то `.bashrc`,
`.profile`, `Environment` в user-сервисе или `envvars.conf`.

[Testcontainers]: https://testcontainers.com/
[Релевантное обсуждение на GitHub]: https://github.com/testcontainers/testcontainers-java/issues/2088
[Wiki Debian о Podman]: https://wiki.debian.org/Podman
[утверждениям экспертов из RedHat]: https://www.redhat.com/sysadmin/introduction-crun
