import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/firestore_service.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';

/// Firestore-backed repository for user Applications.
class ApplicationFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'applications';

  static const List<Map<String, dynamic>> _defaultApplications = [
    {
      'id': 'app_1',
      'programName': 'AI & Machine Learning Internship',
      'organization': 'Excelerate AI Labs',
      'status': 'Pending',
      'appliedAt': 'Jul 24, 2026',
    },
    {
      'id': 'app_2',
      'programName': 'UI/UX Product Design Fellowship',
      'organization': 'Design Studio X',
      'status': 'Accepted',
      'appliedAt': 'Jul 18, 2026',
    },
    {
      'id': 'app_3',
      'programName': 'Full Stack Software Engineering Residency',
      'organization': 'Nexus Tech Innovation',
      'status': 'Pending',
      'appliedAt': 'Jul 22, 2026',
    },
  ];

  static const List<Map<String, dynamic>> _defaultAdminMessages = [
    {
      'id': 'msg_1',
      'sender': 'Program Director (Admin)',
      'title': 'Welcome to Nexus Applicant Hub!',
      'body': 'Your application submissions are currently being evaluated by our program leads. Keep an eye on your status updates here!',
      'time': '10:30 AM',
    },
    {
      'id': 'msg_2',
      'sender': 'Nexus Admissions',
      'title': 'Upcoming Fellowship Cohort Interview Schedule',
      'body': 'Accepted applicants for the UI/UX Fellowship will receive calendar invites for 1-on-1 orientation sessions this Friday.',
      'time': 'Yesterday',
    },
  ];

  /// Get all applications for a specific user with fallback support.
  Future<List<Map<String, dynamic>>> getUserApplications(String userId) async {
    try {
      final apps = await _firestore.queryWhere(
        _collection,
        field: 'userId',
        isEqualTo: userId,
      );
      if (apps.isNotEmpty) return apps;
    } catch (_) {}
    return _defaultApplications;
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

  /// Get admin messages with fallback support.
  Future<List<Map<String, dynamic>>> getAdminMessages(String userId) async {
    try {
      final msgs = await _firestore.getCollection('admin_messages');
      if (msgs.isNotEmpty) return msgs;
    } catch (_) {}
    return _defaultAdminMessages;
  }

  /// Stream admin messages in real-time.
  Stream<List<Map<String, dynamic>>> streamAdminMessages(String userId) {
    return _firestore.streamCollection('admin_messages');
  }
}
