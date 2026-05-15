---
title: Подключение JBL T450BT
author: Антон Муравьев
date: 2024-11-27T20:25:01+03:00
description: Настройка Bluetooth стека
guid: 110c4b29-8076-4879-a0bc-0088d43580d9
---

Подключая свои старые Bluetooth-наушники JBL T450BT, я столкнулся с проблемой.
GUI в KDE для pairing "подвисал". Перезагрузка `bluetooth.service` и системы
ничем не помогала...

Такая ситуация для меня в новинку. Другие, более новые Bluetooth-наушники, у
меня работают без-каких либо проблем. Хорошо, будем разбираться, что не так.

Опробовал пару вариантов в `bluetoothctl`. Чего удалось добиться -- появления
ошибки "Protocol not available". Явного ответа, что это за проблема, не было, но
я попробовал почитать журналы сервиса `bluetooth`.

```shell-session
$ sudo systemctl status bluetooth

● bluetooth.service - Bluetooth service
     Loaded: loaded (/lib/systemd/system/bluetooth.service; enabled; preset: enabled)
    Drop-In: /etc/systemd/system/bluetooth.service.d
             └─override.conf
     Active: active (running) since Wed 2024-11-27 18:57:10 MSK; 1min 25s ago
       Docs: man:bluetoothd(8)
   Main PID: 23759 (bluetoothd)
     Status: "Running"
      Tasks: 1 (limit: 154386)
     Memory: 1.3M
        CPU: 35ms
     CGroup: /system.slice/bluetooth.service
             └─23759 /usr/libexec/bluetooth/bluetoothd

bluetoothd[23759]: profiles/audio/vcp.c:vcp_init() D-Bus experimental not enabled
bluetoothd[23759]: src/plugin.c:plugin_init() Failed to init vcp plugin
bluetoothd[23759]: profiles/audio/mcp.c:mcp_init() D-Bus experimental not enabled
bluetoothd[23759]: src/plugin.c:plugin_init() Failed to init mcp plugin
bluetoothd[23759]: profiles/audio/bap.c:bap_init() D-Bus experimental not enabled
bluetoothd[23759]: src/plugin.c:plugin_init() Failed to init bap plugin
bluetoothd[23759]: Bluetooth management interface 1.22 initialized
bluetoothd[23759]: src/service.c:btd_service_connect() a2dp-sink profile connect failed for 71:04:64:5A:09:F2: Protocol not available
```

Значит, проблема в A2DP профиле. Странно. К сообщениям о "D-Bus experimental" мы
ещё вернёмся чуть позже, они решаются настройкой параметров запуска сервиса.

Большинство результатов поиска было для Ubuntu и в рекомендациях отмечали
необходимость установки `pulseaudio-module-bluetooth`. Пробую установить.

```shell-session
$ sudo apt install pulseaudio-module-bluetooth

Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
pulseaudio-module-bluetooth is already the newest version (16.1+dfsg1-2+b1).
pulseaudio-module-bluetooth set to manually installed.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
```

Хах, он уже был установлен. Пометим его обратно как авто-установку.

```shell-session
$ sudo apt-mark auto pulseaudio-module-bluetooth

pulseaudio-module-bluetooth set to automatically installed.
```

Очередной поиск привёл к одному замечательному [вопросу на
AskUbuntu](https://askubuntu.com/questions/1172000/a2dp-sink-profile-connect-failed).
Он описывает ситуацию в точности как у меня. Один из советов касался установки
`libspa-0.2-bluetooth`. Попробуем установить:

```shell-session
$ sudo apt install libspa-0.2-bluetooth

Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  liblc3-0 libldacbt-abr2
The following NEW packages will be installed:
  liblc3-0 libldacbt-abr2 libspa-0.2-bluetooth
0 upgraded, 3 newly installed, 0 to remove and 0 not upgraded.
Need to get 401 kB of archives.
After this operation, 1 453 kB of additional disk space will be used.

[...]
```

Надо не забыть перезапустить Wireplumber, это его модуль работы с Bluetooth.

```shell-session
$ systemctl --user restart wireplumber
```

После этого наушники подключились и стали видимы как устройство вывода аудио.

```shell-session
$ apt-cache show wireplumber | grep Suggests

Suggests: libspa-0.2-bluetooth, libspa-0.2-libcamera, wireplumber-doc
Suggests: libspa-0.2-bluetooth, wireplumber-doc
```

Дополнительно проверил зависимости и рекомендованные пакеты. Как видно, пакет
`libspa-0.2-bluetooth` предлагается к установке вместе с wireplumber, но не как
обязательная зависимость... Но да ладно, начинаю к этому привыкать...

Кроме того, в конфигурации по умолчанию, Bluetooth-стек в Debian 12 не даёт
информации о заряде устройства. На телефоне индикатор заряда наушников
присутствует и очень хочется получить его и на компьютере.

К счастью, коллеги с ArchWiki, как и в других случаях, уже [описали
решение](https://wiki.archlinux.org/title/Bluetooth) для этой задачи. Достаточно
отредактировать параметры конфигурации. Или установить флаг `--experimental` для
`bluetoothd`. Пойдём вторым путём.

Открываем редактирование override для `bluetooth.service`.

```shell-session
$ sudo systemctl edit bluetooth.service
```

Находим в самом начале строчки `ExecStart` и добавляем флаг `--experimental`.
Добавленный флаг выделен в примере ниже.

<pre>
[Service]
ExecStart=
ExecStart=/usr/libexec/bluetooth/bluetoothd --noplugin=sap <b>--experimental</b>
</pre>

Сохраняем файл и перезапускаем `bluetooth.service`.

```shell-session
$ sudo systemctl restart bluetooth.service
```

После перезапуска и подключения, я сразу увидел процент зарядки наушников.

Отдельно отмечу, что MPD упорно не хотел отдавать аудио на наушники. Эту
проблему решил для меня только классический метод перезапуска компьютера.
