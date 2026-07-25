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

## [1.3.0] - 2026-07-25

### Added
- **Role-Tailored Onboarding (`RoleOnboardingScreen`)**: Modern, interactive onboarding for `Applicant`, `Intern`, and `Administrator` with embedded live module previews.
- **Native Hardware Biometrics**: Integrated `LocalAuthentication` fingerprint & Face ID prompts into Onboarding and Settings.
- **Zero-Cost Custom Photo Upload Engine (`AvatarUtils`)**: Custom photo picker from gallery/camera encoded as Base64 stored directly in Cloud Firestore (`users/{uid}` under `avatar`), achieving **$0 Firebase Storage fees**.
- **Sleek Default Person Avatar**: Integrated modern vector person icon (`HugeIcons.strokeRoundedUser`) as default avatar fallback.
- **Real-Time Admin User Operations**: Stream subscription listener in Admin `UsersScreen` with `+ Add User` modal and `Swipe-to-Delete`.

### Changed
- **Skeletonizer Preloaders**: Replaced loading spinners in Profile Edit Bottom Sheet with `Skeletonizer` shimmer loading.
- **Profile Name Binding**: Replaced static fallback text with live real-time sync from `authController.userDisplayName` and Firestore documents.

## [1.2.0] - 2026-07-23

### Added
- **Mock API Integration**: Program data fetched from local JSON source (`assets/data/programs.json`).
- **Validated Feedback Form**: New Feedback screen accessible from Settings with robust input validation.
- **Repository Pattern**: Implemented `ProgramRepositoryImpl` for separation of concerns.
- **Skeleton Loading**: Integrated `Skeletonizer` for smoother transitions on data-driven screens.

### Fixed
- Deprecated `withOpacity` calls migrated to `withValues`.
- Improved router redirect logic for role selection.
