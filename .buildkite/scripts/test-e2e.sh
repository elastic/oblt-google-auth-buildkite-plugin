#!/usr/bin/env bash

set -euo pipefail

echo "--- :gcp: Verifying Google Cloud authentication"

# Verify that the plugin set the expected environment variables
for var in GOOGLE_APPLICATION_CREDENTIALS CLOUDSDK_CORE_PROJECT GOOGLE_CLOUD_PROJECT; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: ${var} is not set" >&2
    exit 1
  fi
  echo "${var} is set"
done

# Verify credentials file exists
if [[ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
  echo "Error: Credentials file does not exist at $GOOGLE_APPLICATION_CREDENTIALS" >&2
  exit 1
fi
echo "Credentials file exists"

echo "--- :gcloud: Testing gcloud authentication"

gcloud auth list --project="${GOOGLE_PROJECT}"

echo "--- :white_check_mark: E2E tests passed"
