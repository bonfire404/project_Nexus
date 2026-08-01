import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/firestore_service.dart';

/// Firestore Seeder for Nexus application.
/// Automatically populates default Programs, Learning Resources, Tasks, and Meetings if empty.
class FirestoreSeeder {
  static final FirestoreService _firestore = FirestoreService();

  static Future<void> seedIfEmpty() async {
    try {
      await _seedPrograms();
      await _seedLearningResources();
      await _seedTasks();
      await _seedMeetings();
      await _seedApplications();
      await _seedAdminMessages();
    } catch (_) {}
  }

  static Future<void> _seedPrograms() async {
    final existing = await _firestore.getCollection('programs');
    if (existing.isNotEmpty) return;

    final defaultPrograms = [
      {
        'title': 'AI & Machine Learning Internship',
        'organization': 'Excelerate AI Labs',
        'location': 'Remote',
        'type': 'Full-time • 12 Weeks',
        'stipend': '\$1,200 / mo',
        'level': 'Intermediate',
        'applicantsCount': 42,
        'description': 'Work alongside senior AI engineers building production LLM pipelines, RAG systems, and generative media models.',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Full Stack Software Engineering Residency',
        'organization': 'Nexus Tech Innovation',
        'location': 'Hybrid',
        'type': 'Part-time • 8 Weeks',
        'stipend': '\$800 / mo',
        'level': 'Beginner Friendly',
        'applicantsCount': 35,
        'description': 'Hands-on web and mobile development using Flutter, React, Firebase, and Node.js microservices.',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'UI/UX Product Design Fellowship',
        'organization': 'Design Studio X',
        'location': 'Remote',
        'type': 'Flexible • 10 Weeks',
        'stipend': 'Certificate & Portfolio',
        'level': 'All Levels',
        'applicantsCount': 28,
        'description': 'Master modern design systems, user research, glassmorphism UI, interactive prototypes, and Figma tokens.',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Cloud Infrastructure & DevOps Accelerator',
        'organization': 'Cloud Scaling Corp',
        'location': 'Remote',
        'type': 'Full-time • 16 Weeks',
        'stipend': '\$1,500 / mo',
        'level': 'Advanced',
        'applicantsCount': 19,
        'description': 'Build resilient CI/CD pipelines, Docker containerized architectures, Kubernetes clusters, and Terraform IaC.',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final program in defaultPrograms) {
      await _firestore.addDocument('programs', program);
    }
  }

  static Future<void> _seedLearningResources() async {
    final existing = await _firestore.getCollection('learning_resources');
    if (existing.isNotEmpty) return;

    final defaultResources = [
      {
        'title': 'Getting Started: Nexus Workspace & Tools',
        'type': 'PDF Guide',
        'category': 'Getting Started',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Git Branching & GitHub PR Workflow Best Practices',
        'type': 'PDF Guide',
        'category': 'Getting Started',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Flutter & Cross-Platform Development Architecture Masterclass',
        'type': 'Video Course',
        'category': 'Video Tutorials',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Firebase Authentication & Firestore Data Modeling',
        'type': 'Video Course',
        'category': 'Video Tutorials',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Agile Sprint Planning & Weekly Deliverable Template',
        'type': 'Doc Template',
        'category': 'Templates & Documents',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Design System Glassmorphism UI Component Spec',
        'type': 'Figma Kit',
        'category': 'Templates & Documents',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'How to Prepare for Weekly Mentor Check-ins',
        'type': 'FAQ Article',
        'category': 'FAQs',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Internship Program Graduation & Certificate Criteria',
        'type': 'FAQ Article',
        'category': 'FAQs',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final resource in defaultResources) {
      await _firestore.addDocument('learning_resources', resource);
    }
  }

  static Future<void> _seedTasks() async {
    final existing = await _firestore.getCollection('tasks');
    if (existing.isNotEmpty) return;

    final defaultTasks = [
      {
        'userId': 'guest_user',
        'title': 'Complete Nexus Profile & Role Setup',
        'description': 'Verify contact info, bio, avatar, and notification preferences in settings.',
        'status': 'Completed',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'guest_user',
        'title': 'Review Project Architecture & Data Models',
        'description': 'Study the codebase structure, repository patterns, and UI state controllers.',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'guest_user',
        'title': 'Submit Sprint 1 Feature Deliverable',
        'description': 'Package your code changes and attach your pull request link for review.',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'guest_user',
        'title': 'Schedule 1-on-1 Mentor Alignment Session',
        'description': 'Book a 30-minute sync with your assigned mentor to discuss mid-term goals.',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final task in defaultTasks) {
      await _firestore.addDocument('tasks', task);
    }
  }

  static Future<void> _seedMeetings() async {
    final existing = await _firestore.getCollection('meetings');
    if (existing.isNotEmpty) return;

    final defaultMeetings = [
      {
        'userId': 'guest_user',
        'title': 'Daily Stand-up & Sprint Alignment',
        'description': 'Quick sync to share progress, active tasks, and blockers.',
        'time': '9:00 AM',
        'date': 'Today',
        'type': 'Team',
        'link': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'guest_user',
        'title': '1-on-1 Mentor Sync',
        'description': 'Weekly personal guidance and performance feedback with your mentor.',
        'time': '2:00 PM',
        'date': 'Today',
        'type': '1-on-1',
        'link': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'guest_user',
        'title': 'Sprint Review & Demo Presentation',
        'description': 'Review completed features and demonstrate working prototypes to leads.',
        'time': '10:00 AM',
        'date': 'Jul 19',
        'type': 'Team',
        'link': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final meeting in defaultMeetings) {
      await _firestore.addDocument('meetings', meeting);
    }
  }

  static Future<void> _seedApplications() async {
    final existing = await _firestore.getCollection('applications');
    if (existing.isNotEmpty) return;

    final defaultApps = [
      {
        'userId': 'guest_user',
        'programName': 'AI & Machine Learning Internship',
        'organization': 'Excelerate AI Labs',
        'status': 'Pending',
        'appliedAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'guest_user',
        'programName': 'UI/UX Product Design Fellowship',
        'organization': 'Design Studio X',
        'status': 'Accepted',
        'appliedAt': FieldValue.serverTimestamp(),
      },
      {
        'userId': 'guest_user',
        'programName': 'Full Stack Software Engineering Residency',
        'organization': 'Nexus Tech Innovation',
        'status': 'Pending',
        'appliedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final app in defaultApps) {
      await _firestore.addDocument('applications', app);
    }
  }

  static Future<void> _seedAdminMessages() async {
    final existing = await _firestore.getCollection('admin_messages');
    if (existing.isNotEmpty) return;

    final defaultMsgs = [
      {
        'sender': 'Program Director (Admin)',
        'title': 'Welcome to Nexus Applicant Hub!',
        'body': 'Your application submissions are currently being evaluated by our program leads. Keep an eye on your status updates here!',
        'time': '10:30 AM',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'sender': 'Nexus Admissions',
        'title': 'Upcoming Fellowship Cohort Interview Schedule',
        'body': 'Accepted applicants for the UI/UX Fellowship will receive calendar invites for 1-on-1 orientation sessions this Friday.',
        'time': 'Yesterday',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final msg in defaultMsgs) {
      await _firestore.addDocument('admin_messages', msg);
    }
  }
}
