# Nexus - Excelerate Unified Platform

Nexus is an enterprise-grade, role-based platform designed to bridge the gap between aspiring talent and industry opportunities. Built with a focus on performance, security, and structural clarity, Nexus streamlines program discovery, internship tracking, and administrative oversight.

---

## Key Features

### Multi-Role Authentication
- **Tailored Onboarding**: Choose between Applicant, Intern, or Administrator roles.
- **Biometric Security**: Integrated Fingerprint and Face ID authentication for secure access.
- **Input Validation**: Form validation to ensure data integrity during sign-in.

### Dynamic Program Exploration
- **Curated Listings**: Browse professional programs with real-time metadata (Duration, Difficulty Level).
- **Interactive Details**: Program overviews with one-tap enrollment capabilities.

### Design System
- **Typography**: Kameron (Serif) for authoritative headings and Lato (Sans-serif) for high-readability body text.
- **Dark Mode Support**: Low-light interface designed for enterprise efficiency and reduced eye strain.
- **HugeIcons Library**: Modern, high-stroke iconography.

---

## Technical Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.x)
- **Architecture**: Feature-Driven Layered Architecture
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
│   ├── auth/     # Role selection, Login, Controller
│   ├── dashboard/# Home shell, Role-specific widgets
│   └── programs/ # Listing, Details, Domain Logic
└── shared/       # Common Widgets: Buttons, Cards, Inputs
```

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

## Project Milestones

### Week 2 Milestones
- [x] **Role Selection Logic**: Implemented animated card-based selection.
- [x] **Secure Sign-In**: Built interactive login with biometric fallback.
- [x] **Unified Navigation**: Configured routing with `GoRouter` redirects.
- [x] **Discovery Modules**: Developed Program Listing and Detail views.

### Week 3 Milestones
- [x] **API Integration**: Program Listing and Details connected to JSON data sources.
- [x] **Functional Forms**: Feedback form with email and message length validation.
- [x] **Loading UX**: Integrated Skeletonizer for loading states.
- [x] **Modular Repositories**: Implemented repository pattern for data management.

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
