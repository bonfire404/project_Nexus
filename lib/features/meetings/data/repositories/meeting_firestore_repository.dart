import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/firestore_service.dart';

/// Firestore-backed repository for Meetings/Schedule.
class MeetingFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'meetings';

  /// Get all meetings for a specific user.
  Future<List<Map<String, dynamic>>> getUserMeetings(String userId) async {
    return await _firestore.queryWhere(
      _collection,
      field: 'userId',
      isEqualTo: userId,
    );
  }

  /// Add a new meeting.
  Future<String> addMeeting({
    required String userId,
    required String title,
    required String description,
    required DateTime scheduledAt,
  }) async {
    return await _firestore.addDocument(_collection, {
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': 'Scheduled',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream meetings for a specific user.
  Stream<List<Map<String, dynamic>>> streamUserMeetings(String userId) {
    return _firestore.streamWhere(
      _collection,
      field: 'userId',
      isEqualTo: userId,
    );
  }
}
