#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/stub.bash"
load "$BATS_LIB_PATH/bats-support/load"
load "$BATS_LIB_PATH/bats-assert/load"

# Uncomment to enable stub debugging
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

setup() {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_LIFETIME="1800"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="8560181848"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="elastic-observability"
}

teardown() {
  if [[ -n "${BUILDKITE_OIDC_TMPDIR:-}" && -d "$BUILDKITE_OIDC_TMPDIR" ]]; then
    rm -rf "$BUILDKITE_OIDC_TMPDIR"
  fi
}

@test "Validates project-number must be numeric" {
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="not-numeric"
  
  run "$PWD/hooks/environment"
  
  assert_failure
  assert_output --partial "project-number must be numeric"
}

@test "Validates project-id cannot be empty" {
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID=""

  stub buildkite-agent \
    "oidc request-token * : echo 'mock-token'" \
    "redactor add * : true" \
    "redactor add * : true"

  run "$PWD/hooks/environment"

  assert_success
  refute_output --partial "project-id cannot be empty"
  unstub buildkite-agent
}

@test "Creates temporary directory successfully" {
  stub buildkite-agent \
    "oidc request-token * : echo 'mock-token'" \
    "redactor add * : true" \
    "redactor add * : true"

  run bash -c "source $PWD/hooks/environment && printf '%s\n' \"\$BUILDKITE_OIDC_TMPDIR\""

  assert_success
  assert [ -n "$output" ]
  unstub buildkite-agent
}

@test "Sets required environment variables" {
  stub buildkite-agent \
    "oidc request-token * : echo 'mock-token'" \
    "redactor add * : true" \
    "redactor add * : true"
  
  run bash -c "source $PWD/hooks/environment && env"
  
  assert_success
  assert_output --partial "GOOGLE_APPLICATION_CREDENTIALS="
  assert_output --partial "CLOUDSDK_CORE_PROJECT=elastic-observability"
  assert_output --partial "GOOGLE_CLOUD_PROJECT=elastic-observability"
  unstub buildkite-agent
}

@test "Fails when OIDC token request fails" {
  stub buildkite-agent \
    "oidc request-token * : exit 1"
  
  run "$PWD/hooks/environment"
  
  assert_failure
  assert_output --partial "Failed to request OIDC token from Buildkite"
  unstub buildkite-agent
}

@test "Uses default values when configuration not provided" {
  unset BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_LIFETIME
  unset BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER
  unset BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID
  
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime 1800 : echo 'mock-token'" \
    "redactor add * : true" \
    "redactor add * : true"
  
  run "$PWD/hooks/environment"
  
  assert_success
  unstub buildkite-agent
}

@test "Calculates Workload Identity Provider ID correctly" {
  stub buildkite-agent \
    "oidc request-token * : echo 'mock-token'" \
    "redactor add * : true" \
    "redactor add * : true"
  
  run "$PWD/hooks/environment"
  
  assert_success
  assert_output --partial "Workload Identity Provider ID: repo-"
  unstub buildkite-agent
}
