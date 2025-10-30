# Contributing to oblt-google-auth Buildkite Plugin

Thank you for your interest in contributing to the oblt-google-auth Buildkite plugin! This document provides guidelines and information for contributors.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Plugin Architecture](#plugin-architecture)
- [Testing](#testing)
- [Code Style and Standards](#code-style-and-standards)
- [Making Changes](#making-changes)
- [Submitting Pull Requests](#submitting-pull-requests)
- [Release Process](#release-process)
- [Getting Help](#getting-help)

## Getting Started

This plugin enables Buildkite pipelines to authenticate with Google Cloud Platform (GCP) using [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation). It provides two authentication modes:
- **OIDC Token Mode**: Uses Buildkite's OIDC token with external account credentials (default)
- **Service Account Mode**: Creates temporary service accounts for enhanced security

### Prerequisites

Before contributing, ensure you have:
- Docker and Docker Compose installed
- Basic understanding of Buildkite plugins
- Familiarity with Google Cloud IAM and Workload Identity Federation
- Knowledge of Bash scripting

## Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/oblt-google-auth-buildkite-plugin.git
   cd oblt-google-auth-buildkite-plugin
   ```

2. **Install Development Dependencies**
   The project uses Docker for all development tasks, so you only need Docker installed locally.

3. **Verify Setup**
   ```bash
   make lint shellcheck
   ```

## Plugin Architecture

### File Structure

```
├── hooks/
│   ├── environment     # Main authentication logic
│   └── pre-exit       # Cleanup and service account management
├── libs/
│   ├── gcloud         # Google Cloud operations
│   └── slack          # Slack notification functions
├── docker-compose.yml # Development and testing containers
├── plugin.yml         # Plugin metadata and configuration schema
└── Makefile          # Development commands
```

### Hook Lifecycle

1. **Environment Hook** (`hooks/environment`)
   - Executes before the build command
   - Sets up authentication credentials
   - Configures environment variables for GCP access

2. **Pre-exit Hook** (`hooks/pre-exit`)
   - Executes after the build command (success or failure)
   - Cleans up temporary files and credentials
   - Handles service account deletion and notifications

### Authentication Modes

#### OIDC Token Mode (Default)
- Uses `buildkite-agent oidc request-token` to get OIDC token
- Creates external account credentials file
- Suitable for most use cases

#### Service Account Mode
- Creates temporary service accounts with specific permissions
- Provides enhanced security and audit capabilities
- Automatically cleaned up after job completion
- Sends Slack notifications on cleanup failures

## Testing

### Test Framework

The project uses [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) with additional libraries:
- `bats-assert` for assertions
- `bats-mock` for command stubbing
- `bats-support` for helper functions

### Running Tests

```bash
# Run all tests
make tests

# Run specific test files
docker compose run --rm tests bats /plugin/tests/environment.bats
docker compose run --rm tests bats /plugin/tests/pre-exit.bats

# Run individual tests
docker compose run --rm tests bats /plugin/tests/environment.bats -f "test name"
```

### Test Structure

Tests are organized into two main files:
- `tests/environment.bats` - Tests for the environment hook
- `tests/pre-exit.bats` - Tests for the pre-exit hook

Each test file includes:
- Setup and teardown functions for test isolation
- Mock library functions for external dependencies
- Stub commands for system calls (mktemp, buildkite-agent, curl, etc.)

### Writing Tests

When adding new functionality:

1. **Add test cases** that cover both success and failure scenarios
2. **Use proper mocking** for external dependencies:
   ```bash
   # Example: Mock buildkite-agent command
   stub buildkite-agent "oidc request-token --audience \* --lifetime \* : echo 'mock-token'"
   ```
3. **Test environment isolation** - ensure tests don't affect each other
4. **Mock external services** - don't make real API calls in tests

### Test Debugging

To debug failing tests:

```bash
# Enable debug output for specific commands
export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty
export CURL_STUB_DEBUG=/dev/tty

# Run tests with verbose output
docker compose run --rm tests bats --verbose-run /plugin/tests/environment.bats
```

## Code Style and Standards

### Bash Style Guidelines

1. **Use strict error handling**
   ```bash
   set -euo pipefail  # Exit on error, undefined vars, pipe failures
   ```

2. **Quote variables**
   ```bash
   echo "Value: $VARIABLE"
   [[ -n "${OPTIONAL_VAR:-}" ]]
   ```

3. **Use meaningful function names**
   ```bash
   create_service_account() { ... }
   cleanup_temporary_files() { ... }
   ```

4. **Add comments for complex logic**
   ```bash
   # Generate workload identity provider ID from repository hash
   REPO_HASH=$(echo -n "$BUILDKITE_REPO" | sha256sum | cut -c1-27)
   ```

### Linting and Code Quality

The project uses automated code quality checks:

```bash
# Run all quality checks
make lint shellcheck

# Individual checks
make lint        # Plugin-specific linting
make shellcheck  # Bash script analysis
```

**ShellCheck Rules**: The project follows ShellCheck recommendations with specific exceptions documented in the code using `# shellcheck disable=SCxxxx` comments.

## Making Changes

### Branching Strategy

1. **Create feature branches** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Use descriptive commit messages**:
   ```
   feat: add support for custom GCP regions
   
   - Add region configuration option
   - Update authentication logic for regional resources
   - Add tests for region-specific authentication
   ```

3. **Keep changes focused** - one feature or fix per pull request

### Configuration Changes

When modifying plugin configuration:

1. **Update `plugin.yml`** with new properties
2. **Update `README.md`** with documentation
3. **Add validation** in the environment hook
4. **Add test coverage** for new configuration options

### Adding New Features

1. **Design consideration**: Ensure features align with the plugin's purpose
2. **Backward compatibility**: Don't break existing usage
3. **Error handling**: Provide clear error messages
4. **Documentation**: Update README and add inline comments
5. **Testing**: Add comprehensive test coverage

## Submitting Pull Requests

### Pre-submission Checklist

- [ ] All tests pass (`make tests`)
- [ ] Code passes linting (`make lint shellcheck`)
- [ ] Documentation is updated (README.md, inline comments)
- [ ] New features have test coverage
- [ ] Commit messages are descriptive
- [ ] No sensitive information is included

### Pull Request Process

1. **Create pull request** with descriptive title and description
2. **Link related issues** if applicable
3. **Request review** from maintainers
4. **Address feedback** promptly
5. **Ensure CI passes** before requesting final review

## Release Process

### Versioning

The project follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Steps

1. **Update version** in relevant files
2. **Create release notes** documenting changes
3. **Tag the release**: `git tag v1.x.x`
4. **Publish release** through GitHub releases
5. **Update documentation** if needed

## Getting Help

### Communication Channels

- **GitHub Issues**: For bugs, feature requests, and questions
- **Pull Request Reviews**: For code-specific discussions
- **Elastic Internal**: Slack channels for team members

### Reporting Issues

When reporting bugs or issues:

1. **Search existing issues** first
2. **Provide reproduction steps**
3. **Include relevant logs** and error messages
4. **Specify environment details** (Buildkite, GCP setup)

### Contributing Guidelines

- Be respectful and constructive
- Follow the code of conduct
- Provide clear documentation for changes
- Test thoroughly before submitting
- Respond promptly to review feedback

## Additional Resources

- [Buildkite Plugin Documentation](https://buildkite.com/docs/plugins)
- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [BATS Testing Framework](https://github.com/bats-core/bats-core)
- [ShellCheck Documentation](https://github.com/koalaman/shellcheck)

---

Thank you for contributing to the oblt-google-auth Buildkite plugin! 🚀