---
title: Включаем Hyper-V через PowerShell
author: Антон Муравьев
date: 2019-12-25T19:30:36+03:00
description: Никакого GUI, только PS в Windows 10
guid: 5041b014-1a0e-4eee-944c-b8ba0771c66a
changelog:
- date: 2024-01-26T19:45:10+03:00
  change: перевел и перенес заметку с Gist, обновил ссылки на документацию.
- date: 2025-03-28T13:26:05+03:00
  change: стилистически обновил текст.
---

> Исходный текст был опубликован в формате [Markdown] на [Gist] в декабре 2019
> года.

Включение функций Windows 10 через графический интерфейс -- неудобно, особенно
для автоматического развёртывания. Мне требовалось установить Docker Desktop на
Windows, для чего необходим Hyper-V. Решить эту задачу помог cmdlet для
[включения функций] Windows.

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

После перезагрузки системы Hyper-V будет включен.

Некоторые программы могут быть несовместимы с включенным Hyper-V, например,
старые версии VirtualBox, не поддерживающие его. Для отключения Hyper-V можно
использовать cmdlet, [обратный предыдущему].

```powershell
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

После перезагрузки можно будет снова использовать VirtualBox.

Эти команды позволяют включать и отключать любые функции Windows, доступные в
графическом интерфейсе, а не только `Microsoft-Hyper-V`. Однако, возникает
проблема: имена функций в командной строке не совпадают с их отображением в GUI.
Приходится тратить время на поиск нужного `-FeatureName`. С этой задачей поможет
cmdlet для [поиска функций].

```powershell
Get-WindowsOptionalFeature -Online
```

---

Таким образом, используя cmdlet PowerShell для включения и отключения функций
Windows, можно автоматизировать настройку системы, в том числе установку
Hyper-V. Несмотря на некоторые сложности с поиском правильных имён функций,
инструменты PowerShell предоставляют гибкий и эффективный способ управления
системой без использования графического интерфейса.

[Gist]: https://gist.github.com/
[Markdown]: https://daringfireball.net/projects/markdown/
[включения функций]: https://learn.microsoft.com/en-us/powershell/module/dism/enable-windowsoptionalfeature?view=windowsserver2022-ps
[обратный предыдущему]: https://learn.microsoft.com/en-us/powershell/module/dism/disable-windowsoptionalfeature?view=windowsserver2022-ps
[поиска функций]: https://learn.microsoft.com/en-us/powershell/module/dism/get-windowsoptionalfeature?view=windowsserver2022-ps
