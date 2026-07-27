import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nexus/core/services/firestore_service.dart';
import 'package:nexus/core/utils/avatar_utils.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Universal Real-Time Messaging Screen supporting ALL Roles (Applicant, Intern, Administrator).
class MessagesScreen extends StatefulWidget {
  final AuthController authController;

  const MessagesScreen({super.key, required this.authController});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirestoreService _firestore = FirestoreService();
  final UserFirestoreRepository _userRepo = UserFirestoreRepository();
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _messages = [];

  String get currentUserId => widget.authController.currentUser?.uid ?? '';
  String get currentUserEmail => widget.authController.userEmail;

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
  }

  void _subscribeToMessages() {
    _messagesSubscription = _firestore.streamCollection('messages').listen(
      (allMsgs) {
        if (mounted) {
          final userMsgs = allMsgs.where((m) {
            final senderId = m['senderId'] as String? ?? '';
            final recipientId = m['recipientId'] as String? ?? '';
            final senderEmail = (m['senderEmail'] as String? ?? '').toLowerCase();
            final recipientEmail = (m['recipientEmail'] as String? ?? '').toLowerCase();

            return senderId == currentUserId ||
                recipientId == currentUserId ||
                senderEmail == currentUserEmail.toLowerCase() ||
                recipientEmail == currentUserEmail.toLowerCase() ||
                recipientId == 'all' ||
                recipientId == widget.authController.selectedRole?.label;
          }).toList();

          userMsgs.sort((a, b) {
            final tA = a['timestamp'] as String? ?? '';
            final tB = b['timestamp'] as String? ?? '';
            return tB.compareTo(tA);
          });

          setState(() {
            _messages = userMsgs;
            _isLoading = false;
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMessages {
    if (_searchQuery.isEmpty) return _messages;
    final q = _searchQuery.toLowerCase();
    return _messages.where((m) {
      final subject = (m['subject'] as String? ?? '').toLowerCase();
      final body = (m['body'] as String? ?? m['content'] as String? ?? '').toLowerCase();
      final sender = (m['senderName'] as String? ?? '').toLowerCase();
      return subject.contains(q) || body.contains(q) || sender.contains(q);
    }).toList();
  }

  void _showNewMessageSheet() async {
    final theme = Theme.of(context);
    final recipientController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    List<Map<String, dynamic>> availableUsers = [];
    try {
      availableUsers = await _userRepo.getAllUsers();
    } catch (_) {}

    String selectedRecipientId = availableUsers.isNotEmpty
        ? (availableUsers.first['id'] as String? ?? availableUsers.first['uid'] as String? ?? '')
        : '';
    String selectedRecipientName = availableUsers.isNotEmpty
        ? (availableUsers.first['name'] as String? ?? 'User')
        : 'All';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'New Message',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Kameron',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              if (availableUsers.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedRecipientId,
                  decoration: const InputDecoration(labelText: 'Recipient'),
                  items: availableUsers.map((u) {
                    final uId = u['id'] as String? ?? u['uid'] as String? ?? '';
                    final uName = u['name'] as String? ?? 'User';
                    final uRole = u['role'] as String? ?? '';
                    return DropdownMenuItem(
                      value: uId,
                      child: Text('$uName ($uRole)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final match = availableUsers.firstWhere(
                        (u) => (u['id'] ?? u['uid']) == val,
                        orElse: () => {},
                      );
                      setSheetState(() {
                        selectedRecipientId = val;
                        selectedRecipientName = match['name'] as String? ?? 'User';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                TextField(
                  controller: recipientController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Email / ID',
                    hintText: 'admin@nexus.com',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. Mentor Sync / Deliverable Review',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  hintText: 'Type your message...',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send Message'),
                  onPressed: () async {
                    final subject = subjectController.text.trim();
                    final body = bodyController.text.trim();
                    if (subject.isEmpty || body.isEmpty) return;

                    Navigator.pop(ctx);
                    try {
                      await _firestore.addDocument('messages', {
                        'senderId': currentUserId,
                        'senderEmail': currentUserEmail,
                        'senderName': widget.authController.userDisplayName,
                        'recipientId': selectedRecipientId.isNotEmpty
                            ? selectedRecipientId
                            : recipientController.text.trim(),
                        'recipientName': selectedRecipientName,
                        'subject': subject,
                        'body': body,
                        'timestamp': DateTime.now().toIso8601String(),
                      });
                      if (mounted) {
                        showGlassSnackbar(
                          context,
                          'Message sent successfully!',
                          type: SnackbarType.success,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        showGlassSnackbar(
                          context,
                          'Error sending message: $e',
                          type: SnackbarType.error,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageDetail(Map<String, dynamic> msg) {
    final theme = Theme.of(context);
    final docId = msg['id'] as String? ?? '';
    final subject = msg['subject'] as String? ?? 'Message';
    final body = msg['body'] as String? ?? msg['content'] as String? ?? '';
    final sender = msg['senderName'] as String? ?? 'Nexus User';
    final timestamp = msg['timestamp'] as String? ?? '';
    final recipientId = msg['recipientId'] as String? ?? '';
    final recipientEmail = (msg['recipientEmail'] as String? ?? '').toLowerCase();
    final isRead = msg['isRead'] as bool? ?? false;

    final isForMe = (currentUserId.isNotEmpty && recipientId == currentUserId) ||
        (currentUserEmail.isNotEmpty && recipientEmail == currentUserEmail.toLowerCase());

    if (isForMe && !isRead && docId.isNotEmpty) {
      _firestore.updateDocument('messages', docId, {'isRead': true, 'status': 'read'});
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AvatarUtils.buildAvatarWidget(
                  'preset_1',
                  radius: 20,
                  fallbackLetter: sender,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timestamp.isNotEmpty ? timestamp.split('T')[0] : 'Recent',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              subject,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Reply'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showNewMessageSheet();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredMessages;

    return Skeletonizer(
      enabled: _isLoading,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Messages & Inbox',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Kameron',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_square),
                  tooltip: 'New Message',
                  onPressed: _showNewMessageSheet,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? _buildChatTilesSkeleton(theme)
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedMail01,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No messages in your inbox.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showNewMessageSheet,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('New Message'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                        final msg = filtered[index];
                        final sender = msg['senderName'] as String? ?? 'Sender';
                        final subject = msg['subject'] as String? ?? 'No Subject';
                        final body = msg['body'] as String? ?? msg['content'] as String? ?? '';
                        final isRead = msg['isRead'] as bool? ?? false;
                        final recipientId = msg['recipientId'] as String? ?? '';
                        final recipientEmail = (msg['recipientEmail'] as String? ?? '').toLowerCase();

                        final isForMe = (currentUserId.isNotEmpty && recipientId == currentUserId) ||
                            (currentUserEmail.isNotEmpty && recipientEmail == currentUserEmail.toLowerCase());
                        final isUnread = isForMe && !isRead;

                        return GestureDetector(
                          onTap: () => _showMessageDetail(msg),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnread
                                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                                width: isUnread ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                AvatarUtils.buildAvatarWidget(
                                  'preset_1',
                                  radius: 20,
                                  fallbackLetter: sender,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sender,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                          color: isUnread ? theme.colorScheme.onSurface : null,
                                        ),
                                      ),
                                      Text(
                                        body,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                                          color: isUnread
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTilesSkeleton(ThemeData theme) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final isEven = index % 2 == 0;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Bone.circle(size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Bone.text(width: isEven ? 130 : 100),
                          Bone.text(width: 38),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Bone.text(width: isEven ? 160 : 120),
                      const SizedBox(height: 4),
                      Bone.text(width: isEven ? 210 : 170),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
