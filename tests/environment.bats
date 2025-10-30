#!/usr/bin/env bats

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"
  
  # Create a test temporary directory
  export TEST_TMPDIR="/tmp/bats-test-$$"
  mkdir -p "$TEST_TMPDIR"
  
  # Mock buildkite-agent command
  export PATH="$TEST_TMPDIR:$PATH"
  cat > "$TEST_TMPDIR/buildkite-agent" << 'EOF'
#!/bin/bash
case "$1" in
  "oidc")
    if [[ "$2" == "request-token" ]]; then
      # Generate a mock token and output it to stdout
      # The actual command uses redirection: buildkite-agent oidc request-token ... > "$TOKEN_FILE"
      echo "mock-oidc-token-$(date +%s)"
    fi
    ;;
  "redactor")
    if [[ "$2" == "add" ]]; then
      echo "redactor called with: $*" >&2
    fi
    ;;
esac
EOF
  chmod +x "$TEST_TMPDIR/buildkite-agent"
  
  # Mock mktemp to return predictable directory
  cat > "$TEST_TMPDIR/mktemp" << 'EOF'
#!/bin/bash
if [[ "$1" == "-d" ]]; then
  mkdir -p "/tmp/mock-buildkite-test-$$"
  echo "/tmp/mock-buildkite-test-$$"
fi
EOF
  chmod +x "$TEST_TMPDIR/mktemp"
}

teardown() {
  rm -rf "$TEST_TMPDIR" 2>/dev/null || true
  rm -rf /tmp/mock-buildkite-test-* 2>/dev/null || true
  
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
  
  run bash -c "source $PWD/hooks/environment && echo \$BUILDKITE_OIDC_TMPDIR"
  
  assert_success
  assert_output --partial "/tmp/mock-buildkite-test"
}

@test "Sets all required environment variables" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="test-project"
  
  run bash -c "source $PWD/hooks/environment && echo \$GOOGLE_APPLICATION_CREDENTIALS:\$CLOUDSDK_CORE_PROJECT:\$GOOGLE_CLOUD_PROJECT"
  
  assert_success
  assert_output --partial "credentials.json:test-project:test-project"
}

@test "Generates correct workload identity provider ID from repo hash" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  
  run bash -c "source $PWD/hooks/environment >/dev/null 2>&1 && echo \$WORKLOAD_IDENTITY_PROVIDER_ID"
  
  assert_success
  assert_output --partial "repo-"
  # Should be 27 characters after "repo-"
  run bash -c "source $PWD/hooks/environment >/dev/null 2>&1 && echo \${#WORKLOAD_IDENTITY_PROVIDER_ID}"
  assert_output "32" # "repo-" (5) + 27 chars = 32
}

@test "Uses default values when plugin configuration not provided" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  
  run bash -c "source $PWD/hooks/environment >/dev/null 2>&1 && echo \$PROJECT_NUMBER:\$PROJECT_ID"
  
  assert_success
  assert_output "8560181848:elastic-observability"
}

@test "Uses custom configuration when provided" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="987654321"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="custom-project"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_LIFETIME="3600"
  
  run bash -c "source $PWD/hooks/environment >/dev/null 2>&1 && echo \$PROJECT_NUMBER:\$PROJECT_ID"
  
  assert_success
  assert_output "987654321:custom-project"
}

@test "Creates valid credentials.json file with correct structure" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="123456789"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="test-project"
  
  run bash -c "source $PWD/hooks/environment && cat \$GOOGLE_APPLICATION_CREDENTIALS"
  
  assert_success
  assert_output --partial '"type": "external_account"'
  assert_output --partial '"audience": "//iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/buildkite/providers/repo-'
  assert_output --partial '"subject_token_type": "urn:ietf:params:oauth:token-type:jwt"'
  assert_output --partial '"token_url": "https://sts.googleapis.com/v1/token"'
  assert_output --partial '"credential_source"'
  assert_output --partial '"file"'
}

