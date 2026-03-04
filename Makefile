.PHONY: all
all: test plugin-lint shellcheck e2e-test

.PHONY: test
test:
	@docker compose run --rm test

.PHONY: plugin-lint
plugin-lint:
	@docker compose run --rm plugin-lint

.PHONY: shellcheck
shellcheck:
	@docker compose run --rm shellcheck

.PHONY: e2e-test
e2e-test:
	@docker compose run --rm e2e-test
