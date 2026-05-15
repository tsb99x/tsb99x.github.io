---
title: Bash скрипт для тестов
author: Антон Муравьев
date: 2025-03-06T15:42:57+03:00
description: Автоматизация проверки решений
guid: ad3efed0-fd0c-44ae-87a9-b49d82d5a13a
changelog:
- date: 2025-03-14T20:33:26+03:00
  change: реструктурировал заметку, оставил только информацию о Bash скрипте.
- date: 2026-01-02T19:10:12+03:00
  change: перенёс исходный код на GitHub.
---

Тесты для задачек Advent of Code будут описаны на Bash. Парадигма ввода-вывода в
Си отдаёт приоритет прямой работе с STDIN, STDOUT и STDERR. Bash в таком случае
-- хороший компаньон для работы. Он позволит сделать универсальный скрипт и для
компиляции программы, и для линтинга, и для запуска тестов.

Посмотрим на код тестового скрипта `test_i.sh` для [задачки первого дня].

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

BIN=/tmp/part_i
SRC=./part_i.c

RESET='\033[0;0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1;37m'

check () {
        echo -ne "${BOLD}Test${RESET} $1 => $2 "
        OUTPUT=$(echo "$1" | $BIN 2>&1) && [ "$OUTPUT" = "$2" ] || {
                echo -e "${RED}FAILED${RESET}, output: $OUTPUT"
                false
        }
        echo -e "${GREEN}PASSED${RESET}"
}

clang -g -Og -std=c99 \
        -Weverything -Werror \
        -fsanitize=undefined,address \
        -fno-sanitize-recover=all \
        -o "$BIN" "$SRC"

gcc -g -Og -std=c99 \
        -Wall -Wextra -Wpedantic -Werror \
        -fsanitize=undefined,address \
        -fno-sanitize-recover=all \
        -o "$BIN" "$SRC"

clang-tidy $SRC 2> /dev/null

check '(())' 0
check '()()' 0
check '(((' 3
check '(()(()(' 3
check '))(((((' 3
check '())' -1
check '))(' -1
check ')))' -3
check ')())())' -3
echo 'All tests are completed and passed!'

ANSWER="$($BIN < ./input 2>&1)" && echo "Answer for input: $ANSWER" || {
        echo -e "${RED}Program has exited with non-zero code!${RESET}"
        echo "Output: $ANSWER"
}
```

В начале скрипта присутствует `set -euo pipeline` и `IFS=$'\n\t'`. Это ключевые
части [unofficial strict mode]. Погружаться в подробности мы не будем, отметим
только, что использование unofficial strict mode для Bash -- дело личного вкуса.

Основная часть тестового скрипта -- наивная функция `check`. Она принимает два
аргумента. Первый `$1` -- строка, которая с помощью `echo` отправляется на вход
приложения `$BIN`. Второй `$2` -- ожидаемый вывод программы, который проверяется
в квадратных скобках с помощью `=`.

Если приложение завершилось с ошибкой или вывод не имеет точного соответствия,
функция `check` выведет ошибку и вернёт `false`. Если всё ок -- скажет `PASSED`.

Структура функции `check` может выглядеть сложно, но если её декомпозировать, то
большая часть кода -- вывод с помощью `echo` и разукрашивание текста с помощью
[управляющих последовательностей ANSI]: `RED`, `GREEN`, `BOLD` и `RESET`.

До начала всех проверок скрипт прогонит исходник `$SRC` на 2-ух компиляторах.
Clang с флагом `-Weverything` послужит хорошим референсом для отлавливания
сомнительного кода. Дальнейшее тестирование будет проводиться на версии из GCC.

Дополнительная проверка от `clang-tidy` должна помочь с углубленным выявлением
проблемного кода и отдельного класса стилистических ошибок, связанных с Си.

После всех тестов в программу `$BIN` будет передан файл `input`, который
содержит ответ на задачу. В случае, если исполнение программы не завершилось
успешно, то будет выведена ошибка, как и в упомянутой выше функции `check`.

Отдельная ремарка должна быть посвящена конструкции `2&>1`. Это перенаправление
вывода STDERR в STDOUT. Нужно перенаправление для того, чтобы Вы могли получить
ошибку в `$OUTPUT` и `$ANSWER`. В ином случае там может быть пустая строка.

Этот скрипт, незначительно адаптированный, используется во всех задачках Advent
of Code. Решения задачек и тестовые скрипты для них можно найти в [репозитории]
на GitHub.

[задачки первого дня]: /notes/advent-of-code-2015-day-01.html
[unofficial strict mode]: http://redsymbol.net/articles/unofficial-bash-strict-mode/
[управляющих последовательностей ANSI]: https://ru.wikipedia.org/wiki/%D0%A3%D0%BF%D1%80%D0%B0%D0%B2%D0%BB%D1%8F%D1%8E%D1%89%D0%B8%D0%B5_%D0%BF%D0%BE%D1%81%D0%BB%D0%B5%D0%B4%D0%BE%D0%B2%D0%B0%D1%82%D0%B5%D0%BB%D1%8C%D0%BD%D0%BE%D1%81%D1%82%D0%B8_ANSI
[репозитории]: https://github.com/tsb99x/solutions
