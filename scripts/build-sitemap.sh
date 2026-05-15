#!/bin/bash
set -euo pipefail
shopt -s globstar

die() { printf "\033[0;31mERROR:\033[0m %s\n" "$1" >&2; exit 1; }

echo ---
echo title: Sitemap
echo pages:

for FILE in src/**/*.md; do
    [[ "$FILE" == "src/sitemap.md" ]] && continue
    LOC=$(echo "$FILE" | sed 's/src\///; s/\.md$/.html/ ; s/index.html//')
    echo "- loc: $LOC"
    LASTMOD=$(grep -Po '(?<=date: ).*$' "$FILE" | tail -1) \
        || die "Failed to parse date in $FILE"
    echo "  lastmod: $LASTMOD"
done

echo ---
