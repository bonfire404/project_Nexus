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

  /// Respond to a feedback item as an Administrator and dispatch direct message to recipient.
  Future<void> respondToFeedback(
    String docId,
    String responseText, {
    String? recipientEmail,
    String? recipientUserId,
  }) async {
    await _firestore.updateDocument(_collection, docId, {
      'response': responseText,
      'respondedAt': FieldValue.serverTimestamp(),
      'status': 'Responded',
    });

    // Dispatch direct announcement message to user inbox
    try {
      final formattedMessage =
          "📢 Response to your Help & Support Report:\n\n\"$responseText\"\n\n🔒 Private Feedback: Only you can see this response to your submitted report.";

      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': 'nexus_announcements',
        'senderName': 'Nexus Support & Announcements',
        'recipientId': recipientUserId ?? '',
        'recipientEmail': recipientEmail ?? '',
        'content': formattedMessage,
        'feedbackId': docId,
        'isFeedbackResponse': true,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sent',
      });
    } catch (_) {}
  }

  /// Update feedback item status (e.g. from 'Responded' to 'Done').
  Future<void> updateFeedbackStatus(String docId, String status) async {
    await _firestore.updateDocument(_collection, docId, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
