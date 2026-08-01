import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../data/repositories/ai_repository_impl.dart';
import '../providers/chat_provider.dart';
import '../widgets/assistant_avatar.dart';
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

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    provider = ChatProvider(
      repository: AIRepositoryImpl(),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final suggestions = [
      {
        'label': 'Next Meeting',
        'icon': HugeIcons.strokeRoundedCalendar01,
        'query': 'Next Meeting',
      },
      {
        'label': 'Deliverables',
        'icon': HugeIcons.strokeRoundedFile01,
        'query': 'Deliverables',
      },
      {
        'label': 'Announcements',
        'icon': HugeIcons.strokeRoundedNotification01,
        'query': 'Announcements',
      },
      {
        'label': 'Programs',
        'icon': Icons.school_rounded,
        'query': 'Programs',
        'isHugeIcon': false,
      },
      {
        'label': 'Help',
        'icon': Icons.help_outline_rounded,
        'query': 'Help',
        'isHugeIcon': false,
      },
    ];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const AssistantAvatar(radius: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Nexus AI Assistant",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Online • Always ready to help",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: 22,
              color: isDark ? Colors.grey[300] : const Color(0xFF0F172A),
            ),
            tooltip: "New conversation",
            onPressed: () {
              provider.clearConversation();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Suggestions",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: suggestions.length,
              itemBuilder: (_, index) {
                final item = suggestions[index];
                return SuggestionChip(
                  label: item['label'] as String,
                  icon: item['icon'],
                  isHugeIcon: item['isHugeIcon'] as bool? ?? true,
                  onTap: () {
                    provider.sendMessage(
                      item['query'] as String,
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
              builder: (_, messages, child) {
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
            builder: (_, typing, child) {
              if (!typing) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  bottom: 12,
                  top: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AssistantAvatar(
                          radius: 14, showOnlineBadge: false),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: const TypingIndicator(),
                      ),
                    ],
                  ),
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