#!/usr/bin/env bats

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"
  
  # Create test temporary directory
  export TEST_TMPDIR="/tmp/bats-test-$$"
  mkdir -p "$TEST_TMPDIR"
  
  # Set up test environment
  export BUILDKITE_OIDC_TMPDIR="$TEST_TMPDIR/buildkite-oidc"
  export GOOGLE_CLOUD_PROJECT="test-project"
  export BUILDKITE_BUILD_URL="https://buildkite.com/test/build/123"
  
  mkdir -p "$BUILDKITE_OIDC_TMPDIR"
  
  # Create mock token file
  echo "mock-token" > "$BUILDKITE_OIDC_TMPDIR/token.json"
  
  # Mock commands
  export PATH="$TEST_TMPDIR:$PATH"
  
  # Mock curl
  cat > "$TEST_TMPDIR/curl" << 'EOF'
#!/bin/bash
case "$*" in
  *"DELETE"*"serviceAccounts"*)
    if [[ "$MOCK_CURL_FAIL" == "true" ]]; then
      exit 1
    else
      echo '{"name":"projects/test-project/serviceAccounts/test-sa@test-project.iam.gserviceaccount.com"}'
    fi
    ;;
esac
EOF
  chmod +x "$TEST_TMPDIR/curl"
  
  # Mock jq
  cat > "$TEST_TMPDIR/jq" << 'EOF'
#!/bin/bash
if [[ "$2" == ".credentials_source.file" ]]; then
  echo "/tmp/token.json"
elif [[ "$2" == ".credential_source.file" ]]; then
  echo "/tmp/token.json"
fi
EOF
  chmod +x "$TEST_TMPDIR/jq"
  
  # Mock buildkite-agent
  cat > "$TEST_TMPDIR/buildkite-agent" << 'EOF'
#!/bin/bash
case "$1" in
  "annotate")
    echo "annotate called: $2" >&2
    ;;
  "pipeline")
    echo "pipeline upload called" >&2
    ;;
esac
EOF
  chmod +x "$TEST_TMPDIR/buildkite-agent"
  
  # Mock cat for token file
  cat > "$TEST_TMPDIR/cat" << 'EOF'
#!/bin/bash
if [[ "$1" == "/tmp/token.json" ]]; then
  echo "mock-token-content"
else
  /bin/cat "$@"
fi
EOF
  chmod +x "$TEST_TMPDIR/cat"
}

teardown() {
  rm -rf "$TEST_TMPDIR" 2>/dev/null || true
  unset MOCK_CURL_FAIL
  
  # Ensure libs directory is restored if a test failed
  if [[ -d "$PWD/libs.backup" ]]; then
    rm -f "$PWD/libs" 2>/dev/null || true
    mv "$PWD/libs.backup" "$PWD/libs"
  fi
}

@test "Cleans up temporary directory when BUILDKITE_OIDC_TMPDIR is set" {
  run bash "$PWD/hooks/pre-exit"
  
  assert_success
  assert [ ! -d "$BUILDKITE_OIDC_TMPDIR" ]
}

@test "Handles missing BUILDKITE_OIDC_TMPDIR gracefully" {
  unset BUILDKITE_OIDC_TMPDIR
  
  run bash "$PWD/hooks/pre-exit"
  
  assert_success
}

@test "Deletes service account when GOOGLE_APPLICATION_SERVICE_ACCOUNT is set" {
  export GOOGLE_APPLICATION_SERVICE_ACCOUNT="test-sa@test-project.iam.gserviceaccount.com"
  export GOOGLE_APPLICATION_CREDENTIALS='{"credential_source":{"file":"/tmp/token.json"}}'
  
  run bash "$PWD/hooks/pre-exit" 2>&1
  
  assert_success
  assert_output --partial "Cleaning up Service Account test-sa@test-project.iam.gserviceaccount.com"
  assert_output --partial "Service Account test-sa@test-project.iam.gserviceaccount.com cleaned up"
}

