# Security Policy

## Supported Versions

Only the latest major version of the orb receives security fixes.

| Version | Supported |
|---------|-----------|
| 3.x     | ✅        |
| < 3.0   | ❌        |

## Reporting a Vulnerability

Please report vulnerabilities privately via
[GitHub Security Advisories](https://github.com/kevnm67/ios-orb/security/advisories/new).
Do **not** open a public issue for security reports.

You can expect an initial response within 7 days. If the report is accepted,
a fix will be published as a patch release of the orb and noted in the
GitHub Release changelog.

## Scope

This orb executes shell scripts on CircleCI macOS/Linux executors. Reports of
command injection via orb parameters, credential leakage in build logs, or
unsafe handling of `QLTY_COVERAGE_TOKEN` / Fastlane Match secrets are
particularly relevant.
