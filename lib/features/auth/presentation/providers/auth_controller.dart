import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:nexus/core/services/firebase_auth_service.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';
import 'package:local_auth/local_auth.dart';

/// Vanilla ChangeNotifier for auth state backed by system database.
class AuthController extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final UserFirestoreRepository _userRepo = UserFirestoreRepository();

  UserRole? _selectedRole;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _displayName;
  String? _authError;

  UserRole? get selectedRole => _selectedRole;
  bool get isAuthenticated => _isAuthenticated || currentUser != null;
  bool get isLoading => _isLoading;
  String? get authError => _authError;
  User? get currentUser => _firebaseAuth.currentUser;
  String get userEmail => currentUser?.email ?? 'user@nexus.com';
  String get userDisplayName {
    if (_displayName != null && _displayName!.isNotEmpty) {
      return _displayName!;
    }
    final name = currentUser?.displayName;
    if (name != null && name.isNotEmpty) return name;
    final email = currentUser?.email;
    if (email != null && email.contains('@')) {
      final handle = email.split('@')[0];
      return handle[0].toUpperCase() + handle.substring(1);
    }
    return 'Nexus User';
  }

  void updateDisplayName(String name) {
    _displayName = name;
    notifyListeners();
  }

  /// Sets the user's role from the role selection screen.
  void selectRole(UserRole role) {
    _selectedRole = role;
    _authError = null;
    notifyListeners();
  }

  /// Clears selected role for role switching.
  void clearRole() {
    _selectedRole = null;
    _authError = null;
    notifyListeners();
  }

  /// System database login.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      await _firebaseAuth.signInWithEmail(email, password);
      _isAuthenticated = true;
      await _syncUserRoleWithDatabase(email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          final existingProfiles = await _userRepo.getAllUsers();
          final matchingProfile = existingProfiles.firstWhere(
            (p) => (p['email'] as String? ?? '').toLowerCase() == email.toLowerCase(),
            orElse: () => {},
          );

          if (matchingProfile.isNotEmpty || email.toLowerCase() == 'excelerateproject@gmail.com') {
            await _firebaseAuth.createUserWithEmail(email, password);
            _isAuthenticated = true;
            await _syncUserRoleWithDatabase(email);
            return;
          }
        } catch (_) {}
      }

      if (e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'user-not-found') {
        _authError = 'Invalid email address or password. Please check your credentials.';
      } else {
        _authError = e.message ?? 'Authentication failed.';
      }
    } catch (e) {
      _authError = 'An unexpected error occurred during sign in.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// System database account creation.
  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    _authError = null;
    if (name.isNotEmpty) {
      _displayName = name;
    }
    notifyListeners();

    try {
      await _firebaseAuth.createUserWithEmail(email, password);
      _isAuthenticated = true;
      await _syncUserRoleWithDatabase(email);
    } on FirebaseAuthException catch (e) {
      _authError = e.message ?? 'Account creation failed.';
    } catch (e) {
      _authError = 'An unexpected error occurred during registration.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Syncs selected role to system database or restores saved account role.
  Future<void> _syncUserRoleWithDatabase(String email) async {
    final user = currentUser;
    if (user == null) return;

    _displayName = null;

    try {
      final profile = await _userRepo.getUserProfile(user.uid);
      if (profile != null) {
        if (profile.containsKey('name')) {
          final savedName = profile['name'] as String?;
          if (savedName != null && savedName.isNotEmpty) {
            _displayName = savedName;
          }
        }
        if (profile.containsKey('role')) {
          final savedRoleStr = profile['role'] as String? ?? '';
          final restoredRole = _parseUserRole(savedRoleStr);
          if (restoredRole != null) {
            _selectedRole = restoredRole;
          }
        }
      } else {
        // First-time account creation: store chosen role in system database
        final roleLabel = _selectedRole?.label ?? 'Applicant';
        final handle = email.split('@')[0];
        final name = handle[0].toUpperCase() + handle.substring(1);
        _displayName = name;
        await _userRepo.setUserProfile(
          uid: user.uid,
          name: name,
          email: email,
          role: roleLabel,
        );
      }
    } catch (e) {
      debugPrint('Note: Error syncing user role with database: $e');
    }
  }

  UserRole? _parseUserRole(String roleStr) {
    final lower = roleStr.toLowerCase();
    if (lower.contains('admin')) return UserRole.administrator;
    if (lower.contains('intern')) return UserRole.intern;
    if (lower.contains('applicant')) return UserRole.applicant;
    return null;
  }

  /// Attempt biometric authentication
  Future<void> loginWithBiometrics() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final authenticated = await _localAuth.authenticate(
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
      _authError = 'Biometric authentication failed.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Resets all state and signs out.
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _selectedRole = null;
    _displayName = null;
    _isAuthenticated = false;
    _isLoading = false;
    _authError = null;
    notifyListeners();
  }

  /// Triggers a notify to re-evaluate router redirects.
  void signalChange() {
    notifyListeners();
  }
}
