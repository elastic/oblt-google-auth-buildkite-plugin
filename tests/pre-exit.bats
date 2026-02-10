#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/stub.bash"
load "$BATS_LIB_PATH/bats-support/load"
load "$BATS_LIB_PATH/bats-assert/load"

@test "Cleans up temporary directory on success" {
  export BUILDKITE_OIDC_TMPDIR=$(mktemp -d)
  touch "$BUILDKITE_OIDC_TMPDIR/test-file"
  
  run "$PWD/hooks/pre-exit"
  
  assert_success
  assert_output --partial "Removed credentials from"
  assert [ ! -d "$BUILDKITE_OIDC_TMPDIR" ]
}

@test "Handles missing BUILDKITE_OIDC_TMPDIR gracefully" {
  unset BUILDKITE_OIDC_TMPDIR
  
  run "$PWD/hooks/pre-exit"
  
  assert_success
  refute_output --partial "Removed credentials"
}

@test "Continues execution when directory removal fails" {
  export BUILDKITE_OIDC_TMPDIR="/nonexistent/directory"
  
  run "$PWD/hooks/pre-exit"
  
  # Should not fail even if directory doesn't exist
  assert_success
}
