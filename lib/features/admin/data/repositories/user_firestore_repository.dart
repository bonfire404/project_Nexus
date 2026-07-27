import 'package:nexus/core/services/firestore_service.dart';

/// Firestore-backed repository for Admin user management.
class UserFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'users';

  /// Get all users (deduplicated by normalized email and name).
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final rawUsers = await _firestore.getCollection(_collection);
    final Map<String, Map<String, dynamic>> uniqueMap = {};

    for (final u in rawUsers) {
      final email = (u['email'] as String? ?? '').trim().toLowerCase();
      final name = (u['name'] as String? ?? '').trim().toLowerCase();
      final id = (u['id'] as String? ?? u['uid'] as String? ?? '').trim();

      if (email.isEmpty && name.isEmpty && id.isEmpty) continue;

      final key = email.isNotEmpty ? 'email_$email' : (name.isNotEmpty ? 'name_$name' : 'id_$id');

      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = u;
      } else {
        final existing = uniqueMap[key]!;
        final existingHasAvatar = (existing['avatar'] as String? ?? '').isNotEmpty;
        final newHasAvatar = (u['avatar'] as String? ?? '').isNotEmpty;

        if (!existingHasAvatar && newHasAvatar) {
          uniqueMap[key] = u;
        }
      }
    }

    return uniqueMap.values.toList();
  }

  /// Get users by role.
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    return await _firestore.queryWhere(
      _collection,
      field: 'role',
      isEqualTo: role,
    );
  }

  /// Get or create a user profile document.
  Future<void> setUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role,
    String status = 'Active',
  }) async {
    await _firestore.setDocument(_collection, uid, {
      'name': name,
      'email': email,
      'role': role,
      'status': status,
    });
    await logAuditAction(
      action: 'USER_CREATED',
      targetUid: uid,
      details: {'name': name, 'email': email, 'role': role},
    );
  }

  /// Get a single user by UID.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    return await _firestore.getDocument(_collection, uid);
  }

  /// Alias for getting user profile document by UID.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return await getUser(uid);
  }

  /// Update user profile fields.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.updateDocument(_collection, uid, data);
    await logAuditAction(
      action: 'USER_UPDATED',
      targetUid: uid,
      details: data,
    );
  }

  /// Delete user document by UID.
  Future<void> deleteUser(String uid) async {
    await _firestore.deleteDocument(_collection, uid);
    await logAuditAction(
      action: 'USER_DELETED',
      targetUid: uid,
    );
  }

  /// Record admin audit log entry.
  Future<void> logAuditAction({
    required String action,
    required String targetUid,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.addDocument('audit_logs', {
        'action': action,
        'targetUid': targetUid,
        'details': details ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Stream all users (real-time).
  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return _firestore.streamCollection(_collection);
  }

  /// Stream a single user profile document by UID (real-time).
  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _firestore.streamDocument(_collection, uid);
  }
}
