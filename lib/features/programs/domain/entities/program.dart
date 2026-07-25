import 'package:cloud_firestore/cloud_firestore.dart';

class Program {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String duration;
  final String level;

  const Program({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.level,
  });

  /// Create a Program from a Firestore document snapshot.
  factory Program.fromFirestore(Map<String, dynamic> data) {
    return Program(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      duration: data['duration'] ?? '',
      level: data['level'] ?? '',
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'duration': duration,
      'level': level,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
