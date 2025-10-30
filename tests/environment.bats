#!/usr/bin/env bats

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"
  
  # Create a test temporary directory  
  export TEST_TMPDIR="/tmp/bats-test-$$"
  mkdir -p "$TEST_TMPDIR"
  
  # Create the mock buildkite temp directory that mktemp will return
  export MOCK_BUILDKITE_TMPDIR="/tmp/mock-buildkite-test-$$"
  mkdir -p "$MOCK_BUILDKITE_TMPDIR"
  
  # Uncomment the following line to debug stub failures
  # export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
  # export MKTEMP_STUB_DEBUG=/dev/tty
}

teardown() {
  rm -rf "$TEST_TMPDIR" 2>/dev/null || true
  rm -rf "$MOCK_BUILDKITE_TMPDIR" 2>/dev/null || true
  
  # Clean up any remaining stubs
  unstub mktemp 2>/dev/null || true
  unstub buildkite-agent 2>/dev/null || true
  unstub cygpath 2>/dev/null || true
  
  # Ensure libs directory is restored if a test failed
  if [[ -d "$PWD/libs.backup" ]]; then
    rm -f "$PWD/libs" 2>/dev/null || true
    mv "$PWD/libs.backup" "$PWD/libs"
  fi
}

@test "Creates temporary directory and required files" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="123456789"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="test-project"
  
  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'"
  
  run bash -c "source $PWD/hooks/environment && echo \$BUILDKITE_OIDC_TMPDIR"

  assert_success
  assert_output --partial "$MOCK_BUILDKITE_TMPDIR"

  unstub mktemp
  unstub buildkite-agent
}

@test "Sets all required environment variables" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="test-project"
  
  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'"

  run bash -c "source $PWD/hooks/environment && echo \$GOOGLE_APPLICATION_CREDENTIALS:\$CLOUDSDK_CORE_PROJECT:\$GOOGLE_CLOUD_PROJECT"

  assert_success
  assert_output --partial "credentials.json:test-project:test-project"

  unstub mktemp
  unstub buildkite-agent
}

@test "Generates correct workload identity provider ID from repo hash" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  
  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'"
  
  run bash -c "source $PWD/hooks/environment >/dev/null 2>&1 && echo \$WORKLOAD_IDENTITY_PROVIDER_ID && echo \${#WORKLOAD_IDENTITY_PROVIDER_ID}"

  assert_success
  assert_line --index 0 --partial "repo-"
  assert_line --index 1 "32" # "repo-" (5) + 27 chars = 32

  unstub mktemp
  unstub buildkite-agent
}

@test "Uses default values when plugin configuration not provided" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  
  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'"
  
  run bash -c "source $PWD/hooks/environment >/dev/null 2>&1 && echo \$PROJECT_NUMBER:\$PROJECT_ID"

  assert_success
  assert_output "8560181848:elastic-observability"

  unstub mktemp
  unstub buildkite-agent
}

@test "Uses custom configuration when provided" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="987654321"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="custom-project"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_LIFETIME="3600"
  
  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'"

  run bash -c "source $PWD/hooks/environment >/dev/null 2>&1 && echo \$PROJECT_NUMBER:\$PROJECT_ID"

  assert_success
  assert_output "987654321:custom-project"

  unstub mktemp
  unstub buildkite-agent
}

@test "Creates valid credentials.json file with correct structure" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="123456789"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="test-project"

  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'"

  run bash -c "source $PWD/hooks/environment && cat \$GOOGLE_APPLICATION_CREDENTIALS"

  assert_success
  assert_output --partial '"type": "external_account"'
  assert_output --partial '"audience": "//iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/buildkite/providers/repo-'
  assert_output --partial '"subject_token_type": "urn:ietf:params:oauth:token-type:jwt"'
  assert_output --partial '"token_url": "https://sts.googleapis.com/v1/token"'
  assert_output --partial '"credential_source"'
  assert_output --partial '"file"'

  unstub mktemp
  unstub buildkite-agent
}

