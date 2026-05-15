.DELETE_ON_ERROR:

BASE_URI := https://tsb99x.github.io

CSS_SRC := $(shell find src/ -type f -name '*.css')
CSS := $(CSS_SRC:src/%=www/%)
NOTES_SRC := $(shell find src/notes/ -type f -name '*.md' -not -name 'index.md')
NOTES := $(NOTES_SRC:src/notes/%.md=www/notes/%.html)
IMAGES_SRC := $(shell find src/ -type f -name '*.webp' -o -name '*.svg')
IMAGES := $(IMAGES_SRC:src/%=www/%)

FONTS := \
	www/res/JetBrainsMono-Basic-Latin-Regular.woff2 \
	www/res/JetBrainsMono-Basic-Latin-Bold.woff2 \
	www/res/JetBrainsMono-Latin-1-Supplement-Regular.woff2 \
	www/res/JetBrainsMono-Latin-1-Supplement-Bold.woff2 \
	www/res/JetBrainsMono-Combining-Diacritical-Marks-Regular.woff2 \
	www/res/JetBrainsMono-Combining-Diacritical-Marks-Bold.woff2 \
	www/res/JetBrainsMono-Cyrillic-Regular.woff2 \
	www/res/JetBrainsMono-Cyrillic-Bold.woff2 \
	www/res/JetBrainsMono-General-Punctuation-Regular.woff2 \
	www/res/JetBrainsMono-General-Punctuation-Bold.woff2 \
	www/res/JetBrainsMono-Mathematical-Operators-Regular.woff2 \
	www/res/JetBrainsMono-Mathematical-Operators-Bold.woff2 \
	www/res/JetBrainsMono-Box-Drawing-Regular.woff2 \
	www/res/JetBrainsMono-Box-Drawing-Bold.woff2 \
	www/res/JetBrainsMono-Geometric-Shapes-Regular.woff2 \
	www/res/JetBrainsMono-Geometric-Shapes-Bold.woff2 \
	www/res/JetBrainsMono-Block-Elements-Regular.woff2 \
	www/res/JetBrainsMono-Block-Elements-Bold.woff2 \

all: scaffold $(CSS) $(NOTES) $(IMAGES) $(FONTS) \
	www/favicon.ico \
	www/robots.txt \
	www/index.html \
	www/notes/index.html \
	www/notes/feed.xml \
	www/notes/fixgz.zip \
	www/sitemap.xml \
	www/res/avatar-512x512.png

scaffold:
	mkdir -p www/notes/res
	mkdir -p www/res

serve:
	python3 -m http.server -d www --bind ::

nginx:
	podman build -t website .
	podman run -it -p 8080:80 --rm localhost/website

git-gc:
	du -sh .git
	git reflog expire --expire-unreachable=now --all
	git gc --prune=now
	du -sh .git

index-cleanup:
	rm -f src/notes/index.md
	rm -f www/notes/index.html
	rm -f www/notes/feed.xml
	rm -f src/sitemap.md
	rm -f www/sitemap.xml

.PHONY: all scaffold serve verify-fonts nginx git-gc index-cleanup

src/notes/index.md: $(NOTES_SRC) scripts/build-notes-index.py
	./scripts/build-notes-index.py > $@

src/sitemap.md: $(NOTES_SRC) src/index.md src/notes/index.md scripts/build-sitemap.sh
	./scripts/build-sitemap.sh > $@

www/%: src/%
	cp -a $< $@

www/%.svg: src/%.svg
	scour --remove-metadata --remove-titles --enable-id-stripping --create-groups $< $@

www/robots.txt: src/robots.tmpl
	BASE_URI="$(BASE_URI)" envsubst < $< > $@

www/index.html: src/index.md templates/index.html
	pandoc --fail-if-warnings --wrap=none -f markdown -t html \
	--template templates/index.html \
	--metadata base-uri="$(BASE_URI)" \
	--include-after-body templates/footer.html \
	$< -o $@

www/sitemap.xml: src/sitemap.md templates/sitemap.xml
	pandoc --fail-if-warnings --wrap=none -f markdown -t html \
	--template templates/sitemap.xml \
	--metadata base-uri="$(BASE_URI)" \
	$< -o $@

www/notes/%.html: src/notes/%.md templates/note.html templates/header.html templates/footer.html scripts/pygmentize.py scripts/date-ru.py
	pandoc --fail-if-warnings --wrap=none -f markdown -t html \
	--template templates/note.html \
	--metadata output-filename="$(notdir $@)" \
	--metadata base-uri="$(BASE_URI)" \
	--include-before-body templates/header.html \
	--include-after-body templates/footer.html \
	--filter ./scripts/pygmentize.py \
	--filter ./scripts/date-ru.py \
	$< -o $@

www/notes/index.html: src/notes/index.md templates/notes-index.html templates/header.html templates/footer.html
	pandoc --fail-if-warnings --wrap=none -f markdown -t html \
	--template templates/notes-index.html \
	--include-before-body templates/header.html \
	--include-after-body templates/footer.html \
	--metadata base-uri="$(BASE_URI)" \
	$< -o $@

www/notes/feed.xml: src/notes/index.md templates/notes-feed.xml
	sed '/title:/ s/`//g ; s/<//g ; s/>//g' $< > $<.tmp
	pandoc --fail-if-warnings --wrap=none -f markdown -t html \
	--template templates/notes-feed.xml \
	--metadata base-uri="$(BASE_URI)" \
	$<.tmp -o $@
	rm $<.tmp

build_font = pyftsubset $< \
	--unicodes=$(1) \
	--layout-features='' \
	--flavor='woff2' \
	--no-recalc-timestamp \
	--output-file=$@

www/res/JetBrainsMono-Basic-Latin-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+0000-007F')

www/res/JetBrainsMono-Latin-1-Supplement-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+0080-00FF')

www/res/JetBrainsMono-Combining-Diacritical-Marks-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+0300-036F')

www/res/JetBrainsMono-Cyrillic-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+0400-04FF')

www/res/JetBrainsMono-General-Punctuation-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+2000-206F')

www/res/JetBrainsMono-Mathematical-Operators-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+2200-22FF')

www/res/JetBrainsMono-Box-Drawing-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+2500-257F')

www/res/JetBrainsMono-Geometric-Shapes-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+25A0-25FF')

www/res/JetBrainsMono-Block-Elements-%.woff2: src/res/JetBrainsMono-%.woff2
	$(call build_font,'U+2580-259F')
