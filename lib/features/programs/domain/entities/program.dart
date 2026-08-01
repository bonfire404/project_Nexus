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

  /// Default programs used as fallback when Firestore collection is empty.
  static const List<Program> defaultPrograms = [
    Program(
      id: 'p1',
      title: 'AI & Machine Learning Internship',
      description: 'Work alongside senior AI engineers building production LLM pipelines, RAG systems, and generative media models.',
      imageUrl: '',
      duration: '12 Weeks',
      level: 'Intermediate',
    ),
    Program(
      id: 'p2',
      title: 'Full Stack Software Engineering Residency',
      description: 'Hands-on web and mobile development using Flutter, React, Firebase, and Node.js microservices.',
      imageUrl: '',
      duration: '8 Weeks',
      level: 'Beginner Friendly',
    ),
    Program(
      id: 'p3',
      title: 'UI/UX Product Design Fellowship',
      description: 'Master modern design systems, user research, glassmorphism UI, interactive prototypes, and Figma tokens.',
      imageUrl: '',
      duration: '10 Weeks',
      level: 'All Levels',
    ),
    Program(
      id: 'p4',
      title: 'Cloud Infrastructure & DevOps Accelerator',
      description: 'Build resilient CI/CD pipelines, Docker containerized architectures, Kubernetes clusters, and Terraform IaC.',
      imageUrl: '',
      duration: '16 Weeks',
      level: 'Advanced',
    ),
  ];
}
