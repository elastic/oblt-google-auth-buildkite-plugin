#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

setup() {
  export BUILDKITE_REPO="https://github.com/elastic/test-repo.git"
}

teardown() {
  if [[ -n "${BUILDKITE_OIDC_TMPDIR:-}" ]]; then
    rm -rf "${BUILDKITE_OIDC_TMPDIR}"
    unset BUILDKITE_OIDC_TMPDIR
  fi
  unset GOOGLE_APPLICATION_CREDENTIALS CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE
  unset CLOUDSDK_CORE_PROJECT CLOUDSDK_PROJECT GCLOUD_PROJECT GCP_PROJECT GOOGLE_CLOUD_PROJECT
}

@test "requests OIDC token from Buildkite" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  run bash hooks/environment

  assert_success
  assert_output --partial "Requesting OIDC token from Buildkite"
  unstub buildkite-agent
}

@test "uses plugin-configured project number" {
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="123456789"

  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  run bash hooks/environment

  assert_success
  unstub buildkite-agent
}

@test "uses default lifetime of 1800" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime 1800 : echo fake-oidc-token"

  run bash hooks/environment

  assert_success
  unstub buildkite-agent
}

@test "uses plugin-configured lifetime" {
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_LIFETIME="7200"

  stub buildkite-agent \
    "oidc request-token --audience * --lifetime 7200 : echo fake-oidc-token"

  run bash hooks/environment

  assert_success
  unstub buildkite-agent
}

@test "prints the workload identity provider id" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  run bash hooks/environment

  assert_success
  assert_output --partial "Workload Identity Provider ID:"
  unstub buildkite-agent
}

@test "exports GOOGLE_APPLICATION_CREDENTIALS pointing to an existing file" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  source hooks/environment

  assert [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]
  assert [ -f "${GOOGLE_APPLICATION_CREDENTIALS}" ]
  unstub buildkite-agent
}

@test "credentials file is valid external_account JSON" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  source hooks/environment

  run jq -e '.type == "external_account"' "${GOOGLE_APPLICATION_CREDENTIALS}"
  assert_success
  unstub buildkite-agent
}

@test "credentials file audience contains default project number" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  source hooks/environment

  run jq -re '.audience' "${GOOGLE_APPLICATION_CREDENTIALS}"
  assert_success
  assert_output --partial "8560181848"
  unstub buildkite-agent
}

@test "credentials file audience contains custom project number" {
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_NUMBER="987654321"

  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  source hooks/environment

  run jq -re '.audience' "${GOOGLE_APPLICATION_CREDENTIALS}"
  assert_success
  assert_output --partial "987654321"
  unstub buildkite-agent
}

@test "exports all GCP project environment variables" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  source hooks/environment

  assert [ -n "${CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE:-}" ]
  assert [ -n "${CLOUDSDK_CORE_PROJECT:-}" ]
  assert [ -n "${CLOUDSDK_PROJECT:-}" ]
  assert [ -n "${GCLOUD_PROJECT:-}" ]
  assert [ -n "${GCP_PROJECT:-}" ]
  assert [ -n "${GOOGLE_CLOUD_PROJECT:-}" ]
  unstub buildkite-agent
}

@test "uses default project ID for GCP env vars" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  source hooks/environment

  assert_equal "${CLOUDSDK_CORE_PROJECT}" "elastic-observability"
  unstub buildkite-agent
}

@test "uses plugin-configured project ID for GCP env vars" {
  export BUILDKITE_PLUGIN_OBLT_GOOGLE_AUTH_PROJECT_ID="my-custom-project"

  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  source hooks/environment

  assert_equal "${CLOUDSDK_CORE_PROJECT}" "my-custom-project"
  unstub buildkite-agent
}

@test "exports BUILDKITE_OIDC_TMPDIR for cleanup" {
  stub buildkite-agent \
    "oidc request-token --audience * --lifetime * : echo fake-oidc-token"

  source hooks/environment

  assert [ -n "${BUILDKITE_OIDC_TMPDIR:-}" ]
  assert [ -d "${BUILDKITE_OIDC_TMPDIR}" ]
  unstub buildkite-agent
}