@test "Handles Windows paths correctly when OSTYPE is msys" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export OSTYPE="msys"

  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'"
  stub cygpath "-w \* : echo 'C:\\temp\\mock-path\\token.json'"

  run bash -c "source $PWD/hooks/environment && cat \$GOOGLE_APPLICATION_CREDENTIALS"

  assert_success
  assert_output --partial "C:\\\\temp\\\\mock-path"

  unstub mktemp
  unstub buildkite-agent
  unstub cygpath
}

@test "Handles Windows paths correctly when OSTYPE is cygwin" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export OSTYPE="cygwin"

  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'"
  stub cygpath "-w \* : echo 'C:\\buildkite\\temp\\token.json'"

  run bash -c "source $PWD/hooks/environment && cat \$GOOGLE_APPLICATION_CREDENTIALS"

  assert_success
  assert_output --partial "C:\\\\buildkite\\\\temp"

  unstub mktemp
  unstub buildkite-agent
  unstub cygpath
}

@test "Service account mode creates additional variables and calls gcloud functions" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_USE_SERVICE_ACCOUNT="true"
  export BUILDKITE_JOB_ID="test-job-123"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="test-project"

  # Create mock gcloud library in test temp directory
  mkdir -p "$TEST_TMPDIR/libs"
  cat > "$TEST_TMPDIR/libs/gcloud" << 'EOF'
create_service_account() { 
  echo "SA created: $1" >&2
  return 0
}
set_iam_policy() { 
  echo "IAM policy set: $1" >&2
  return 0
}
create_service_account_key() { 
  echo '{"type":"service_account","project_id":"test"}' > "$4"
  return 0
}
EOF

  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent \
    "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'" \
    "redactor add : echo 'redactor called with: redactor add' >&2"
  
  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"

  run bash -c "source $PWD/hooks/environment 2>&1"

  assert_success
  assert_output --partial "SA created: ephemeral-test-repo-bk-plugin-sa-test-job-123"
  assert_output --partial "IAM policy set: ephemeral-test-repo-bk-plugin-sa-test-job-123@test-project.iam.gserviceaccount.com"

  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"

  unstub mktemp
  unstub buildkite-agent
}

@test "Service account mode generates correct SA name from repo basename" {
  export BUILDKITE_REPO="https://github.com/elastic/test-repo-name.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_USE_SERVICE_ACCOUNT="true"
  export BUILDKITE_JOB_ID="job-456"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="my-project"

  # Create mock gcloud library in test temp directory
  mkdir -p "$TEST_TMPDIR/libs"
  cat > "$TEST_TMPDIR/libs/gcloud" << 'EOF'
create_service_account() { echo "SA name: $1" >&2; }
set_iam_policy() { return 0; }
create_service_account_key() { echo '{}' > "$4"; }
EOF

  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent \
    "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'" \
    "redactor add : echo 'redactor called' >&2"

  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"

  run bash -c "source $PWD/hooks/environment 2>&1"

  assert_success
  assert_output --partial "SA name: ephemeral-test-repo-name-bk-plugin-sa-job-456"
  
  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"

  unstub mktemp
  unstub buildkite-agent
}

@test "Token redaction is called when using service account" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_USE_SERVICE_ACCOUNT="true"
  export BUILDKITE_JOB_ID="test-job-123"

  # Create mock gcloud library in test temp directory
  mkdir -p "$TEST_TMPDIR/libs"
  cat > "$TEST_TMPDIR/libs/gcloud" << 'EOF'
create_service_account() { return 0; }
set_iam_policy() { return 0; }
create_service_account_key() { echo '{}' > "$4"; }
EOF

  # Stub commands used by the environment script
  stub mktemp "-d : echo '$MOCK_BUILDKITE_TMPDIR'"
  stub buildkite-agent \
    "oidc request-token --audience \* --lifetime \* : echo 'mock-oidc-token'" \
    "redactor add : echo 'redactor called' >&2"

  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"

  run bash -c "source $PWD/hooks/environment 2>&1"

  assert_success
  assert_output --partial "redactor called"

  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"

  unstub mktemp
  unstub buildkite-agent
}