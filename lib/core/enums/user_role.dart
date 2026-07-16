/// Defines the user roles within the Nexus platform.
enum UserRole {
  applicant,
  intern,
  administrator;

  /// Human-readable label for display.
  String get label {
    switch (this) {
      case UserRole.applicant:
        return 'Applicant';
      case UserRole.intern:
        return 'Intern';
      case UserRole.administrator:
        return 'Administrator';
    }
  }

  /// Short description for the role selection screen.
  String get description {
    switch (this) {
      case UserRole.applicant:
        return 'Discover programs and apply';
      case UserRole.intern:
        return 'Access your internship tools';
      case UserRole.administrator:
        return 'Manage programs and teams';
    }
  }
}