@test "Handles Windows paths correctly when OSTYPE is msys" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export OSTYPE="msys"
  
  # Mock cygpath
  cat > "$TEST_TMPDIR/cygpath" << 'EOF'
#!/bin/bash
if [[ "$1" == "-w" ]]; then
  echo "C:\\temp\\mock-path\\$(basename "$2")"
fi
EOF
  chmod +x "$TEST_TMPDIR/cygpath"
  
  run bash -c "source $PWD/hooks/environment && cat \$GOOGLE_APPLICATION_CREDENTIALS"
  
  assert_success
  assert_output --partial "C:\\\\temp\\\\mock-path"
}

@test "Handles Windows paths correctly when OSTYPE is cygwin" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export OSTYPE="cygwin"
  
  # Mock cygpath
  cat > "$TEST_TMPDIR/cygpath" << 'EOF'
#!/bin/bash
if [[ "$1" == "-w" ]]; then
  echo "C:\\buildkite\\temp\\$(basename "$2")"
fi
EOF
  chmod +x "$TEST_TMPDIR/cygpath"
  
  run bash -c "source $PWD/hooks/environment && cat \$GOOGLE_APPLICATION_CREDENTIALS"
  
  assert_success
  assert_output --partial "C:\\\\buildkite\\\\temp"
}

@test "Service account mode creates additional variables and calls gcloud functions" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_USE_SERVICE_ACCOUNT="true"
  export BUILDKITE_JOB_ID="test-job-123"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="test-project"
  
  # Create mock gcloud library functions in test temp directory
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
  
  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"
  
  run bash -c "source $PWD/hooks/environment 2>&1"
  
  assert_success
  assert_output --partial "SA created: ephemeral-test-repo-bk-plugin-sa-test-job-123"
  assert_output --partial "IAM policy set: ephemeral-test-repo-bk-plugin-sa-test-job-123@test-project.iam.gserviceaccount.com"
  
  # Test that service account variables are set
  run bash -c "source $PWD/hooks/environment >/dev/null 2>&1 && echo \$GOOGLE_APPLICATION_SERVICE_ACCOUNT"
  assert_success
  assert_output "ephemeral-test-repo-bk-plugin-sa-test-job-123@test-project.iam.gserviceaccount.com"
  
  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"
}

@test "Service account mode generates correct SA name from repo basename" {
  export BUILDKITE_REPO="https://github.com/elastic/test-repo-name.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_USE_SERVICE_ACCOUNT="true"
  export BUILDKITE_JOB_ID="job-456"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="my-project"
  
  # Create mock gcloud library functions in test temp directory
  mkdir -p "$TEST_TMPDIR/libs"
  cat > "$TEST_TMPDIR/libs/gcloud" << 'EOF'
create_service_account() { echo "SA name: $1" >&2; }
set_iam_policy() { return 0; }
create_service_account_key() { echo '{}' > "$4"; }
EOF
  
  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"
  
  run bash -c "source $PWD/hooks/environment 2>&1"
  
  assert_success
  assert_output --partial "SA name: ephemeral-test-repo-name-bk-plugin-sa-job-456"
  
  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"
}

@test "Token redaction is called when using service account" {
  export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_USE_SERVICE_ACCOUNT="true"
  export BUILDKITE_JOB_ID="test-job-123"
  
  # Create mock gcloud library functions in test temp directory
  mkdir -p "$TEST_TMPDIR/libs"
  cat > "$TEST_TMPDIR/libs/gcloud" << 'EOF'
create_service_account() { return 0; }
set_iam_policy() { return 0; }
create_service_account_key() { echo '{}' > "$4"; }
EOF
  
  # Temporarily replace the real libs with our mock
  mv "$PWD/libs" "$PWD/libs.backup"
  ln -s "$TEST_TMPDIR/libs" "$PWD/libs"
  
  run bash -c "source $PWD/hooks/environment 2>&1"
  
  assert_success
  assert_output --partial "redactor called"
  
  # Restore original libs
  rm "$PWD/libs"
  mv "$PWD/libs.backup" "$PWD/libs"
}