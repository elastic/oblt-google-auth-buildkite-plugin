# Authenticate to Google Cloud from Buildkite

[![usages](https://img.shields.io/badge/usages-white?logo=buildkite&logoColor=blue)](https://github.com/search?q=elastic%2Foblt-google-auth+%28path%3A.buildkite%29&type=code)

This is an opinionated plugin to authenticate to any Google Cloud project from Buildkite using [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation).
The Workload Identity Provider uses a hash for the GitHub repository with the format `owner/repo`, the
hash has a length of 28 characters.

The Workload Identity Pool defaults to `buildkite`. Teams that own a separate pool can select it with
`workload-identity-pool-suffix`, which is appended to the hardcoded `buildkite` prefix — a suffix of
`sec-eng` resolves to the pool `buildkite-sec-eng`. The prefix is not configurable so the plugin can
only ever target pools dedicated to Buildkite.

## Properties

| Name                  | Description                                                                                           | Required | Default                 |
|-----------------------|-------------------------------------------------------------------------------------------------------|----------|-------------------------|
| `lifetime`            | The time (in seconds) the OIDC token will be valid for before expiry. Must be a non-negative integer. | `false`  | `1800`                  |
| `project-id`          | The GCP project id.                                                                                   | `false`  | `elastic-observability` |
| `project-number`      | The GCP project number.                                                                               | `false`  | `8560181848`            |
| `workload-identity-pool-suffix` | Suffix appended to the `buildkite` pool id, e.g. `sec-eng` -> `buildkite-sec-eng`. 1-22 characters of `[a-z0-9-]`, starting and ending with a letter or digit. | `false`  | _none_ (pool `buildkite`) |

## Usage

```yml
steps:
  - command: |
      echo "Credentials are located at \$GOOGLE_APPLICATION_CREDENTIALS"
      gcloud container clusters list
    plugins:
      - elastic/oblt-google-auth#v1.3.2:
          lifetime: 1800 # seconds
          # project-id: "elastic-observability"
          # project-number: "8560181848"
```

### Using a dedicated Workload Identity Pool

`workload-identity-pool-suffix` only works if the target project already has a `buildkite-<suffix>`
pool provisioned for it — this plugin does not create one. Pool provisioning is opinionated and
managed through a dedicated Terraform module, so this option is only useful to teams that have
already set up such a pool through that module.

```yml
steps:
  - command: |
      echo "Credentials are located at \$GOOGLE_APPLICATION_CREDENTIALS"
      gcloud container clusters list
    plugins:
      - elastic/oblt-google-auth#v1.3.2:
          lifetime: 1800 # seconds
          project-id: "elastic-observability"
          project-number: "8560181848"
          workload-identity-pool-suffix: "sec-eng" # -> pool "buildkite-sec-eng"
```

## Requirements

This plugin needs the following requirements:

- bash
- buildkite-agent
