# Changelog — ZeroInject

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-03-05

### Fixed
- Removed mock/dummy SSH account generation (`_generateDemoAccounts`) — parsers now return real parsed data or empty lists
- Created missing `sni_scanner.dart` screen (was imported in `main.dart` but didn't exist)
- Created missing `offline_configs.dart` screen (was imported in `main.dart` but didn't exist)
- Expanded `.gitignore` with Dart/Flutter/Android/iOS/IDE entries
- Deleted stale remote branch `webapp-poc`

### Changed
- All SSH scrapers (`_parseSSHKit`, `_parseFastSSH`, `_parseSSHOcean`) now use real regex parsing instead of generating demo data

## [1.1.0] - 2026-03-04

### Added
- Trilingual README (EN/ID/CN) with disclaimer
- CONTRIBUTING.md with trilingual content and disclaimer
- CODE_OF_CONDUCT.md with disclaimer
- SECURITY.md with disclaimer
- MIT License (2026)
- GitHub issue templates (bug report, feature request, question)
- Pull request template with disclaimer
- FUNDING.yml
- Deleted stale branch: webapp-poc

## [1.0.0] - Initial Release

### Added
- Dart/Flutter multi-platform core
- Node.js server backend
- Web interface for control
