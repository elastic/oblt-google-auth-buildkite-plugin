# Release Process

This document outlines how to release a new version of this plugin.

## Versioning

This project uses [Semantic Versioning](https://semver.org/). The version is automatically determined by [release-drafter](https://github.com/release-drafter/release-drafter) based on PR labels:

- `changelog:breaking` → Major version bump (e.g., 1.0.0 → 2.0.0)
- `changelog:feature` → Minor version bump (e.g., 1.0.0 → 1.1.0)
- Other labels → Patch version bump (e.g., 1.0.0 → 1.0.1)

See [release-drafter.yml](../.github/release-drafter.yml) for configuration details.

## How to Release

### 1. Merge PRs with changelog labels

Every PR must have exactly one `changelog:*` label. When merged to `main`, release-drafter automatically updates the draft release.

### 2. Publish the draft release

1. Go to [Releases](../../releases)
2. Wait for the [release-drafter workflow](../.github/workflows/release-drafter.yml) to finish
3. Review the draft release notes
4. Click **Publish release**

### 3. Review the version bump PR

After publishing, the [bump-version workflow](../.github/workflows/bump-version.yml) automatically creates a PR to update the plugin version in README.md. Review and merge it to keep the documentation up to date.

## Changelog Labels

Every PR needs exactly one of these labels:

| Label | Description | Version Impact |
|-------|-------------|----------------|
| `changelog:breaking` | Breaking changes | Major |
| `changelog:feature` | New features | Minor |
| `changelog:enhancement` | Improvements to existing features | Patch |
| `changelog:fix` | Bug fixes | Patch |
| `changelog:docs` | Documentation updates | Patch |
| `changelog:chore` | Maintenance tasks | Patch |
| `changelog:ci` | CI/CD changes | Patch |
| `changelog:dependencies` | Dependency updates | Patch |
| `changelog:skip` | Excluded from changelog | None |
