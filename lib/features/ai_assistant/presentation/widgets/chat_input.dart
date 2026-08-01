import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
  });

  final ValueChanged<String> onSend;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      final hasText = controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => send(),
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: "Ask about meetings, tasks, announcements...",
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasText
                      ? theme.colorScheme.primary
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0)),
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSent,
                    size: 20,
                    color: _hasText
                        ? Colors.white
                        : (isDark ? Colors.grey[600]! : Colors.grey[500]!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}