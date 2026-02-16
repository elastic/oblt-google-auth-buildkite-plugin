
## Contributing

When contributing to this plugin, please ensure:

1. All changes include appropriate tests
2. Error messages are clear and actionable
3. Secrets are redacted from logs using `buildkite-agent redactor add`
4. Input validation is performed for user-provided configuration
5. Documentation is updated to reflect changes

## Testing

This plugin includes comprehensive test coverage using BATS (Bash Automated Testing System). 

### Running Tests

To run the tests locally, use the following Makefile targets:
 - `test`: runs BATS tests
 - `integration-test`: will test the functionality itself requesting a token from GCP
 - `plugin-lint`: will check for linting issues
 - `shellcheck`: will check BASH scripts
```
