#!/usr/bin/env python3
# mypy: ignore-errors

from pandocfilters import RawBlock, toJSONFilter
from pygments import highlight
from pygments.formatters import get_formatter_by_name
from pygments.lexers import get_lexer_by_name


def pygmentize(key, value, format, _):
    if key == "CodeBlock":
        [[_, classes, _], code] = value
        if classes:
            lexer = get_lexer_by_name(classes[0])
            formatter = get_formatter_by_name(format, wrapcode=True)
            processed = highlight(code, lexer, formatter)
            return [RawBlock(format, processed)]
    return None


if __name__ == "__main__":
    toJSONFilter(pygmentize)
