# Changelog

## [1.1.0](https://github.com/bonfire404/project_Nexus/compare/v1.0.0...v1.1.0) (2026-07-20)


### Features

* implement core feature screens and infrastructure including programs, applications, and workspace modules ([60b7979](https://github.com/bonfire404/project_Nexus/commit/60b7979370bcea431757d492d42bd4cab612e2b7))

## [1.0.0] - 2026-07-20 03:18 UTC

*Published by:* ![GitHub](https://github.githubassets.com/favicons/favicon.png) **@bonfire404** & **@bizcodz**

### Added
- Initial release of Excelerate Nexus.
- Implemented core authentication.
- Added profile and settings management.
- Added dashboard and program discovery.
- In-app changelog in settings reading from Markdown file.
- Proper semantic versioning via GitHub Actions and release-please.

### Changed
- Minor UI improvements and bug fixes.

## [1.2.0] - 2026-07-23

### Added
- **Mock API Integration**: Program data is now fetched from a local JSON source (`assets/data/programs.json`).
- **Validated Feedback Form**: New Feedback screen accessible from Settings with robust input validation.
- **Repository Pattern**: Implemented `ProgramRepositoryImpl` for better separation of concerns.
- **Skeleton Loading**: Integrated `Skeletonizer` for smoother transitions on data-driven screens.
- **Improved Details**: Dynamic loading of program details based on ID.

### Fixed
- Deprecated `withOpacity` calls migrated to `withValues`.
- Improved router redirect logic for role selection.
