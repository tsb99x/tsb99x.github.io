---
title: UFW или Uncomplicated Firewall
author: Антон Муравьев
date: 2024-06-10T09:28:44+03:00
description: Базовые сценарии использования
guid: af97aad5-80eb-4174-b7d2-8f2c9d482273
---

Некоторые дистрибутивы Linux поставляются без включенного брандмауэра. С одной
стороны, можно спорить, что это удобно и не нужно заморачиваться с настройкой.
С другой стороны, это может привести к нежелательному доступу к локальным
сервисам.

Как бы там ни было, моя политика предельно проста -- брандмауэр должен быть и
должен по-умолчанию блокировать входящие соединения, т.е. работаем по модели
whitelist. Исходящие соединения представляют значительно больше сложности в
настройке и предпочтительный режим работы -- blacklist. Маршрутизация трафика
терминальным ПК должна быть запрещена.

Для Debian есть несколько актуальных решений, включая Uncomplicated Firewall
(UFW) и графическую утилиту для настройки под названием GUFW. Хотя в прошлом
мне казалось хорошей идеей дать пользователям GUI для настройки, со временем
я понял, что это не имеет большого смысла. Сам UFW крайне прост в настройке и
без GUI. Первый шаг -- установка из стандартных репозиториев.

```shell-session
$ sudo apt install ufw
```

После установки можем проверить статус UFW.

```shell-session
$ sudo ufw status

Status: inactive
```

После установки UFW будет выключен. Что же, давайте включим его.

```shell-session
$ sudo ufw enable

Command may disrupt existing ssh connections. Proceed with operation (y|n)? n
```

Стоп. Не забудьте добавить SSH-соединения в исключения. Разработчики услужливо
добавили логичный вопрос хотим ли мы продолжить, ведь SSH-соединение будет
прервано. Это неприемлемо для удалённых серверов к которым нет физического
доступа. Давайте разрешим входящие соединения по протоколу SSH.

```shell-session
$ sudo ufw allow ssh

Rules updated
Rules updated (v6)
```

Видим, что добавились 2 вида правил. Правило без `(v6)` относятся к IPv4, а с
`(v6)` уже к IPv6. Поскольку SSH-подключения разрешены, то можем активировать
Firewall.

```shell-session
$ sudo ufw enable

Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
Firewall is active and enabled on system startup
```

Firewall включен и мы можем проверить его подробный статус.

```shell-session
$ sudo ufw status verbose

Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
```

Видим в выводе 2 правила касательно SSH (22/tcp) в версии IPv4 и IPv6. Также
видим политики по-умолчанию. Они полностью соответствуют моим предпочтениям, что
радует.

То, как добавлен доступ к `sshd` путём `allow ssh` не подойдет для любых
приложений. Есть набор предопределённых правил для известных сервисов, но они не
содержат **всех** приложений, поэтому посмотрим на альтернативные механизмы
того, как понять и добавлять новые правила для нужных адресов и портов.

Иногда для проверки того, на каких портах приложение слушает соединения, полезно
использовать утилиту `ss`. Она входит в стандартную поставку Debian.

```shell-session
$ sudo ss -tulpn

Netid  State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
udp    UNCONN  0       0             0.0.0.0:68         0.0.0.0:*      users:(("dhclient",pid=543,fd=7))
tcp    LISTEN  0       128           0.0.0.0:22         0.0.0.0:*      users:(("sshd",pid=569,fd=3))
tcp    LISTEN  0       128              [::]:22            [::]:*      users:(("sshd",pid=569,fd=4))
```

Видим 3 порта. Один из них UDP и принадлежит `dhclient`, два TCP принадлежат
`sshd`. Один из TCP портов с адресом IPv4 `0.0.0.0`, а другой IPv6 `[::]`.
С помощью такой интроспекции можно достаточно просто настроить нужные правила.

Я иногда предпочитаю и другой способ. Он может быть чуть более утомительным, но
имеет большую степень точности. UFW журналирует сообщения о блокировках входящих
соединений. Достаточно включить режим отображения `journalctl` с обновлением в
реальном времени (следования) и следить за блокировками.

К примеру, запустим на компьютере с включенным UFW сервер HTTP на python.

```shell-session
$ python3 -m http.server

Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
```

После запуска сервера в другом терминале этого же ПК запускаем следование за
журналом и оставим только сообщения от UFW.

```shell-session
$ sudo journalctl -f | grep UFW
```

Теперь с **другого** компьютера запустим `wget`. Представим, что устройство с
HTTP сервером имеет адрес `192.168.122.9` (у меня это виртуальная машина).

```shell-session
$ wget --server-response --spider --tries 1 --timeout 3 192.168.122.9:8000

--2024-06-09 14:32:23--  http://192.168.122.9:8000/
Connecting to 192.168.122.9:8000... failed: Connection timed out.
Giving up.
```

Так, UFW нас отфутболил, идём смотреть логи `journalctl` на **сервер**. Там
увидим строчку по аналогии с приведённой ниже.

```
Jun 09 14:32:23 debian kernel: [UFW BLOCK]
    IN=enp1s0 OUT=
    MAC=52:54:00:4d:25:4f:52:54:00:96:02:67:08:00
    SRC=192.168.122.1 DST=192.168.122.9
    LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=4717
    DF PROTO=TCP SPT=59620 DPT=8000
    WINDOW=32120 RES=0x00 SYN URGP=0
```

Выделим важные части, чтобы понять, что нам можно использовать в UFW правилах.

- IN `enp1s0` и пустой OUT -- имена сетевых интерфейсов.
- Совмещенное поле MAC для указания:
  - MAC-адреса источника сообщения `52:54:00:4d:25:4f`
  - MAC-адреса цели сообщения `52:54:00:96:02:67`
  - Указания [EtherType] `08:00` -- это значит IPv4.
