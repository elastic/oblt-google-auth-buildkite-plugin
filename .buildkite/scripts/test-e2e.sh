#!/usr/bin/env bash

set -euo pipefail

echo "--- :google-cloud-platform: Listing active auth accounts"

gcloud auth list

active_account=$(gcloud auth list --filter="status=ACTIVE" --format="value(account)")

if [ -z "${active_account}" ]; then
  echo "^^^ +++"
  echo "Error: No active credentialed account found. The plugin did not set up Google Cloud auth."
  exit 1
fi

echo ""
echo "E2E test passed! Active account: ${active_account}"
