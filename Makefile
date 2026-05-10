all: serve

.PHONY: serve

serve:
	python3 -m http.server -d www --bind ::
