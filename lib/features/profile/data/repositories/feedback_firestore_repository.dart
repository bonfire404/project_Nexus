import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/firestore_service.dart';

/// Firestore-backed repository for User Feedback.
class FeedbackFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'feedback';

  /// Submit user feedback document to Firestore.
  Future<String> submitFeedback({
    required String email,
    required String category,
    required String message,
    String? userId,
  }) async {
    return await _firestore.addDocument(_collection, {
      'userId': userId ?? '',
      'email': email,
      'category': category,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream feedback documents for admin review.
  Stream<List<Map<String, dynamic>>> streamAllFeedback() {
    return _firestore.streamCollection(_collection);
  }

  /// Get all feedback documents for admin review.
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    try {
      return await _firestore.getCollectionOrdered(_collection, orderBy: 'createdAt', descending: true);
    } catch (_) {
      return await _firestore.getCollection(_collection);
    }
  }

  /// Respond to a feedback item as an Administrator.
  Future<void> respondToFeedback(String docId, String responseText) async {
    await _firestore.updateDocument(_collection, docId, {
      'response': responseText,
      'respondedAt': FieldValue.serverTimestamp(),
      'status': 'Responded',
    });
  }
}
