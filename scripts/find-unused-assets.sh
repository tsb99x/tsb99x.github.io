#!/bin/sh -eux

cd www/notes
find res/ -type f -not -iname '*.html' -exec sh -c 'rg -q {} || echo {}' \;
find . -maxdepth 1 -type f -not -iname '*.html' -exec sh -c 'rg -q $(basename {}) || echo {}' \;
