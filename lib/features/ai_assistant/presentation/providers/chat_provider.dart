import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_repository.dart';

class ChatProvider {
 ChatProvider({
  required AIRepository repository,
}) : _repository = repository {
  messages.value = [
    ChatMessage(
      id: "welcome",
      message:
          "👋 Hello! I'm Nexus Assistant.\n\nI can help you with meetings, deliverables, announcements, programs, and account questions.\n\nHow can I help you today?",
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
    ),
  ];
}

  final AIRepository _repository;

  final ValueNotifier<List<ChatMessage>> messages =
      ValueNotifier<List<ChatMessage>>([]);

  final ValueNotifier<bool> isTyping =
      ValueNotifier(false);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.value = [
      ...messages.value,
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: text,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
    ];

    isTyping.value = true;

    final response = await _repository.getResponse(text);

    isTyping.value = false;

    messages.value = [
      ...messages.value,
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: response.message,
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void clearConversation() {
    messages.value = [];
  }

  void dispose() {
    messages.dispose();
    isTyping.dispose();
  }
}