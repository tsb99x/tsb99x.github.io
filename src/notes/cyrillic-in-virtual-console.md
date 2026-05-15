---
title: Кириллица в виртуальной консоли
author: Антон Муравьев
date: 2024-09-09T18:34:14+03:00
description: Настраиваем отображение и раскладку
guid: fe3fb771-44ea-4543-8bca-b31355a55788
changelog:
- date: 2025-03-10T12:35:35+03:00
  change: добавил post scriptum про использование CAPS Lock.
---

После установки Debian имеет смысл настроить для консоли отображение кириллицы и
русскую раскладку клавиатуры. Тогда можно работать с файловой системой, читать и
редактировать текст с кириллицей без графического интерфейса. Это будет удобно
для некоторых VM, ведь графика там нужна не всегда и можно обойтись консолью.

Отмечу, подобная настройка не требуется для SSH-сервера, там в первую очередь
нужна [генерация локали `ru`]. Речь будет только о настройке для так называемой
[виртуальной консоли]. Доступ к ней **обычно** получается физически, с помощью
комбинации <kbd>CTRL</kbd> + <kbd>ALT</kbd> + <kbd>F2</kbd>, а не о терминале в
графической среде. Там свои правила, определяемые графической средой
(Xorg/Wayland/etc.)

В рамках этой заметки я буду пользоваться программой `sed`. Она заменяет в файле
одну подстроку на другую. Если `sed` для Вас неудобен, то имеется `sudoedit`. Он
откроет интерактивный редактор типа `nano`, в котором можно внести изменения.

Первым делом объясним системе, что хотим видеть кириллицу в консоли. Пояснения
для этой части можно найти в [man console-setup]. Нужная конфигурация ожидает
нас в файле `console-setup`, который найдём в директории `/etc/default/`:

```shell-session
$ cat /etc/default/console-setup

# CONFIGURATION FILE FOR SETUPCON

# Consult the console-setup(5) manual page.

ACTIVE_CONSOLES="/dev/tty[1-6]"

CHARMAP="UTF-8"

CODESET="Lat15"
FONTFACE="Fixed"
FONTSIZE="8x16"

VIDEOMODE=

# The following is an example how to use a braille font
# FONT='lat9w-08.psf.gz brl-8x8.psf'
```

Видим `CODESET` установлен в `Lat15`, который не позволит отобразить кириллицу.
Необходимость настройки `CODESET` может казаться странной в наше время с UTF-8.
Виртуальная консоль в Linux имеет [VGA-совместимый режим]. Это и есть причина
ограничения в 256 (есть наборы по 512) символов для отображения одновременно.
Из-за этого и нужно устанавливать правильный `CODESET`. В страницах у `man`
рассказывают и про вариант `guess`, но я привык явно задавать кодировку.

Поменяем `CODESET` с `Lat15` на `CyrSlav`:

```shell-session
$ sudo sed -i 's/CODESET="Lat15"/CODESET="CyrSlav"/g' \
    /etc/default/console-setup
```

Переходим к раскладкам клавиатуры. Документацию найдём в [man keyboard], а также
в [man xkeyboard-config]. Конфигурация в `keyboard` из той же `/etc/default/`:

```shell-session
$ cat /etc/default/keyboard

# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""

BACKSPACE="guess"
```

Интересующие поля: `XKBLAYOUT`, `XKBVARIANT`, `XKBOPTIONS`. Установим нужные
значения для них один-за-одним. Добавим раскладку `ru` и опцию переключения.
В варианты записываем одну запятую, это означает простые `us` и `ru`:

```shell-session
$ sudo sed -i 's/XKBLAYOUT="us"/XKBLAYOUT="us,ru"/g' \
    /etc/default/keyboard
$ sudo sed -i 's/XKBVARIANT=""/XKBVARIANT=","/g' \
    /etc/default/keyboard
$ sudo sed -i 's/XKBOPTIONS=""/XKBOPTIONS="grp:win_space_toggle"/g' \
    /etc/default/keyboard
```

