.PHONY: all lint shellcheck clean

all: lint shellcheck

lint:
	-docker compose run lint

shellcheck:
	-docker compose run shellcheck

clean:
	-docker compose \
		rm  --remove-orphans --force --stop
