import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/firestore_service.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';

/// Firestore-backed repository for user Applications.
class ApplicationFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'applications';

  /// Get all applications for a specific user.
  Future<List<Map<String, dynamic>>> getUserApplications(String userId) async {
    return await _firestore.queryWhere(
      _collection,
      field: 'userId',
      isEqualTo: userId,
    );
  }

  /// Submit a new application.
  Future<String> submitApplication({
    required String userId,
    required String programName,
    required String organization,
    bool autoPromoteOnEnroll = false,
  }) async {
    final docId = await _firestore.addDocument(_collection, {
      'userId': userId,
      'programName': programName,
      'organization': organization,
      'status': autoPromoteOnEnroll ? 'Accepted' : 'Pending',
      'appliedAt': FieldValue.serverTimestamp(),
    });

    if (autoPromoteOnEnroll) {
      try {
        final userRepo = UserFirestoreRepository();
        await userRepo.updateUser(userId, {'role': 'Intern'});
      } catch (_) {}
    }
    return docId;
  }

  /// Update application status and auto-promote to Intern when Accepted by Admin.
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String userId,
    required String status,
  }) async {
    await _firestore.updateDocument(_collection, applicationId, {'status': status});
    if (status == 'Accepted') {
      try {
        final userRepo = UserFirestoreRepository();
        await userRepo.updateUser(userId, {'role': 'Intern'});
      } catch (_) {}
    }
  }

  /// Withdraw (delete) an application.
  Future<void> withdrawApplication(String docId) async {
    await _firestore.deleteDocument(_collection, docId);
  }

  /// Stream applications for a specific user (real-time).
  Stream<List<Map<String, dynamic>>> streamUserApplications(String userId) {
    return _firestore.streamWhere(
      _collection,
      field: 'userId',
      isEqualTo: userId,
    );
  }

  /// Get admin messages.
  Future<List<Map<String, dynamic>>> getAdminMessages(String userId) async {
    return await _firestore.getCollection('admin_messages');
  }

  /// Stream admin messages in real-time.
  Stream<List<Map<String, dynamic>>> streamAdminMessages(String userId) {
    return _firestore.streamCollection('admin_messages');
  }
}
