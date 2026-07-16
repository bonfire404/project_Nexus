import 'package:nexus/core/enums/user_role.dart';

/// Lightweight auth state — no external packages.
class AuthState {
  final UserRole? role;
  final bool isAuthenticated;

  const AuthState({
    this.role,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserRole? role,
    bool? isAuthenticated,
  }) {
    return AuthState(
      role: role ?? this.role,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
