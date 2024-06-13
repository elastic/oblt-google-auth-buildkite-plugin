# Authenticate to Google Cloud from Buildkite

This is an opinionated plugin to authenticate to the elastic-observability Google Cloud project from Buildkite using [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation).

## Configuration

| Name       | Description                                                                                           | Required | Default |
|------------|-------------------------------------------------------------------------------------------------------|----------|---------|
| `lifetime` | The time (in seconds) the OIDC token will be valid for before expiry. Must be a non-negative integer. | `false`  | `1800`  |

## Usage

```yml
steps:
  - command: |
      echo "Credentials are located at \$GOOGLE_APPLICATION_CREDENTIALS"
      gcloud container clusters list
    plugins:
      - elastic/oblt-google-auth#v1.0.0:
          lifetime: 1800 # seconds
```
