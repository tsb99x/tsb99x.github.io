#!/usr/bin/env python3

import io
import json
import locale
import sys
from datetime import datetime
from typing import Any

from pandocfilters import Space, Str, elt  # type: ignore

MetaInlines = elt("MetaInlines", 1)


def read_json() -> Any:
    input_stream = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8")
    source = input_stream.read()
    return json.loads(source)


def print_json(document: Any) -> None:
    output = json.dumps(document)
    sys.stdout.write(output)


def main() -> None:
    document = read_json()

    # print(json.dumps(document, indent=4), file=sys.stderr)

    meta = document["meta"]
    assert meta["date"]["t"] == "MetaInlines"
    assert meta["date"]["c"][0]["t"] == "Str"
    date_str = meta["date"]["c"][0]["c"]
    date = datetime.fromisoformat(date_str)
    # FIXME : locale.setlocale seems to be a hack to overcome limitations
    # FIXME : of date.strftime(...) API. It might be better to use babel
    locale.setlocale(locale.LC_ALL, "ru_RU.UTF-8")
    # FIXME : '%-d' part is tricky, as it might not work on all OSes
    # FIXME : I've left it here, so day would be presented without leading zero
    # FIXME : i.e., with minus it would print 5, but 05 without it
    words = date.strftime("%-d %B %Y г.").split(" ")
    strs = map(Str, words)
    inline = [x for s in strs for x in (s, Space())][:-1]
    meta["date-ru"] = MetaInlines(inline)

    if meta.get("changelog"):
        assert meta["changelog"]["t"] == "MetaList"
        for entry in meta["changelog"]["c"]:
            assert entry["t"] == "MetaMap"
            entry_date_str = entry["c"]["date"]["c"][0]["c"]
            entry_date = datetime.fromisoformat(entry_date_str)
            entry_words = entry_date.strftime("%-d %B %Y г.").split(" ")
            strs = map(Str, entry_words)
            inline = [x for s in strs for x in (s, Space())][:-1]
            entry["c"]["date-ru"] = MetaInlines(inline)

    # print(json.dumps(document, indent=4), file=sys.stderr)

    print_json(document)


if __name__ == "__main__":
    main()