- IP-адрес источника SRC `192.168.122.1`
- IP-адрес цели DST `192.168.122.9`
- Протокол соединения PROTO `TCP`
- SPT `59620` -- с какого порта отправили сообщение
- DPT `8000` -- на какой порт отправили сообщение

Остальные параметры нам не нужны и, обычно, имеют интерес для других задач.

Давайте добавим новое правило, чтобы разрешить доступ к HTTP серверу.

```shell-session
$ sudo ufw allow \
    from 192.168.122.0/24 to 192.168.122.9 \
    port 8000 proto tcp \
    comment 'VM network access to Python HTTP Server'

Rule added
```

Тут мы указываем, что хотим разрешить соединение (`allow`) из сети
`192.168.122.0` с маской `/24` к порту `8000` нашего IP `192.168.122.9` по
протоколу `tcp`. Чтобы потом не забыть, что это за правило, добавляем
релевантный `comment`.

Это очень понятный текстовый формат, что и отличает UFW от других инструментов.
Части правила можно просто опустить. К примеру, приведённая выше команда может
не включать часть `from 192.168.122.0/24`. Это будет равнозначно описанию
`from any`, т.е. принимаем сообщения от **любого** IP. То же можно проделать и с
`to`, `port`, `proto` и `comment`, но эти эксперименты оставлю на усмотрение
читателя. Какие-то комбинации будут обязательны к заполнению, но UFW расскажет,
что именно ему не хватает.

Посмотрим, как это правило выглядит в расширенном статусе.

```shell-session
$ sudo ufw status verbose

Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                        Action      From
--                        ------      ----
22/tcp                    ALLOW IN    Anywhere
192.168.122.9 8000/tcp    ALLOW IN    192.168.122.0/24    # HTTP server access for VM network
22/tcp (v6)               ALLOW IN    Anywhere (v6)
```

Новое правило появилось. Проверим, что оно заработало. С другого устройства
опять запустим `wget`.

```shell-session
$ wget --server-response --spider --tries 1 --timeout 3 192.168.122.9:8000

Spider mode enabled. Check if remote file exists.
--2024-06-09 15:20:46--  http://192.168.122.9:8000/
Connecting to 192.168.122.9:8000... connected.
HTTP request sent, awaiting response...
  HTTP/1.0 200 OK
  Server: SimpleHTTP/0.6 Python/3.11.2
  Date: Sun, 09 Jun 2024 12:20:46 GMT
  Content-type: text/html; charset=utf-8
  Content-Length: 518
Length: 518 [text/html]
Remote file exists and could contain further links,
but recursion is disabled -- not retrieving.
```

Теперь HTTP сервер отвечает на запрос ровно так, как и ожидается, а UFW уже
пропускает соединения в соответствии с изменёнными правилами. Если правила не
применились, то можно использовать `sudo ufw reload` для перезагрузки UFW.

Исходный вид команды для добавления правила в UFW можно добыть командой `show`

```shell-session
$ sudo ufw show added

Added user rules (see 'ufw status' for running firewall):
ufw allow 22/tcp
ufw allow from 192.168.122.0/24 to 192.168.122.9 port 8000 proto tcp comment 'VM network access to Python HTTP Server'
```

Таким образом можно перенести правила между системами или сохранить их перед
модификацией. Кстати о модификации. Если правила требуется удалить, то можно
запросить нумерованный список правил.

```shell-session
$ sudo ufw status numbered

Status: active

     To                        Action      From
     --                        ------      ----
[ 1] 22/tcp                    ALLOW IN    Anywhere
[ 2] 192.168.122.9 8000/tcp    ALLOW IN    192.168.122.0/24    # HTTP server access for VM network
[ 3] 22/tcp (v6)               ALLOW IN    Anywhere (v6)
```

Теперь, зная номер правила, можно его удалить.

```shell-session
$ sudo ufw delete 2

Deleting:
 allow from 192.168.122.0/24 to 192.168.122.9 port 8000 proto tcp comment 'HTTP server access for VM network'
Proceed with operation (y|n)? y
Rule deleted
```

Если понадобится совсем выключить Firewall, то используйте `ufw disable`. Это
может пригодиться для отладки. Главное -- не забыть включить обратно!

```shell-session
$ sudo ufw disable

Firewall stopped and disabled on system startup
```

В остальном, у UFW ещё есть пару трюков в рукаве. Конечно, их нужно изучить и
столь мелкая заметка не включит всю информацию из `man ufw`. Советую почитать
man самостоятельно. Там есть другие примеры и объяснения как работать с UFW.

Как видно, UFW действует на достаточно низком уровне сетевых соединений и
транспортных потоков. Через UFW не получится добавить правила для одного
конкретного приложения, речь идёт только о работе с IP-адресами и портами.

Кому-то может показаться такая гранулярность контроля слишком крупной. Если Вам
требуются инструменты для работы с мелкой гранулярностью, вплоть до определения
какие приложения могут делать подключения куда, то я могу порекомендовать Вам
инструмент под названием [OpenSnitch].

Он всё это позволяет и даже находится в стандартных репозиториях Debian, хотя, я
бы посоветовал достать более свежую версию с GitHub. Этот open-source аналог
[Little Snitch] для MacOS и аналог [simplewall] для Windows.

[EtherType]: https://en.wikipedia.org/wiki/EtherType
[OpenSnitch]: https://github.com/evilsocket/opensnitch
[Little Snitch]: https://www.obdev.at/products/littlesnitch/index.html
[simplewall]: https://github.com/henrypp/simplewall
