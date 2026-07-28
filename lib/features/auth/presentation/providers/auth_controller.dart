import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _avatarUrl;
  String? _authError;
  StreamSubscription<Map<String, dynamic>?>? _userDocSubscription;

  UserRole? get selectedRole => _selectedRole;
  bool get isAuthenticated => _isAuthenticated || currentUser != null;
  bool get isLoading => _isLoading;
  String? get authError => _authError;
  User? get currentUser => _firebaseAuth.currentUser;
  String? get avatarUrl => _avatarUrl ?? currentUser?.photoURL;
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

  Future<void> updateAvatar(String newAvatar) async {
    _avatarUrl = newAvatar;
    notifyListeners();

    final user = currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar_${user.uid}', newAvatar);
      try {
        await _userRepo.updateUser(user.uid, {
          'avatar': newAvatar,
          'photoUrl': newAvatar,
        });
      } catch (_) {}
    }
  }

  static const String _roleKey = 'nexus_saved_user_role';
  static const String _nameKey = 'nexus_saved_display_name';

  /// Restores saved user session and role from SharedPreferences & Firestore
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRoleStr = prefs.getString(_roleKey);
      final savedName = prefs.getString(_nameKey);

      if (savedName != null && savedName.isNotEmpty) {
        _displayName = savedName;
      }

      if (savedRoleStr != null && savedRoleStr.isNotEmpty) {
        _selectedRole = _parseUserRole(savedRoleStr);
      }

      final user = currentUser;
      if (user != null) {
        _isAuthenticated = true;
        final prefs = await SharedPreferences.getInstance();
        final savedAvatar = prefs.getString('user_avatar_${user.uid}');
        if (savedAvatar != null && savedAvatar.isNotEmpty) {
          _avatarUrl = savedAvatar;
        }
        await _syncUserRoleWithDatabase(user.email ?? '');
      }
    } catch (e) {
      debugPrint('Note: Error restoring auth session: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Sets the user's role from the role selection screen.
  void selectRole(UserRole role) {
    _selectedRole = role;
    _authError = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_roleKey, role.label);
    });
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
      final success = await _syncUserRoleWithDatabase(email);
      if (!success) return;
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
            final syncOk = await _syncUserRoleWithDatabase(email);
            if (!syncOk) return;
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

  /// Syncs selected role and real-time status/presence to system database.
  Future<bool> _syncUserRoleWithDatabase(String email) async {
    final user = currentUser;
    if (user == null) return false;

    _displayName = null;

    try {
      Map<String, dynamic>? profile = await _userRepo.getUserProfile(user.uid);
      String targetDocId = user.uid;

      if (profile == null) {
        final allUsers = await _userRepo.getAllUsers();
        final match = allUsers.firstWhere(
          (u) => (u['email'] as String? ?? '').toLowerCase() == email.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) {
          profile = match;
          targetDocId = match['id'] as String? ?? match['uid'] as String? ?? user.uid;
        }
      }

      final updateData = <String, dynamic>{
        'status': 'Active',
        'lastSeen': DateTime.now().toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      final localSavedAvatar = prefs.getString('user_avatar_${user.uid}');

      if (profile != null) {
        final docAvatar = profile['avatar'] as String? ?? profile['photoUrl'] as String?;
        if (docAvatar != null && docAvatar.isNotEmpty) {
          _avatarUrl = docAvatar;
          await prefs.setString('user_avatar_${user.uid}', docAvatar);
        } else if (localSavedAvatar != null && localSavedAvatar.isNotEmpty) {
          _avatarUrl = localSavedAvatar;
          updateData['avatar'] = localSavedAvatar;
        }

        if (profile.containsKey('name')) {
          final savedName = profile['name'] as String?;
          if (savedName != null && savedName.isNotEmpty) {
            _displayName = savedName;
          }
        }

        final savedRoleStr = profile['role'] as String? ?? '';
        final storedRole = _parseUserRole(savedRoleStr);

        if (storedRole != null) {
          if (_selectedRole != null && _selectedRole != storedRole) {
            // Strict Role Validation: Deny login if selected role doesn't match assigned account role
            await _firebaseAuth.signOut();
            _isAuthenticated = false;
            _selectedRole = null;
            _authError = 'Access Denied: This account is assigned to the ${storedRole.label} role. Please select ${storedRole.label} to sign in.';
            return false;
          }
          _selectedRole = storedRole;
          updateData['role'] = storedRole.label;
        } else if (_selectedRole != null) {
          updateData['role'] = _selectedRole!.label;
        }

        await _userRepo.updateUser(targetDocId, updateData);
      } else {
        // First-time account creation: store chosen role in system database
        final roleLabel = _selectedRole?.label ?? 'Applicant';
        final handle = email.split('@')[0];
        final name = handle[0].toUpperCase() + handle.substring(1);
        _displayName = name;
        await _userRepo.setUserProfile(
          uid: targetDocId,
          name: name,
          email: email,
          role: roleLabel,
          status: 'Active',
          avatar: _avatarUrl ?? localSavedAvatar,
        );
      }

      if (_selectedRole != null) {
        await prefs.setString(_roleKey, _selectedRole!.label);
      }
      if (_displayName != null) {
        await prefs.setString(_nameKey, _displayName!);
      }

      _startPresenceHeartbeat();
      _listenToRealtimeRoleChanges(targetDocId);
      return true;
    } catch (e) {
      debugPrint('Note: Error syncing user role with database: $e');
      _startPresenceHeartbeat();
      return true;
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
        final email = currentUser?.email ?? '';
        if (email.isNotEmpty) {
          await _syncUserRoleWithDatabase(email);
        }
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      _authError = 'Biometric authentication failed.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Timer? _heartbeatTimer;

  void _startPresenceHeartbeat() {
    _heartbeatTimer?.cancel();
    _updatePresence('Online');
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isAuthenticated) {
        _updatePresence('Online');
      }
    });
  }

  void _stopPresenceHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _updatePresence(String status) async {
    final user = currentUser;
    if (user != null) {
      try {
        await _userRepo.updateUser(user.uid, {
          'status': status,
          'lastSeen': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        try {
          await _userRepo.setUserProfile(
            uid: user.uid,
            name: userDisplayName,
            email: userEmail,
            role: _selectedRole?.label ?? 'Applicant',
            status: status,
          );
        } catch (e) {
          debugPrint('Note: Error updating presence: $e');
        }
      }
    }
  }

  void _listenToRealtimeRoleChanges(String targetDocId) {
    _userDocSubscription?.cancel();
    if (targetDocId.isEmpty) return;

    _userDocSubscription = _userRepo.streamUserProfile(targetDocId).listen((doc) {
      if (doc != null && isAuthenticated) {
        final savedRoleStr = doc['role'] as String? ?? '';
        final storedRole = _parseUserRole(savedRoleStr);
        if (storedRole != null && _selectedRole != null && storedRole != _selectedRole) {
          debugPrint('Real-time role change detected in Firestore (${_selectedRole?.label} -> ${storedRole.label}). Executing silent session logout.');
          logout();
        }
      }
    });
  }

  /// Resets all state and signs out with real-time status update.
  Future<void> logout() async {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    await _updatePresence('Offline');
    _stopPresenceHeartbeat();
    await _firebaseAuth.signOut();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roleKey);
      await prefs.remove(_nameKey);
    } catch (_) {}
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

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    _stopPresenceHeartbeat();
    super.dispose();
  }
}
