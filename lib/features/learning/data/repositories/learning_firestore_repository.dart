import 'package:nexus/core/services/firestore_service.dart';

/// Firestore-backed repository for Learning resources.
class LearningFirestoreRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _collection = 'learning_resources';

  static const List<Map<String, String>> _defaultResources = [
    {
      'title': 'Getting Started: Nexus Workspace & Tools',
      'type': 'PDF Guide',
      'category': 'Getting Started',
    },
    {
      'title': 'Git Branching & GitHub PR Workflow Best Practices',
      'type': 'PDF Guide',
      'category': 'Getting Started',
    },
    {
      'title': 'Flutter & Cross-Platform Development Architecture Masterclass',
      'type': 'Video Course',
      'category': 'Video Tutorials',
    },
    {
      'title': 'Firebase Authentication & Firestore Data Modeling',
      'type': 'Video Course',
      'category': 'Video Tutorials',
    },
    {
      'title': 'Agile Sprint Planning & Weekly Deliverable Template',
      'type': 'Doc Template',
      'category': 'Templates & Documents',
    },
    {
      'title': 'Design System Glassmorphism UI Component Spec',
      'type': 'Figma Kit',
      'category': 'Templates & Documents',
    },
    {
      'title': 'How to Prepare for Weekly Mentor Check-ins',
      'type': 'FAQ Article',
      'category': 'FAQs',
    },
    {
      'title': 'Internship Program Graduation & Certificate Criteria',
      'type': 'FAQ Article',
      'category': 'FAQs',
    },
  ];

  /// Get all learning resources with fallback support.
  Future<List<Map<String, dynamic>>> getResources() async {
    try {
      final resources = await _firestore.getCollection(_collection);
      if (resources.isNotEmpty) return resources;
    } catch (_) {}
    return _defaultResources;
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
