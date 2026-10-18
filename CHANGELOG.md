# Changelog

Notable changes to Hearken, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Sign-in for a single account, created on the server with `bin/rails users:create`; every page needs a signed-in session.
- A Content Security Policy on every page, and HTTPS and host checks in production.
