#!/usr/bin/env python3

from datetime import datetime
from email.utils import format_datetime
from itertools import groupby
from pathlib import Path
from typing import Any

import yaml


def extract_metadata(filepath: Path) -> dict[str, Any]:
    with open(filepath, mode="r") as f:
        documents = f.read()
        data = next(yaml.safe_load_all(documents))
        data["filename"] = filepath.name.removesuffix(".md")
        data["date-rfc"] = format_datetime(data["date"])
        return dict(data)


def build_document(metas_by_year: dict[int, list[dict[str, Any]]]) -> dict[str, Any]:
    now = datetime.now()
    return {
        "title": "Заметки",
        "author": "Антон Муравьев",
        "description": "Небольшие заметки о том, что мне интересно",
        "date": now.astimezone().isoformat(timespec="seconds"),
        "date-rfc": format_datetime(now.astimezone()),
        "notes": [build_year(k, v) for k, v in metas_by_year.items()],
    }


def build_year(year: int, metas: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "year": year,
        "articles": [build_note_entry(x) for x in metas],
    }


def build_note_entry(meta: dict[str, Any]) -> dict[str, Any]:
    return {
        "title": meta["title"],
        "description": meta["description"],
        "date-rfc": meta["date-rfc"],
        "file": meta["filename"],
        "guid": meta["guid"],
    }


def main() -> None:
    notes = [p for p in Path("src/notes").glob("*.md") if p.is_file()]
    metas = map(extract_metadata, notes)
    ordered = sorted(metas, key=lambda m: m["date"], reverse=True)
    metas_by_year = {
        k: list(v) for k, v in groupby(ordered, key=lambda m: m["date"].year)
    }
    document = build_document(metas_by_year)
    output = yaml.safe_dump(document, allow_unicode=True, sort_keys=False)
    print("---")
    print(output, end="")
    print("---")


if __name__ == "__main__":
    main()
