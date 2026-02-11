.PHONY: test clean integration-test plugin-lint shellcheck

ROOT_DIR := $(PWD)
BATS_DIR := $(ROOT_DIR)/.tmp/bats-core
BATS_MOCK_DIR := $(ROOT_DIR)/.tmp/bats-mock
BATS_LIB_DIR := $(ROOT_DIR)/.tmp/bats-lib

BATS_SUPPORT_DIR := $(BATS_LIB_DIR)/bats-support
BATS_ASSERT_DIR := $(BATS_LIB_DIR)/bats-assert

BATS_BIN := $(BATS_DIR)/bin/bats

$(BATS_BIN):
	mkdir -p .tmp
	if [ ! -d "$(BATS_DIR)" ]; then git clone --depth 1 https://github.com/bats-core/bats-core.git "$(BATS_DIR)"; fi

$(BATS_MOCK_DIR)/stub.bash:
	mkdir -p .tmp
	if [ ! -d "$(BATS_MOCK_DIR)" ]; then git clone --depth 1 https://github.com/jasonkarns/bats-mock.git "$(BATS_MOCK_DIR)"; fi

$(BATS_SUPPORT_DIR)/load:
	mkdir -p "$(BATS_LIB_DIR)"
	if [ ! -d "$(BATS_SUPPORT_DIR)" ]; then git clone --depth 1 https://github.com/bats-core/bats-support.git "$(BATS_SUPPORT_DIR)"; fi

$(BATS_ASSERT_DIR)/load:
	mkdir -p "$(BATS_LIB_DIR)"
	if [ ! -d "$(BATS_ASSERT_DIR)" ]; then git clone --depth 1 https://github.com/bats-core/bats-assert.git "$(BATS_ASSERT_DIR)"; fi

test: $(BATS_BIN) $(BATS_MOCK_DIR)/stub.bash $(BATS_SUPPORT_DIR)/load $(BATS_ASSERT_DIR)/load
	BATS_PLUGIN_PATH="$(BATS_MOCK_DIR)" \
	BATS_LIB_PATH="$(BATS_LIB_DIR)" \
	"$(BATS_BIN)" tests/

INTEGRATION_LIBS_DIR := $(ROOT_DIR)/tests/bats-libs

$(INTEGRATION_LIBS_DIR):
	mkdir -p "$(INTEGRATION_LIBS_DIR)"
	git clone --depth 1 https://github.com/bats-core/bats-support.git "$(INTEGRATION_LIBS_DIR)/bats-support"
	git clone --depth 1 https://github.com/bats-core/bats-assert.git "$(INTEGRATION_LIBS_DIR)/bats-assert"
	git clone --depth 1 https://github.com/jasonkarns/bats-mock.git "$(INTEGRATION_LIBS_DIR)/bats-mock"

CONTAINER_RUNTIME := $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null)
COMPOSE := $(shell command -v docker 2>/dev/null && echo 'docker compose' || echo 'podman compose')

integration-test: $(INTEGRATION_LIBS_DIR)
	$(COMPOSE) run --rm tests

plugin-lint:
	$(CONTAINER_RUNTIME) run --rm -v "$(PWD)":/plugin:z docker.io/buildkite/plugin-linter --id elastic/oblt-google-auth

shellcheck:
	shellcheck hooks/*

clean:
	rm -rf .tmp tests/bats-libs