Можно ожидать, что в этой конфигурации переключение будет делаться по комбинации
<kbd>WIN</kbd> + <kbd>SPACE</kbd>. Это будет верно для SDDM и других
инструментов, использующих Xorg. Но в виртуальной консоли раскладка будет
переключаться с помощью <kbd>SHIFT</kbd> + <kbd>SPACE</kbd>!

Это неочевидно и может быть неудобно. Если Вы хотите что-то более очевидное, то
можно использовать `grp:alt_shift_toggle`, который производит переключение с
помощью <kbd>ALT</kbd> + <kbd>SHIFT</kbd> в любой среде, будь то SDDM или
виртуальная консоль.

Теперь нужно перезагрузиться для обновления настроек системы:

```shell-session
$ sudo reboot
```

После перезагрузки проверяю смену раскладки с помощью <kbd>WIN</kbd> +
<kbd>SPACE</kbd> в SDDM, а потом проверяю <kbd>SHIFT</kbd> + <kbd>SPACE</kbd> в
виртуальной консоли. Всё работает, супер!

# P.S.: CAPS Lock

После многих лет использования <kbd>WIN</kbd> + <kbd>SPACE</kbd> для
переключения раскладок, я всё же перешёл на использование <kbd>CAPS Lock</kbd>.
Пользуюсь новым вариантом переключения раскладки в течении полугода.

CAPS Lock оказался намного удобнее с точки зрения работы в Vim. Безымянный палец
уже привык переключать раскладку RU на EN сразу после выхода из режима INSERT в
NORMAL. Исходным вариантом CAPS Lock как "зажатым SHIFT" я не пользуюсь
практически никогда, поэтому ничего не потерял с точки зрения удобства.

Немного про механику. При использовании опции `grp:caps_toggle` однократное
нажатие <kbd>CAPS Lock</kbd> будет переключать раскладку. Нажатие вместе с
<kbd>SHIFT</kbd> будет работать как CAPS Lock по-умолчанию -- менять регистр
символов.

Вместе с `grp:caps_toggle` можно использовать опцию `grp_led:caps`. Тогда
горящий индикатор CAPS Lock на клавиатуре будет означать, что у Вас включена
раскладка с кириллицей. Работает `grp_led:caps` только в графической среде.

Финальная версия изменений `XKBOPTIONS` для меня выглядит так:

```shell-session
$ sudo sed -i 's/XKBOPTIONS=""/XKBOPTIONS="grp:caps_toggle,grp_led:caps"/g' \
    /etc/default/keyboard
```

[генерация локали `ru`]: /notes/generating-ru-locale.html
[виртуальной консоли]: https://ru.wikipedia.org/wiki/%D0%92%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D1%8C%D0%BD%D0%B0%D1%8F_%D0%BA%D0%BE%D0%BD%D1%81%D0%BE%D0%BB%D1%8C
[man console-setup]: https://manpages.debian.org/bookworm/console-setup/console-setup.5.en.html
[VGA-совместимый режим]: https://ru.wikipedia.org/wiki/%D0%A2%D0%B5%D0%BA%D1%81%D1%82%D0%BE%D0%B2%D1%8B%D0%B9_%D0%B2%D0%B8%D0%B4%D0%B5%D0%BE%D1%80%D0%B5%D0%B6%D0%B8%D0%BC_PC-%D1%81%D0%BE%D0%B2%D0%BC%D0%B5%D1%81%D1%82%D0%B8%D0%BC%D1%8B%D1%85_%D0%BA%D0%BE%D0%BC%D0%BF%D1%8C%D1%8E%D1%82%D0%B5%D1%80%D0%BE%D0%B2
[man keyboard]: https://manpages.debian.org/bookworm/keyboard-configuration/keyboard.5.en.html
[man xkeyboard-config]: https://manpages.debian.org/bookworm/xkb-data/xkeyboard-config.7.en.html
