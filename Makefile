.PHONY: all lint tests shellcheck clean

all: lint shellcheck tests

tests:
	-docker compose \
	  run --rm \
	  	tests

lint:
	-docker compose run lint

shellcheck:
	-docker compose run shellcheck

clean:
	-docker compose \
		rm  --remove-orphans --force --stop
