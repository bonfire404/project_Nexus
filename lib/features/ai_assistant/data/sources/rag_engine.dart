import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/assistant_response.dart';

class KnowledgeChunk {
  final String id;
  final String title;
  final String content;
  final List<String> keywords;
  final String? actionLabel;
  final String? actionRoute;

  const KnowledgeChunk({
    required this.id,
    required this.title,
    required this.content,
    required this.keywords,
    this.actionLabel,
    this.actionRoute,
  });
}

class NexusRagEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pre-indexed static knowledge corpus
  static const List<KnowledgeChunk> _corpus = [
    KnowledgeChunk(
      id: 'greeting',
      title: 'Greeting',
      content: "Hello 👋 I'm Nexus Assistant.\n\nHow can I help you today? You can ask me about meetings, deliverables, announcements, programs, or your account.",
      keywords: ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'greeting', 'who'],
    ),
    KnowledgeChunk(
      id: 'meetings_schedule',
      title: 'Meetings & Live Sessions',
      content:
          'Internship meetings, mentor Q&A sessions, and team syncs are conducted weekly. You can view all upcoming live sessions, join links, and calendar schedules directly in your Schedule module.',
      keywords: ['meeting', 'schedule', 'zoom', 'meet', 'session', 'class', 'calendar', 'time', 'when'],
      actionLabel: 'View Schedule',
      actionRoute: '/schedule',
    ),
    KnowledgeChunk(
      id: 'deliverables_tasks',
      title: 'Deliverables & Tasks',
      content:
          'Deliverables represent your weekly project milestones, coding assignments, and report submissions. Make sure to check due dates and submit work before deadlines to maintain your score.',
      keywords: ['deliverable', 'task', 'deadline', 'assignment', 'submit', 'submission', 'due', 'milestone'],
      actionLabel: 'Open Deliverables',
      actionRoute: '/deliverables',
    ),
    KnowledgeChunk(
      id: 'announcements_news',
      title: 'Announcements & News Updates',
      content:
          'Official program updates, mentor announcements, and grading releases are posted regularly on your Dashboard announcement feed.',
      keywords: ['announcement', 'news', 'update', 'feed', 'notice', 'release', 'alert'],
      actionLabel: 'View Dashboard',
      actionRoute: '/dashboard',
    ),
    KnowledgeChunk(
      id: 'programs_internships',
      title: 'Internship Programs & Tracks',
      content:
          'Excelerate Nexus offers tracks in Full-Stack Software Engineering, AI/ML, UI/UX Design, and Data Analytics. You can explore prerequisites, requirements, and apply for open tracks.',
      keywords: ['program', 'internship', 'track', 'course', 'apply', 'enrolled', 'learning', 'tech'],
      actionLabel: 'Browse Programs',
      actionRoute: '/programs',
    ),
    KnowledgeChunk(
      id: 'account_profile',
      title: 'Account Settings & Profile',
      content:
          'Manage your personal details, update profile picture avatar, switch app color themes (Dark/Light mode), and adjust notification preferences in Settings.',
      keywords: ['account', 'profile', 'password', 'setting', 'theme', 'dark mode', 'avatar', 'picture', 'email'],
      actionLabel: 'Open Settings',
      actionRoute: '/settings',
    ),
    KnowledgeChunk(
      id: 'help_faq',
      title: 'Support & Help Desk',
      content:
          'I can assist you with schedule timings, task submission guidelines, program enrollment, or general platform support.',
      keywords: ['help', 'faq', 'support', 'question', 'nexus', 'assistant', 'ai', 'bot', 'how'],
    ),
  ];

  /// RAG Retrieval & Synthesis Pipeline
  Future<AssistantResponse> query(String userMessage) async {
    final queryText = userMessage.trim().toLowerCase();
    if (queryText.isEmpty) {
      return const AssistantResponse(
        message: "Hello! How can I assist you with Excelerate Nexus today?",
      );
    }

    // 1. Retrieve Live Real-Time Context from Firestore
    final liveContext = await _retrieveLiveFirestoreContext(queryText);

    // 2. Perform Term Relevance Retrieval over Knowledge Corpus
    final scoredChunks = <MapEntry<KnowledgeChunk, double>>[];
    final queryTokens = _tokenize(queryText);

    for (final chunk in _corpus) {
      double score = 0.0;
      final chunkText = '${chunk.title} ${chunk.content} ${chunk.keywords.join(' ')}'.toLowerCase();

      for (final token in queryTokens) {
        if (chunkText.contains(token)) {
          score += 1.5;
        }
        for (final kw in chunk.keywords) {
          if (kw == token) {
            score += 3.0; // Exact keyword match boost
          } else if (kw.contains(token) || token.contains(kw)) {
            score += 1.0;
          }
        }
      }

      if (queryText.contains(chunk.title.toLowerCase())) {
        score += 5.0;
      }

      if (score > 0) {
        scoredChunks.add(MapEntry(chunk, score));
      }
    }

    scoredChunks.sort((a, b) => b.value.compareTo(a.value));

    // 3. Synthesis Layer (Combine Live Context & Retrieved Knowledge)
    if (liveContext != null && liveContext.isNotEmpty) {
      final topChunk = scoredChunks.isNotEmpty ? scoredChunks.first.key : null;
      return AssistantResponse(
        message: liveContext,
        actionLabel: topChunk?.actionLabel,
        actionRoute: topChunk?.actionRoute,
      );
    }

    if (scoredChunks.isNotEmpty) {
      final bestMatch = scoredChunks.first.key;
      return AssistantResponse(
        message: '${bestMatch.title}\n\n${bestMatch.content}',
        actionLabel: bestMatch.actionLabel,
        actionRoute: bestMatch.actionRoute,
      );
    }

    // Professional Fallback Response
    return const AssistantResponse(
      message:
          "I couldn't find an exact match for your inquiry. Feel free to ask about meetings, deliverables, announcements, programs, or account settings!",
    );
  }

  /// Live Context Retrieval from Firestore Database
  Future<String?> _retrieveLiveFirestoreContext(String queryText) async {
    try {
      if (queryText.contains('meeting') || queryText.contains('session') || queryText.contains('when')) {
        final snap = await _firestore.collection('meetings').limit(3).get();
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first.data();
          final title = doc['title'] ?? 'Team Sync Meeting';
          final date = doc['date'] ?? doc['time'] ?? 'Upcoming Session';
          final link = doc['link'] ?? 'Available in Schedule module';
          return "📅 Upcoming Meeting:\n\nTitle: $title\nTime/Date: $date\nJoin Link: $link";
        }
      }

      if (queryText.contains('deliverable') || queryText.contains('task') || queryText.contains('due')) {
        final snap = await _firestore.collection('tasks').limit(3).get();
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first.data();
          final title = doc['title'] ?? doc['name'] ?? 'Project Milestone';
          final dueDate = doc['dueDate'] ?? doc['deadline'] ?? 'This Week';
          return "📄 Current Deliverable:\n\nTask: $title\nDeadline: $dueDate\n\nPlease ensure your work is submitted prior to the deadline.";
        }
      }

      if (queryText.contains('announcement') || queryText.contains('news')) {
        final snap = await _firestore.collection('announcements').limit(3).get();
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first.data();
          final title = doc['title'] ?? 'Program Update';
          final content = doc['content'] ?? doc['description'] ?? 'Check Dashboard feed for details.';
          return "📢 Latest Announcement:\n\n$title\n\n$content";
        }
      }
    } catch (_) {
      // Graceful fallback if offline/permission issue
    }
    return null;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
  }
}
