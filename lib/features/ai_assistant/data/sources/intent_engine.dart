enum AssistantIntent {
  greeting,
  meeting,
  deliverables,
  announcements,
  programs,
  account,
  faq,
  unknown,
}

class IntentEngine {
  static final Map<AssistantIntent, List<String>> _keywords = {
    AssistantIntent.greeting: [
      'hi',
      'hello',
      'hey',
      'good morning',
      'good afternoon',
    ],

    AssistantIntent.meeting: [
      'meeting',
      'zoom',
      'google meet',
      'session',
      'class',
      'orientation',
    ],

    AssistantIntent.deliverables: [
      'deliverable',
      'deadline',
      'task',
      'assignment',
      'submit',
      'submission',
      'due',
    ],

    AssistantIntent.announcements: [
      'announcement',
      'news',
      'update',
    ],

    AssistantIntent.programs: [
      'program',
      'internship',
      'track',
      'course',
    ],

    AssistantIntent.account: [
      'account',
      'password',
      'login',
      'profile',
    ],

    AssistantIntent.faq: [
      'help',
      'faq',
      'question',
      'support',
    ],
  };

  AssistantIntent detectIntent(String message) {
    final input = message.toLowerCase();

    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (input.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return AssistantIntent.unknown;
  }
}