@test "Skips service account deletion when GOOGLE_APPLICATION_SERVICE_ACCOUNT is not set" {
  unset GOOGLE_APPLICATION_SERVICE_ACCOUNT
  
  run bash "$PWD/hooks/pre-exit" 2>&1
  
  assert_success
  refute_output --partial "Cleaning up Service Account"
}

@test "Handles service account deletion failure gracefully" {
  export GOOGLE_APPLICATION_SERVICE_ACCOUNT="test-sa@test-project.iam.gserviceaccount.com"
  export GOOGLE_APPLICATION_CREDENTIALS='{"credential_source":{"file":"/tmp/token.json"}}'
  export MOCK_CURL_FAIL="true"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_SLACK_CHANNEL="#test-channel"
  
  # Create mock slack library in test temp directory
  mkdir -p "$TEST_TMPDIR/libs"
  cat > "$TEST_TMPDIR/libs/slack" << 'EOF'
send_message() {
  echo "slack message sent to: $1" >&2
  echo "message: $2" >&2
}
EOF
  
  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"
  
  run bash "$PWD/hooks/pre-exit" 2>&1
  
  assert_success
  assert_output --partial "Failed to delete Service Account"
  assert_output --partial "annotate called"
  assert_output --partial "slack message sent to: #test-channel"
  
  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"
}

@test "Uses default slack channel when not configured" {
  export GOOGLE_APPLICATION_SERVICE_ACCOUNT="test-sa@test-project.iam.gserviceaccount.com"
  export GOOGLE_APPLICATION_CREDENTIALS='{"credential_source":{"file":"/tmp/token.json"}}'
  export MOCK_CURL_FAIL="true"
  
  # Create mock slack library in test temp directory
  mkdir -p "$TEST_TMPDIR/libs"
  cat > "$TEST_TMPDIR/libs/slack" << 'EOF'
send_message() {
  echo "slack channel: $1" >&2
}
EOF
  
  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"
  
  run bash "$PWD/hooks/pre-exit" 2>&1
  
  assert_success
  assert_output --partial "slack channel: #observablt-bots"
  
  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"
}

@test "Creates buildkite annotation on service account deletion failure" {
  export GOOGLE_APPLICATION_SERVICE_ACCOUNT="test-sa@test-project.iam.gserviceaccount.com"
  export GOOGLE_APPLICATION_CREDENTIALS='{"credential_source":{"file":"/tmp/token.json"}}'
  export MOCK_CURL_FAIL="true"
  
  # Create mock slack library in test temp directory
  mkdir -p "$TEST_TMPDIR/libs"
  cat > "$TEST_TMPDIR/libs/slack" << 'EOF'
send_message() { return 0; }
EOF
  
  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"
  
  run bash "$PWD/hooks/pre-exit" 2>&1
  
  assert_success
  assert_output --partial "annotate called"
  
  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"
}

@test "Handles credentials file with different JSON structure" {
  export GOOGLE_APPLICATION_SERVICE_ACCOUNT="test-sa@test-project.iam.gserviceaccount.com"
  export GOOGLE_APPLICATION_CREDENTIALS='{"credentials_source":{"file":"/tmp/token.json"}}'
  
  run bash "$PWD/hooks/pre-exit" 2>&1
  
  assert_success
  assert_output --partial "Service Account test-sa@test-project.iam.gserviceaccount.com cleaned up"
}

@test "Outputs cleanup completion message" {
  run bash "$PWD/hooks/pre-exit"
  
  assert_success
  assert_output --partial "Removed credentials from"
}

@test "Script handles missing dependencies gracefully" {
  # Remove jq from PATH to test error handling
  export PATH="/usr/bin:/bin"
  export GOOGLE_APPLICATION_SERVICE_ACCOUNT="test-sa@test-project.iam.gserviceaccount.com"
  export GOOGLE_APPLICATION_CREDENTIALS='{"credential_source":{"file":"/tmp/token.json"}}'
  
  run bash "$PWD/hooks/pre-exit" 2>&1
  
  # Script should not fail completely due to set +eu at the beginning
  assert_success
}