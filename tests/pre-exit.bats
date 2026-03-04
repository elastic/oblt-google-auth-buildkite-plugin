#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

@test "removes the temp dir when BUILDKITE_OIDC_TMPDIR is set" {
  tmpdir=$(mktemp -d)
  export BUILDKITE_OIDC_TMPDIR="$tmpdir"

  run bash hooks/pre-exit

  assert_success
  assert [ ! -d "$tmpdir" ]
  assert_output --partial "Removed credentials from $tmpdir"
}

@test "does nothing when BUILDKITE_OIDC_TMPDIR is not set" {
  unset BUILDKITE_OIDC_TMPDIR

  run bash hooks/pre-exit

  assert_success
  refute_output
}
