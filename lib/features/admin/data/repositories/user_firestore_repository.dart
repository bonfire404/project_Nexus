import 'package:nexus/core/services/firestore_service.dart';

/// Firestore-backed repository for Admin user management.
class UserFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'users';

  /// Get all users.
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _firestore.getCollection(_collection);
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
  }

  /// Delete user document by UID.
  Future<void> deleteUser(String uid) async {
    await _firestore.deleteDocument(_collection, uid);
  }

  /// Stream all users (real-time).
  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return _firestore.streamCollection(_collection);
  }
}
