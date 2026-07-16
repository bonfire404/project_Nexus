import 'package:flutter/foundation.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:local_auth/local_auth.dart';

/// Vanilla ChangeNotifier for auth state.
/// Includes biometric auth support for the skeleton phase.
class AuthController extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();
  
  UserRole? _selectedRole;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  UserRole? get selectedRole => _selectedRole;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  /// Sets the user's role from the role selection screen.
  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  /// Stub login — accepts any credentials after 1.5s delay.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
  }

  /// Attempt biometric authentication
  Future<void> loginWithBiometrics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        _isLoading = false;
        notifyListeners();
        return; // Device doesn't support biometrics, silently fail back to manual login
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to sign in to Nexus',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Resets all state and returns user to role selection.
  void logout() {
    _selectedRole = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  /// Triggers a notify to re-evaluate router redirects.
  /// Used by splash screen to signal initialization complete.
  void signalChange() {
    notifyListeners();
  }
}
