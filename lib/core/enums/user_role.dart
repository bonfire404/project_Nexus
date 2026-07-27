import 'package:flutter/material.dart';

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

  /// Icon representation for UI badges.
  IconData get icon {
    switch (this) {
      case UserRole.applicant:
        return Icons.person_search_rounded;
      case UserRole.intern:
        return Icons.badge_rounded;
      case UserRole.administrator:
        return Icons.admin_panel_settings_rounded;
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

  /// Capability getters for granular permission checks.
  bool get canManageUsers => this == UserRole.administrator;
  bool get canPublishPrograms => this == UserRole.administrator;
  bool get canSendBroadcasts => this == UserRole.administrator;
  bool get canSubmitDeliverables => this == UserRole.intern;
  bool get canAccessLearning => this == UserRole.intern;
  bool get canApplyToPrograms => this == UserRole.applicant;

  /// Route authorization check.
  bool canAccessRoute(String route) {
    if (route == '/users' || route == '/admin') {
      return this == UserRole.administrator;
    }
    return true;
  }
}
