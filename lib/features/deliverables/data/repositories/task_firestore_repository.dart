import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/firestore_service.dart';

/// Firestore-backed repository for Tasks (deliverables).
class TaskFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'tasks';

  static const List<Map<String, dynamic>> _defaultTasks = [
    {
      'id': 'task_1',
      'title': 'Complete Nexus Profile & Role Setup',
      'description': 'Verify contact info, bio, avatar, and notification preferences in settings.',
      'status': 'Completed',
    },
    {
      'id': 'task_2',
      'title': 'Review Project Architecture & Data Models',
      'description': 'Study the codebase structure, repository patterns, and UI state controllers.',
      'status': 'Pending',
    },
    {
      'id': 'task_3',
      'title': 'Submit Sprint 1 Feature Deliverable',
      'description': 'Package your code changes and attach your pull request link for review.',
      'status': 'Pending',
    },
    {
      'id': 'task_4',
      'title': 'Schedule 1-on-1 Mentor Alignment Session',
      'description': 'Book a 30-minute sync with your assigned mentor to discuss mid-term goals.',
      'status': 'Pending',
    },
  ];

  /// Get all tasks for a specific user with fallback support.
  Future<List<Map<String, dynamic>>> getUserTasks(String userId) async {
    try {
      final tasks = await _firestore.queryWhere(
        _collection,
        field: 'userId',
        isEqualTo: userId,
      );
      if (tasks.isNotEmpty) return tasks;
    } catch (_) {}
    return _defaultTasks;
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
