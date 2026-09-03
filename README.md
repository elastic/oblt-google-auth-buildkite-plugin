# Authenticate to Google Cloud from Buildkite

[![usages](https://img.shields.io/badge/usages-white?logo=buildkite&logoColor=blue)](https://github.com/search?q=elastic%2Foblt-google-auth+%28path%3A.buildkite%29&type=code)

This is an opinionated plugin to authenticate to any Google Cloud project from Buildkite using [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation).
The Workload Identity Provider uses a hash for the GitHub repository with the format `owner/repo`, the
hash has a length of 28 characters.

## Properties

| Name                  | Description                                                                                           | Required | Default                 |
|-----------------------|-------------------------------------------------------------------------------------------------------|----------|-------------------------|
| `lifetime`            | The time (in seconds) the OIDC token will be valid for before expiry. Must be a non-negative integer. | `false`  | `1800`                  |
| `project-id`          | The GCP project id.                                                                                   | `false`  | `elastic-observability` |
| `project-number`      | The GCP project number.                                                                               | `false`  | `8560181848`            |

## Usage

```yml
steps:
  - command: |
      echo "Credentials are located at \$GOOGLE_APPLICATION_CREDENTIALS"
      gcloud container clusters list
    plugins:
      - elastic/oblt-google-auth#v1.3.0:
          lifetime: 1800 # seconds
          # project-id: "elastic-observability"
          # project-number: "8560181848"
```

## Requirements

This plugin needs the following requirements:

- bash
- buildkite-agent (with OIDC support enabled)

## Troubleshooting

If authentication fails or the plugin does not behave as expected, check the following:

- **OIDC support**: Ensure your `buildkite-agent` is configured with OIDC support enabled.
- **Environment variables**: Verify that any required environment variables (for example, `GOOGLE_APPLICATION_CREDENTIALS`) are set and exported in the step.
- **Project configuration**: Confirm that `project-id` and `project-number` (if overridden) match an existing Google Cloud project and Workload Identity Provider configuration.
- **Permissions**: Make sure the Workload Identity Pool and Provider allow the Buildkite identity and that the corresponding service account has the necessary IAM roles (e.g., to list clusters with `gcloud container clusters list`).
- **Token lifetime**: If you override `lifetime`, ensure it is a non-negative integer and within allowed limits for your Google Cloud setup.

## Security

This plugin follows security best practices:

- No hardcoded secrets - uses environment variables
- Input validation for all configuration parameters
- Secrets redacted from logs using `buildkite-agent redactor add`
- Temporary credentials cleaned up in pre-exit hook
- Fail-fast error handling with `set -euo pipefail`

## Testing

This plugin includes comprehensive test coverage using BATS (Bash Automated Testing System). 

### Running Tests

To run the tests locally, use the following Makefile targets:
 - `test`: runs BATS tests
 - `integration-test`: will test the functionality itself requesting a token from GCP
 - `plugin-lint`: will check for linting issues
 - `shellcheck`: will check BASH scripts
```

## Contributing

When contributing to this plugin, please ensure:

1. All changes include appropriate tests
2. Error messages are clear and actionable
3. Secrets are redacted from logs using `buildkite-agent redactor add`
4. Input validation is performed for user-provided configuration
5. Documentation is updated to reflect changes
