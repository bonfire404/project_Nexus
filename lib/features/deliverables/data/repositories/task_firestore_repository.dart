import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/firestore_service.dart';

/// Firestore-backed repository for Tasks (deliverables).
class TaskFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'tasks';

  /// Get all tasks for a specific user.
  Future<List<Map<String, dynamic>>> getUserTasks(String userId) async {
    return await _firestore.queryWhere(
      _collection,
      field: 'userId',
      isEqualTo: userId,
    );
  }

  /// Add a new task.
  Future<String> addTask({
    required String userId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    return await _firestore.addDocument(_collection, {
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update task status.
  Future<void> updateTaskStatus(String docId, String status) async {
    await _firestore.updateDocument(_collection, docId, {'status': status});
  }

  /// Stream tasks for a specific user.
  Stream<List<Map<String, dynamic>>> streamUserTasks(String userId) {
    return _firestore.streamWhere(
      _collection,
      field: 'userId',
      isEqualTo: userId,
    );
  }
}
