import 'package:flutter/material.dart';

import '../../data/repositories/ai_repository_impl.dart';
import '../../data/sources/intent_engine.dart';
import '../../data/sources/knowledge_source.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/suggestion_chip.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatProvider provider;

  final ScrollController scrollController =
      ScrollController();

  @override
  void initState() {
    super.initState();

    provider = ChatProvider(
      repository: AIRepositoryImpl(
        intentEngine: IntentEngine(),
        knowledgeSource: KnowledgeSource(),
      ),
    );

    provider.messages.addListener(scrollToBottom);
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    provider.messages.removeListener(scrollToBottom);
    provider.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = [
        "📅 Next Meeting",
        "📄 Deliverables",
        "📢 Announcements",
        "🎓 Programs",
        "❓ Help",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nexus Assistant"),
            Text(
              "Always here to help",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear chat",
            onPressed: () {
              provider.clearConversation();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: suggestions.length,
              itemBuilder: (_, index) {
                return SuggestionChip(
                  label: suggestions[index],
                  onTap: () {
                    provider.sendMessage(
                      suggestions[index],
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: provider.messages,
              builder: (_, messages, __) {
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    return MessageBubble(
                      message: messages[index],
                    );
                  },
                );
              },
            ),
          ),

          ValueListenableBuilder(
            valueListenable: provider.isTyping,
            builder: (_, typing, __) {
              if (!typing) return const SizedBox();

              return const Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  bottom: 10,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TypingIndicator(),
                ),
              );
            },
          ),

          ChatInput(
            onSend: provider.sendMessage,
          ),
        ],
      ),
    );
  }
}