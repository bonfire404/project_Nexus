# Changelog

## [1.5.0](https://github.com/bonfire404/project_Nexus/compare/nexus-v1.4.0...nexus-v1.5.0) (2026-07-27)


### Features

* implement application scaffold with modular feature screens and unified settings UI ([a0593e7](https://github.com/bonfire404/project_Nexus/commit/a0593e711ade32911153e6f167a4684375baa378))
* implement core feature screens and infrastructure including programs, applications, and workspace modules ([60b7979](https://github.com/bonfire404/project_Nexus/commit/60b7979370bcea431757d492d42bd4cab612e2b7))
* implement UI prototype for Week 2 deliverable ([c89f8d4](https://github.com/bonfire404/project_Nexus/commit/c89f8d47dea6a34e912e480a4fa536c2f983de1d))
* implement UI prototype for Week 2 deliverable ([#1](https://github.com/bonfire404/project_Nexus/issues/1)) ([380cae5](https://github.com/bonfire404/project_Nexus/commit/380cae5a341cf9b307fed75d61d740e41c1d68e3))
* initialize Firebase, environment variables, and app dependencies in main entry point ([2757b1e](https://github.com/bonfire404/project_Nexus/commit/2757b1e5a4cb58fbb7d8b24bb17990e92612d541))
* initialize project structure with authentication, routing, asset assets, and custom fonts ([2e94495](https://github.com/bonfire404/project_Nexus/commit/2e94495f695899649b23a3d5b65c202f9cccddaf))
* role onboarding, biometrics, custom photo upload, real-time sync, and skeletonizer preloaders ([169fa44](https://github.com/bonfire404/project_Nexus/commit/169fa4484c6bd28e53010042af61caad94539999))
* setup environment configuration via flutter_dotenv and .env.example ([32e91f0](https://github.com/bonfire404/project_Nexus/commit/32e91f00d23c3e1d70e7d335a8f6be4049499f4d))
* **v1.4.0:** add 3d liquid glass input, biometric holding, and real-time security auto-logout ([8915e13](https://github.com/bonfire404/project_Nexus/commit/8915e1345195e24ac08dcf8e19063c399cd35cee))
* Week 3 - API-connected functional app with feedback form and documentation ([9229134](https://github.com/bonfire404/project_Nexus/commit/92291347119ba33a53986b0e1e16db22869519e4))


### Bug Fixes

* **ci:** add fallback .env asset file step and bump version to 1.4.0+5 ([7f2dc23](https://github.com/bonfire404/project_Nexus/commit/7f2dc239bc6d85f80ce7a4850674837526215b05))
* **ci:** update release-please action to googleapis/release-please-action@v4 ([9ec578e](https://github.com/bonfire404/project_Nexus/commit/9ec578e676981915707d555d6337b384c3f8f398))

## [1.2.0](https://github.com/bonfire404/project_Nexus/compare/v1.1.0...v1.2.0) (2026-07-27)


### Features

* initialize Firebase, environment variables, and app dependencies in main entry point ([2757b1e](https://github.com/bonfire404/project_Nexus/commit/2757b1e5a4cb58fbb7d8b24bb17990e92612d541))
* role onboarding, biometrics, custom photo upload, real-time sync, and skeletonizer preloaders ([169fa44](https://github.com/bonfire404/project_Nexus/commit/169fa4484c6bd28e53010042af61caad94539999))
* setup environment configuration via flutter_dotenv and .env.example ([32e91f0](https://github.com/bonfire404/project_Nexus/commit/32e91f00d23c3e1d70e7d335a8f6be4049499f4d))
* **v1.4.0:** add 3d liquid glass input, biometric holding, and real-time security auto-logout ([8915e13](https://github.com/bonfire404/project_Nexus/commit/8915e1345195e24ac08dcf8e19063c399cd35cee))
* Week 3 - API-connected functional app with feedback form and documentation ([9229134](https://github.com/bonfire404/project_Nexus/commit/92291347119ba33a53986b0e1e16db22869519e4))


### Bug Fixes

* **ci:** update release-please action to googleapis/release-please-action@v4 ([9ec578e](https://github.com/bonfire404/project_Nexus/commit/9ec578e676981915707d555d6337b384c3f8f398))

## [1.4.0] - 2026-07-28

*Published by:* ![GitHub](https://github.githubassets.com/favicons/favicon.png) **@bonfire404** & **@bizcodz**

### Added
- **Sleek 3D Glass Chat Input**: Floating 3D liquid glass message bar with a dedicated 3D send button.
- **Animated Message Sender**: Loading icon inside the send button while your message is sending.
- **Emoji Message Reactions**: Long-press any chat bubble to react with emojis like ❤️, 👍, 😂, and receive instant reaction banners.
- **Minimalist Welcome Back Screen**: Clean welcome page showing your profile picture with an active green online status badge.
- **Fingerprint & Face ID Lock**: Extra account security holding the welcome screen until unlocked with your phone's fingerprint or Face ID.
- **Real-Time Account Security**: Keeps your account protected by safely updating your session if your assigned role changes while online.
- **User Profile Status Dots**: User Management now displays user profile photos alongside live green (online) or grey (offline) status indicators.

### Changed
- **Faster App Startup**: Optimized launch and load times so you can access your dashboard faster.
- **Smart Session Saver**: Stays logged in safely so you don't have to choose your role every time you open the app.

### Fixed
- **Smoother Animations**: Improved transitions and page animations across the app.
- **Notification Reliability**: Fixed messaging permissions and background notifications.

## [1.3.0] - 2026-07-25

### Added
- **Personalized Onboarding**: Tailored welcome guides for Applicants, Interns, and Administrators with live previews.
- **Fingerprint & Face ID Login**: Turn on quick biometric unlock in Onboarding or Settings.
- **Custom Profile Photo Upload**: Pick and update your profile picture anytime from your phone's gallery or camera.
- **Modern User Avatars**: Clean default profile icon for new accounts.
- **Admin User Tools**: Add new users or remove accounts easily in User Management.

### Changed
- **Smoother Profile Edits**: Instant shimmer loading preview when editing your profile details.
- **Live Name Updates**: Your profile name syncs everywhere automatically.

## [1.2.0] - 2026-07-23

### Added
- **Explore Programs**: Discover available internship programs and opportunities.
- **In-App Feedback**: Share your thoughts and suggestions directly from Settings.
- **Fast Loading Screens**: Smooth placeholders while loading your data.

### Fixed
- Improved navigation and app responsiveness.

## [1.1.0] - 2026-07-20

### Features
- Essential screens for programs, application submissions, and team collaboration workspace.

## [1.0.0] - 2026-07-20

*Published by:* ![GitHub](https://github.githubassets.com/favicons/favicon.png) **@bonfire404** & **@bizcodz**

### Added
- Official launch of Excelerate Nexus.
- Account sign-in, profile management, and dashboard.
- Customizable app settings.
