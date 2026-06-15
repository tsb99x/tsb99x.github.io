---
title: Запускаем Ollama в Podman
author: Антон Муравьев
date: 2025-07-20T10:37:42+03:00
description: Локальная LLM на Linux
guid: 288caebd-d8fd-47a5-96bc-64224596aaeb
changelog:
- date: 2026-06-15T11:48:15+03:00
  change: Добавил переменную окружения `OLLAMA_KEEP_ALIVE`.
---

Из каждого утюга слышно про LLM. Их нынче называют AI, хотя я сомневаюсь в этом.
Мне, как любителю Open Source и Self Hosted, претит мысль пользоваться облачными
решениями. Поэтому LLM'ки, чтобы не отставать от моды, я разворачиваю локально.

[Ollama] -- простейшее решение для развёртывания LLM в контейнере. Это тулза,
которая позволит загружать LLM, запускать её и взаимодействовать через CLI. Доки
[Ollama на Docker Hub] дают понять, что для исполнения LLM на GPU от AMD мне
нужно загружать тег `rocm`. Начинаем с этого. Пользуюсь, по традиции, Podman.

```shell-session
$ podman pull docker.io/ollama/ollama:rocm

Trying to pull docker.io/ollama/ollama:rocm...
Getting image source signatures
Copying blob a1a22aa331e6 done
Copying blob b08e2ff4391e done
Copying blob bdf13fb94fec done
Copying blob 3fd4deb1a79f done
Copying config d466fc07e3 done
Writing manifest to image destination
Storing signatures
d466fc07e32ed2f07fa1c9de9e4fe48d5d4b1aab72a9083d3809018cce5f76c6

$ podman image ls ollama

REPOSITORY               TAG         IMAGE ID      CREATED      SIZE
docker.io/ollama/ollama  rocm        d466fc07e32e  11 days ago  6.42 GB
```

Да, образ толстенький. Теперь его надо запустить. На странице Docker Hub есть
команда для запуска на AMD GPU. Немного её модифицируем, добавив права опцией
`container_runtime_t` и сохраняя пользовательские группы опцией `keep-groups`.
Это нужно для Podman, ведь он выдаёт контейнерам меньше прав по-умолчанию.
Кроме этого добавил переменную окружения `OLLAMA_KEEP_ALIVE`, чтобы модели
автоматически выключались после 30 минут бездействия, а не 5, как обычно.

```shell-session
$ podman run -d \
    --device /dev/kfd \
    --device /dev/dri \
    -v ollama:/root/.ollama \
    -p 11434:11434 \
    -e OLLAMA_KEEP_ALIVE=30m \
    --name ollama \
    --security-opt label=type:container_runtime_t \
    --group-add keep-groups \
    ollama/ollama:rocm

f864498e8c3df755b854527e393f1372fb25dc3405374fdc75a8abf2a30c2e9b
```

Запустилось! Посмотрим на версию Ollama, заодно поймём как пользоваться CLI.

```shell-session
$ podman exec -it ollama ollama --version

ollama version is 0.9.6
```

Чтобы не писать каждый раз `podman exec -it ollama ollama`, делаем `alias`.

```shell-session
$ alias ollama='podman exec -it ollama ollama'
```

Загружаем какие-нибудь модели. Возмём [дистиллят попсового DeepSeek-R1] на 8
миллиардов параметров. Это не настоящая архитектура R1, но локально пойдёт.

```shell-session
$ ollama pull deepseek-r1:8b

pulling manifest
pulling e6a7edc1a4d7: 100% ▕██████████████████▏ 5.2 GB
pulling c5ad996bda6e: 100% ▕██████████████████▏  556 B
pulling 6e4c38e1172f: 100% ▕██████████████████▏ 1.1 KB
pulling ed8474dc73db: 100% ▕██████████████████▏  179 B
pulling f64cd5418e4b: 100% ▕██████████████████▏  487 B
verifying sha256 digest
writing manifest
success

$ ollama ls

NAME                     ID              SIZE      MODIFIED
deepseek-r1:8b           6995872bfe4c    5.2 GB    9 seconds ago
```

Ух, и это не самая большая модель! Запускаем интерактивный CLI с помощью `run`.

```shell-session
$ ollama run deepseek-r1:8b

>>> Hello there

Thinking...
Okay, the user just said “Hello there” – that's a pretty neutral and
friendly opening.

Hmm, they didn't specify their name or what they want to talk about yet.
Maybe they're just testing how I respond before diving into something more
substantial? Or perhaps they're in a greeting mode checking if it's an
appropriate time to interact.

Their message length suggests they might prefer concise responses too, but
I'll keep monitoring that as the conversation develops. For now, this
balanced approach should work well – friendly enough without being
overbearing.
...done thinking.

Hello! Hi there,

How can I help you today?

>>> Send a message (/? for help)
```

CLI даже показывает блок thinking, отражающего псевдо-мыслительный процесс LLM.
В целом бывает удобно для отладки промпта, если нейронка несёт полную чушь.

Чтобы погасить LLM, пользуемся `/bye` в чате и `podman stop` опосля.

```shell-session
>>> /bye

$ podman stop ollama

ollama
```

Чтобы обратно запустить Ollama, достаточно использовать `podman start`.

```shell-session
$ podman start ollama

ollama
```

На этом quick start можно завершать. Оставлю только одну ремарку -- все LLM'ки,
с которыми я пока поработал, несут полнейшую чушь время от времени, особенно
относительно фактической информации. Будьте внимательны и проверяйте ответы :)

[Ollama]: https://ollama.com/
[ollama на Docker Hub]: https://hub.docker.com/r/ollama/ollama
[дистиллят попсового DeepSeek-R1]: https://ollama.com/library/deepseek-r1
