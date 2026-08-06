# Nexus - Excelerate Unified Platform

Nexus is an enterprise-grade, role-based platform designed to bridge the gap between aspiring talent and industry opportunities. Built with a focus on performance, security, and structural clarity, Nexus streamlines program discovery, internship tracking, and administrative oversight into a single unified workspace.

---

## Problem Statement & Platform Solution

### Problem Statement
- **Fragmented Workflow**: Users constantly switch between different applications to complete daily tasks.
- **Collaboration Barriers**: Communication and team collaboration become fragmented and inefficient.
- **Tracking Friction**: Monitoring internship progress, deliverables, and milestones is difficult without centralized tracking.
- **Administrative Overhead**: Administrative processes require significant manual coordination across disconnected tools.
- **Inconsistent User Experience**: Disjointed interfaces lead to lower engagement and reduced productivity.

### The Nexus Solution
Excelerate Nexus addresses these challenges by offering a centralized, enterprise platform with:
- **Multi-Role Secure Authentication**: Role-tailored access for Applicants, Interns, and Administrators.
- **Personalized Workspace Dashboard**: Centralized hub for tasks, scheduled meetings, and announcements.
- **Built-in Communication Tools**: Integrated tools for team messaging and collaborative workflows.
- **Deliverable & Progress Tracking**: Real-time progress monitoring for internship tasks and milestone reviews.
- **Learning & Evaluation Management**: Curated learning modules and structured performance evaluation.
- **AI-Powered Assistant**: Intelligent in-app assistant providing instant guidance, automated Q&A, and workflow assistance.
- **Administrative Oversight Suite**: Governance tools for user management, engagement analytics, and program publishing.

---

## Core Features

### Multi-Role Authentication
- **Tailored Onboarding**: Role-specific experience for Applicants, Interns, and Administrators.
- **Biometric Security**: Integrated Fingerprint and Face ID authentication for secure access.
- **Input Validation**: Robust form validation ensuring data integrity during sign-in.

### Dynamic Program Exploration
- **Curated Listings**: Browse professional programs with real-time metadata (Duration, Difficulty Level).
- **Interactive Overviews**: Program descriptions with streamlined enrollment capabilities.

### Design System
- **Typography**: Kameron (Serif) for authoritative headings and Lato (Sans-serif) for high-readability body text.
- **Dark Mode Support**: Low-light interface designed for enterprise efficiency and reduced eye strain.
- **HugeIcons Library**: Modern, high-stroke iconography.

---

## Technical Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.x)
- **Architecture**: Feature-Driven Layered Architecture (Clean Architecture Principles)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) for declarative navigation
- **State Management**: Controller-based pattern using `ChangeNotifier`
- **Security**: [Local Auth](https://pub.dev/packages/local_auth) for hardware-level biometrics

---

## Project Architecture

```text
lib/
├── app/          # Global configuration: Router, Themes, App Shell
├── core/         # Shared: Enums, Constants, Global Styles
├── features/     # Encapsulated Modules
│   ├── admin/        # Administrative user & program governance
│   ├── ai_assistant/ # AI-powered assistant module
│   ├── auth/         # Role selection, Login, Controller
│   ├── dashboard/    # Home shell, Role-specific widgets
│   ├── deliverables/ # Task & progress tracking
│   ├── learning/     # Educational modules & resources
│   ├── meetings/     # Meeting scheduling & calendar
│   └── programs/     # Program listings & detail domain logic
└── shared/       # Common Widgets: Buttons, Cards, Inputs
```

---

## Continuous Integration & Automated Delivery (CI/CD)

Project Nexus utilizes a GitHub Actions CI/CD pipeline powered by Google's **Release Please** framework to automate semantic versioning, changelog generation, and release management based on Conventional Commit messages pushed to the `main` branch. 

Upon release creation, the pipeline provisions a Java 17 and Flutter stable build environment, compiles a production Android APK, and uploads it directly to the corresponding GitHub Release for distribution.

---

## Development Milestones

- **Week 1**: Project planning, environment setup, GitHub repository initialization, wireframes, and application structure definition.
- **Week 2**: User interface development, unified navigation, authentication system, and dashboard implementation.
- **Week 3**: API integration, feedback module, registered user authentication, and validation enhancements.
- **Week 4**: AI Assistant integration, UI refinements, bug fixes, automated testing, project documentation, and final presentation.

---

## Getting Started

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/BONFIREBASE/project_Nexus.git
   ```

2. **Initialize Project**
   ```bash
   flutter pub get
   ```

3. **Launch Application**
   ```bash
   flutter run
   ```

---

## License & Maintenance

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

- **Maintained by**: [Bonfire Base Studio](https://bonfire.base69.studio) (`support@base69.studio`)
- **Original Code Collaborators (Team 14)**:
  - **Herbert Botwe Sackey** – Team Leader, Associate Developer
  - **Bon Jury Pecaoco** – Assistant Team Leader, Lead Developer
  - **Kodi Venkata Keerthan** – UI/UX Designer, Associate Developer

---
Developed for the Excelerate Nexus Platform.
