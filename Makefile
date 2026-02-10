.PHONY: test clean

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

clean:
	rm -rf .tmp
