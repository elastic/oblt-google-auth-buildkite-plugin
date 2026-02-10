#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

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

@test "Shows warning when cleanup fails" {
  export BUILDKITE_OIDC_TMPDIR=$(mktemp -d)
  chmod 000 "$BUILDKITE_OIDC_TMPDIR"
  
  run "$PWD/hooks/pre-exit"
  
  # Pre-exit should still succeed to allow pipeline to continue
  assert_success
  assert_output --partial "Warning: Failed to remove credentials"
  
  # Cleanup
  chmod 755 "$BUILDKITE_OIDC_TMPDIR"
  rmdir "$BUILDKITE_OIDC_TMPDIR"
}
