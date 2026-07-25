import 'package:nexus/core/services/firestore_service.dart';

/// Firestore-backed repository for Learning resources.
class LearningFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'learning_resources';

  /// Get all learning resources.
  Future<List<Map<String, dynamic>>> getResources() async {
    return await _firestore.getCollection(_collection);
  }

  /// Get resources filtered by category.
  Future<List<Map<String, dynamic>>> getResourcesByCategory(String category) async {
    return await _firestore.queryWhere(
      _collection,
      field: 'category',
      isEqualTo: category,
    );
  }

  /// Stream all resources (real-time).
  Stream<List<Map<String, dynamic>>> streamResources() {
    return _firestore.streamCollection(_collection);
  }
}
