import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nexus/core/services/firestore_service.dart';
import 'package:nexus/core/utils/avatar_utils.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Messenger-Style Floating Chat Bottom Sheet with Real-Time Threads & Bubbles.
class MessengerChatSheet extends StatefulWidget {
  final AuthController authController;

  const MessengerChatSheet({super.key, required this.authController});

  @override
  State<MessengerChatSheet> createState() => _MessengerChatSheetState();
}

class _MessengerChatSheetState extends State<MessengerChatSheet> with TickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  final UserFirestoreRepository _userRepo = UserFirestoreRepository();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AnimationController? _logoSpinController;
  bool _isSending = false;

  AnimationController _getSpinController() {
    _logoSpinController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    return _logoSpinController!;
  }

  StreamSubscription<List<Map<String, dynamic>>>? _chatSubscription;
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _localPendingMessages = [];
  Map<String, dynamic>? _selectedContact;
  bool _isLoadingContacts = true;
  bool _isLoadingThreadMessages = false;

  // Inline edit state
  String? _editingDocId;
  String? _editingOriginalText;

  // Reply message state
  Map<String, dynamic>? _replyingToMessage;

  // Reaction lock set to prevent spam reaction taps
  final Set<String> _processingReactionDocIds = {};

  // Context menu state (scoped to chat UI)
  Map<String, dynamic>? _contextMenuMsg;
  bool _contextMenuIsMe = false;

  // Real-time All Messages stream for unread badges & preview
  StreamSubscription<List<Map<String, dynamic>>>? _allMessagesSubscription;
  List<Map<String, dynamic>> _allMessages = [];

  // Real-time Network Awareness state
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String get currentUserId => widget.authController.currentUser?.uid ?? '';
  String get currentUserEmail => widget.authController.userEmail;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _getSpinController();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
      _scrollToBottom();
    });
    _loadPreferences();
    _loadContacts();
    _initConnectivity();
    _subscribeToAllMessages();
  }

  void _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectivityStatus(results);
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectivityStatus);
    } catch (_) {}
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    if (mounted && _isOffline != isOffline) {
      setState(() {
        _isOffline = isOffline;
      });

      if (!isOffline) {
        _autoResendFailedMessages();
        if (_selectedContact != null) {
          _subscribeToChat();
        }
      }
    }
  }

  void _autoResendFailedMessages() {
    final failedMsgs = List<Map<String, dynamic>>.from(
      _localPendingMessages.where((m) => m['status'] == 'failed'),
    );
    for (final msg in failedMsgs) {
      final tempId = msg['tempId'] as String? ?? '';
      final text = msg['body'] as String? ?? '';
      if (text.isNotEmpty) {
        _sendMessage(retryText: text, failedTempId: tempId);
      }
    }
  }

  final Set<String> _notifiedMessageIds = {};

  void _subscribeToAllMessages() {
    _allMessagesSubscription?.cancel();
    _allMessagesSubscription = _firestore.streamCollection('messages').listen((msgs) {
      if (mounted) {
        final myId = currentUserId;
        final myEmail = currentUserEmail.toLowerCase();

        for (final m in msgs) {
          final mId = m['id'] as String? ?? '';
          final rId = m['recipientId'] as String? ?? '';
          final rEmail = (m['recipientEmail'] as String? ?? '').toLowerCase();
          final sId = m['senderId'] as String? ?? '';
          final sEmail = (m['senderEmail'] as String? ?? '').toLowerCase();
          final isRead = m['isRead'] as bool? ?? false;
          final tsStr = m['timestamp'] as String? ?? '';
          final senderName = m['senderName'] as String? ?? 'New Message';
          final body = m['body'] as String? ?? m['content'] as String? ?? '';

          final isForMe = (myId.isNotEmpty && rId == myId) || (myEmail.isNotEmpty && rEmail == myEmail);
          final isFromOther = (myId.isEmpty || sId != myId) && (myEmail.isEmpty || sEmail != myEmail);

          if (isForMe && isFromOther && !isRead && mId.isNotEmpty && !_notifiedMessageIds.contains(mId)) {
            final ts = DateTime.tryParse(tsStr);
            if (ts != null && DateTime.now().difference(ts).inSeconds <= 15) {
              _notifiedMessageIds.add(mId);
              NotificationService().showChatPushNotification(
                senderName: senderName,
                messageText: body,
              );
            }
          }
        }

        _markMessagesAsRead(msgs);

        setState(() {
          _allMessages = msgs;
        });
      }
    });
  }

  Map<String, dynamic>? _getLastMessageForContact(String contactId, String contactEmail) {
    final cEmail = contactEmail.toLowerCase();
    final myId = currentUserId;
    final myEmail = currentUserEmail.toLowerCase();

    final relevantMsgs = _allMessages.where((m) {
      final sId = m['senderId'] as String? ?? '';
      final sEmail = (m['senderEmail'] as String? ?? '').toLowerCase();
      final rId = m['recipientId'] as String? ?? '';
      final rEmail = (m['recipientEmail'] as String? ?? '').toLowerCase();

      if (contactId == 'excelerate_general') {
        final isGen = m['isGeneral'] as bool? ?? false;
        final isBroad = m['isBroadcast'] as bool? ?? false;
        final target = m['targetAudience'] as String? ?? m['target'] as String? ?? 'All Users';
        final userRoleEnum = widget.authController.selectedRole;
        final userRoleName = userRoleEnum != null ? userRoleEnum.name.toLowerCase() : '';

        bool matchesTarget = true;
        if (target == 'Interns') {
          matchesTarget = userRoleName == 'intern' || userRoleName == 'administrator';
        } else if (target == 'Applicants') {
          matchesTarget = userRoleName == 'applicant' || userRoleName == 'administrator';
        }

        final isChannelMsg = rId == 'general' || rId == 'all' || sId == 'excelerate_general' || isGen || isBroad;
        return isChannelMsg && matchesTarget;
      }

      final isMeSender = (myId.isNotEmpty && sId == myId) || (myEmail.isNotEmpty && sEmail == myEmail);
      final isMeRecipient = (myId.isNotEmpty && rId == myId) || (myEmail.isNotEmpty && rEmail == myEmail);

      final isContactSender = (contactId.isNotEmpty && sId == contactId) || (cEmail.isNotEmpty && sEmail == cEmail);
      final isContactRecipient = (contactId.isNotEmpty && rId == contactId) || (cEmail.isNotEmpty && rEmail == cEmail);

      return (isMeSender && isContactRecipient) || (isContactSender && isMeRecipient);
    }).toList();

    if (relevantMsgs.isEmpty) return null;

    relevantMsgs.sort((a, b) {
      final tA = a['timestamp'] as String? ?? '';
      final tB = b['timestamp'] as String? ?? '';
      return tB.compareTo(tA);
    });

    return relevantMsgs.first;
  }

  int _getUnreadCountForContact(String contactId, String contactEmail) {
    final cEmail = contactEmail.toLowerCase();
    final myId = currentUserId;
    final myEmail = currentUserEmail.toLowerCase();

    return _allMessages.where((m) {
      final sId = m['senderId'] as String? ?? '';
      final sEmail = (m['senderEmail'] as String? ?? '').toLowerCase();
      final rId = m['recipientId'] as String? ?? '';
      final rEmail = (m['recipientEmail'] as String? ?? '').toLowerCase();
      final isRead = m['isRead'] as bool? ?? false;

      final isFromContactToMe = ((contactId.isNotEmpty && sId == contactId) || (cEmail.isNotEmpty && sEmail == cEmail)) &&
          ((myId.isNotEmpty && rId == myId) || (myEmail.isNotEmpty && rEmail == myEmail));

      return isFromContactToMe && !isRead;
    }).length;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
      setState(() => _showEmojiPicker = false);
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _showEmojiPicker = true);
    }
    _scrollToBottom();
  }

  Future<void> _loadContacts() async {
    try {
      final allUsers = await _userRepo.getAllUsers();
      final otherUsers = allUsers.where((u) {
        final email = (u['email'] as String? ?? '').toLowerCase();
        final uid = u['id'] as String? ?? u['uid'] as String? ?? '';
        return email != currentUserEmail.toLowerCase() && uid != currentUserId && uid != 'excelerate_general';
      }).toList();

      final generalChannel = <String, dynamic>{
        'id': 'nexus_announcement',
        'uid': 'nexus_announcement',
        'name': 'Nexus Announcement',
        'email': 'announcement@nexus.com',
        'role': 'Official Channel',
        'avatar': 'assets/icons/app_logo.png',
        'isOfficialChannel': true,
        'status': 'Active',
      };

      if (mounted) {
        setState(() {
          _contacts = [generalChannel, ...otherUsers];
          _isLoadingContacts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() {
        _isLoadingContacts = true;
      });
    }
    await _loadContacts();
    _subscribeToAllMessages();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isLoadingContacts = false;
      });
    }
  }

  bool _isPartnerTyping = false;
  Timer? _typingDebounceTimer;
  StreamSubscription? _typingSubscription;

  void _subscribeToChat() {
    _chatSubscription?.cancel();
    _subscribeToTypingStatus();
    if (_selectedContact == null) return;

    setState(() => _isLoadingThreadMessages = true);

    final targetId = (_selectedContact!['id'] as String? ?? _selectedContact!['uid'] as String? ?? '').toLowerCase();
    final targetEmail = (_selectedContact!['email'] as String? ?? '').toLowerCase();
    final targetName = (_selectedContact!['name'] as String? ?? '').toLowerCase();

    final myId = currentUserId.toLowerCase();
    final myEmail = currentUserEmail.toLowerCase();
    final myName = (widget.authController.userDisplayName).toLowerCase();

    final isOfficial = targetId == 'excelerate_general' ||
        targetEmail == 'general@excelerate.com' ||
        (_selectedContact!['isOfficialChannel'] as bool? ?? false);

    _chatSubscription = _firestore.streamCollection('messages').listen(
      (allMsgs) {
        if (mounted) {
          final chatMsgs = allMsgs.where((m) {
            if (isOfficial) {
              final rId = (m['recipientId'] as String? ?? '').toLowerCase();
              final sId = (m['senderId'] as String? ?? '').toLowerCase();
              final isGen = m['isGeneral'] as bool? ?? false;
              final isBroad = m['isBroadcast'] as bool? ?? false;
              final target = m['targetAudience'] as String? ?? m['target'] as String? ?? 'All Users';

              final userRoleEnum = widget.authController.selectedRole;
              final userRoleName = userRoleEnum != null ? userRoleEnum.name.toLowerCase() : '';

              bool matchesTarget = true;
              if (target == 'Interns') {
                matchesTarget = userRoleName == 'intern' || userRoleName == 'administrator';
              } else if (target == 'Applicants') {
                matchesTarget = userRoleName == 'applicant' || userRoleName == 'administrator';
              }

              final isChannelMsg = rId == 'general' || rId == 'all' || sId == 'excelerate_general' || isGen || isBroad;
              return isChannelMsg && matchesTarget;
            }

            final sId = (m['senderId'] as String? ?? '').toLowerCase();
            final sEmail = (m['senderEmail'] as String? ?? '').toLowerCase();
            final sName = (m['senderName'] as String? ?? '').toLowerCase();

            final rId = (m['recipientId'] as String? ?? '').toLowerCase();
            final rEmail = (m['recipientEmail'] as String? ?? '').toLowerCase();
            final rName = (m['recipientName'] as String? ?? '').toLowerCase();

            final isSenderMe = (myId.isNotEmpty && (sId == myId || sEmail == myId)) ||
                (myEmail.isNotEmpty && (sEmail == myEmail || sId == myEmail)) ||
                (myName.isNotEmpty && sName.isNotEmpty && sName == myName);

            final isSenderTarget = (targetId.isNotEmpty && (sId == targetId || sEmail == targetId)) ||
                (targetEmail.isNotEmpty && (sEmail == targetEmail || sId == targetEmail)) ||
                (targetName.isNotEmpty && sName.isNotEmpty && sName == targetName);

            final isRecipientMe = (myId.isNotEmpty && (rId == myId || rEmail == myId)) ||
                (myEmail.isNotEmpty && (rEmail == myEmail || rId == myEmail)) ||
                (myName.isNotEmpty && rName.isNotEmpty && rName == myName);

            final isRecipientTarget = (targetId.isNotEmpty && (rId == targetId || rEmail == targetId)) ||
                (targetEmail.isNotEmpty && (rEmail == targetEmail || rId == targetEmail)) ||
                (targetName.isNotEmpty && rName.isNotEmpty && rName == targetName);

            final fromMeToTarget = isSenderMe && isRecipientTarget;
            final fromTargetToMe = isSenderTarget && isRecipientMe;

            return fromMeToTarget || fromTargetToMe;
          }).toList();

          chatMsgs.sort((a, b) {
            final tA = a['timestamp'] as String? ?? '';
            final tB = b['timestamp'] as String? ?? '';
            return tA.compareTo(tB);
          });

          _markMessagesAsRead(chatMsgs);

          setState(() {
            _messages = chatMsgs;
            _isLoadingThreadMessages = false;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
    );
  }

  void _onTypingChanged(String text) {
    if (_selectedContact == null) return;
    final targetId = _selectedContact!['id'] as String? ?? _selectedContact!['uid'] as String? ?? '';
    if (targetId.isEmpty) return;

    _updateTypingStatus(targetId, text.isNotEmpty);

    _typingDebounceTimer?.cancel();
    if (text.isNotEmpty) {
      _typingDebounceTimer = Timer(const Duration(seconds: 3), () {
        _updateTypingStatus(targetId, false);
      });
    }
  }

  Future<void> _updateTypingStatus(String targetId, bool isTyping) async {
    try {
      final docId = '${currentUserId}_$targetId';
      await _firestore.setDocument('typing_status', docId, {
        'isTyping': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void _subscribeToTypingStatus() {
    _typingSubscription?.cancel();
    if (_selectedContact == null) {
      setState(() => _isPartnerTyping = false);
      return;
    }
    final targetId = _selectedContact!['id'] as String? ?? _selectedContact!['uid'] as String? ?? '';
    if (targetId.isEmpty) return;

    final docId = '${targetId}_$currentUserId';
    _typingSubscription = _firestore.streamDocument('typing_status', docId).listen((doc) {
      if (mounted) {
        final isTyping = doc['isTyping'] as bool? ?? false;
        final tsStr = doc['timestamp'] as String? ?? '';
        bool fresh = false;
        if (tsStr.isNotEmpty) {
          final ts = DateTime.tryParse(tsStr);
          if (ts != null && DateTime.now().difference(ts).inSeconds <= 6) {
            fresh = true;
          }
        }
        setState(() => _isPartnerTyping = isTyping && fresh);
      }
    });
  }

  void _markMessagesAsRead(List<Map<String, dynamic>> msgs) {
    for (final m in msgs) {
      final recipientId = m['recipientId'] as String? ?? '';
      final recipientEmail = (m['recipientEmail'] as String? ?? '').toLowerCase();
      final isRead = m['isRead'] as bool? ?? false;
      final docId = m['id'] as String? ?? '';

      final isForMe = (currentUserId.isNotEmpty && recipientId == currentUserId) ||
          (currentUserEmail.isNotEmpty && recipientEmail == currentUserEmail.toLowerCase());
      if (isForMe && !isRead && docId.isNotEmpty) {
        _firestore.updateDocument('messages', docId, {
          'isRead': true,
          'status': 'read',
        });
      }
    }
  }

  final PageController _emojiPageController = PageController();

  @override
  void dispose() {
    _logoSpinController?.dispose();
    _logoSpinController = null;
    _allMessagesSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _typingDebounceTimer?.cancel();
    _typingSubscription?.cancel();
    _focusNode.dispose();
    _emojiPageController.dispose();
    _chatSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startInlineEdit(String docId, String currentBody) {
    setState(() {
      _editingDocId = docId;
      _editingOriginalText = currentBody;
      _textController.text = currentBody;
      _textController.selection = TextSelection.collapsed(offset: currentBody.length);
    });
    _focusNode.requestFocus();
  }

  void _cancelInlineEdit() {
    setState(() {
      _editingDocId = null;
      _editingOriginalText = null;
      _textController.clear();
    });
  }

  Future<void> _submitInlineEdit() async {
    final newText = _textController.text.trim();
    final docId = _editingDocId;
    if (newText.isEmpty || docId == null || docId.isEmpty) return;
    if (newText == _editingOriginalText) {
      _cancelInlineEdit();
      return;
    }
    setState(() {
      _editingDocId = null;
      _editingOriginalText = null;
      _textController.clear();
    });
    try {
      await _firestore.updateDocument('messages', docId, {
        'body': newText,
        'isEdited': true,
      });
      if (mounted) {
        showGlassSnackbar(context, 'Message updated', type: SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackbar(context, 'Error editing message: $e', type: SnackbarType.error);
      }
    }
  }

  /// Check if a message can be edited/unsent.
  /// Allowed within 60 seconds of sending even if read, as long as the recipient has not replied after it.
  bool _canEditOrUnsend(Map<String, dynamic> msg) {
    final isUnsent = msg['isUnsent'] as bool? ?? false;
    if (isUnsent) return false;

    final msgTimestamp = msg['timestamp'] as String? ?? '';
    final senderId = msg['senderId'] as String? ?? '';

    // Check 60-second window
    final ts = DateTime.tryParse(msgTimestamp);
    if (ts != null) {
      final elapsedSeconds = DateTime.now().difference(ts).inSeconds;
      if (elapsedSeconds > 60) {
        return false;
      }
    }

    // Check if there's a reply from the other user after this message
    for (final m in _messages) {
      final mSenderId = m['senderId'] as String? ?? '';
      final mTs = m['timestamp'] as String? ?? '';
      if (mSenderId != senderId && mTs.compareTo(msgTimestamp) > 0) {
        return false;
      }
    }
    return true;
  }

  void _showIosMessageContextMenu(Map<String, dynamic> msg, bool isMe) {
    HapticFeedback.mediumImpact();
    setState(() {
      _contextMenuMsg = msg;
      _contextMenuIsMe = isMe;
    });
  }

  void _dismissContextMenu() {
    setState(() {
      _contextMenuMsg = null;
      _contextMenuIsMe = false;
    });
  }

  Future<void> _reactToMessage(String docId, String emoji) async {
    _dismissContextMenu();
    if (docId.isEmpty || _processingReactionDocIds.contains(docId)) return;
    _processingReactionDocIds.add(docId);

    try {
      // Read current reactions
      final doc = await _firestore.getDocument('messages', docId);
      final reactions = Map<String, dynamic>.from(doc?['reactions'] as Map? ?? {});

      // Check if user already reacted with this specific emoji
      final currentUsersForEmoji = List<String>.from(reactions[emoji] as List? ?? []);
      final bool alreadyHasThisEmoji = currentUsersForEmoji.contains(currentUserId);

      // Remove current user's reaction from ALL existing emojis first (Instagram single-emoji policy)
      reactions.forEach((eKey, uList) {
        final list = List<String>.from(uList as List? ?? []);
        list.remove(currentUserId);
        reactions[eKey] = list;
      });

      bool isAddingNewReaction = false;

      if (alreadyHasThisEmoji) {
        // Toggled off their existing reaction for this emoji
        isAddingNewReaction = false;
      } else {
        // Toggle on new emoji: Add current user to this emoji
        final updatedList = List<String>.from(reactions[emoji] as List? ?? []);
        updatedList.add(currentUserId);
        reactions[emoji] = updatedList;
        isAddingNewReaction = true;
      }

      // Clean up empty emoji lists
      reactions.removeWhere((eKey, uList) => (uList as List).isEmpty);

      await _firestore.updateDocument('messages', docId, {'reactions': reactions});

      // If adding a new reaction, create a persistent notification document for the recipient
      if (isAddingNewReaction && doc != null) {
        try {
          final reactorName = widget.authController.userDisplayName;
          final msgBody = doc['body'] as String? ?? doc['content'] as String? ?? '';
          final snippet = msgBody.length > 25 ? '${msgBody.substring(0, 25)}...' : msgBody;

          final msgSenderId = doc['senderId'] as String? ?? '';
          final targetNotifyUserId = (msgSenderId.isNotEmpty && msgSenderId != currentUserId)
              ? msgSenderId
              : (_selectedContact?['id'] as String? ?? _selectedContact?['uid'] as String? ?? '');

          if (targetNotifyUserId.isNotEmpty && targetNotifyUserId != currentUserId) {
            await _firestore.addDocument('notifications', {
              'userId': targetNotifyUserId,
              'senderId': currentUserId,
              'senderName': reactorName,
              'type': 'chat_reaction',
              'title': '$reactorName reacted $emoji to your message',
              'body': '"$snippet"',
              'timestamp': DateTime.now().toIso8601String(),
              'isRead': false,
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackbar(context, 'Error updating reaction: $e', type: SnackbarType.error);
      }
    } finally {
      _processingReactionDocIds.remove(docId);
    }
  }

  Future<void> _sendMessage({String? retryText, String? failedTempId}) async {
    if (_isSending) return;
    final text = retryText ?? _textController.text.trim();
    if (text.isEmpty || _selectedContact == null) return;

    final sendStartTime = DateTime.now().millisecondsSinceEpoch;

    if (retryText == null) {
      _textController.clear();
    }

    if (failedTempId != null) {
      setState(() {
        _localPendingMessages.removeWhere((m) => m['tempId'] == failedTempId);
      });
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final targetId = _selectedContact!['id'] as String? ?? _selectedContact!['uid'] as String? ?? '';
    final targetEmail = _selectedContact!['email'] as String? ?? '';
    final targetName = _selectedContact!['name'] as String? ?? 'User';
    final senderName = widget.authController.userDisplayName;
    final nowStr = DateTime.now().toIso8601String();

    if (_isOffline) {
      final pendingMsg = {
        'tempId': tempId,
        'senderId': currentUserId,
        'senderEmail': currentUserEmail,
        'senderName': senderName,
        'recipientId': targetId,
        'recipientEmail': targetEmail,
        'recipientName': targetName,
        'body': text,
        'isRead': false,
        'status': 'failed',
        'timestamp': nowStr,
      };
      setState(() {
        _localPendingMessages.add(pendingMsg);
      });
      _scrollToBottom();
      showGlassSnackbar(context, 'No network connection. Message marked as failed.', type: SnackbarType.error);
      return;
    }

    final pendingMsg = {
      'tempId': tempId,
      'senderId': currentUserId,
      'senderEmail': currentUserEmail,
      'senderName': senderName,
      'recipientId': targetId,
      'recipientEmail': targetEmail,
      'recipientName': targetName,
      'body': text,
      'isRead': false,
      'status': 'sending',
      'timestamp': nowStr,
    };

    setState(() {
      _localPendingMessages.add(pendingMsg);
      _isSending = true;
    });
    _getSpinController().repeat();
    _scrollToBottom();

    final replyData = _replyingToMessage;
    setState(() {
      _replyingToMessage = null;
    });

    try {
      final isOnline = _isContactOnline(_selectedContact);
      final initialStatus = isOnline ? 'delivered' : 'sent';

      final docData = <String, dynamic>{
        'senderId': currentUserId,
        'senderEmail': currentUserEmail,
        'senderName': senderName,
        'recipientId': targetId,
        'recipientEmail': targetEmail,
        'recipientName': targetName,
        'subject': 'Chat Message',
        'body': text,
        'isRead': false,
        'status': initialStatus,
        'timestamp': nowStr,
      };

      if (replyData != null) {
        docData['replyToId'] = replyData['id'];
        docData['replyToSenderName'] = replyData['senderName'] as String? ?? replyData['senderEmail'] as String? ?? 'User';
        docData['replyToBody'] = replyData['body'] as String? ?? replyData['content'] as String? ?? '';
      }

      await _firestore.addDocument('messages', docData);

      if (mounted) {
        setState(() {
          _localPendingMessages.removeWhere((m) => m['tempId'] == tempId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _localPendingMessages.indexWhere((m) => m['tempId'] == tempId);
          if (idx != -1) {
            _localPendingMessages[idx]['status'] = 'failed';
          }
        });
        showGlassSnackbar(context, 'Failed to send message. Tap message to retry.', type: SnackbarType.error);
      }
    } finally {
      final elapsed = DateTime.now().millisecondsSinceEpoch - sendStartTime;
      if (elapsed < 350) {
        await Future.delayed(Duration(milliseconds: 350 - elapsed));
      }
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _logoSpinController?.stop();
        _logoSpinController?.reset();
      }
    }
  }

  void _showFailedMessageOptions(Map<String, dynamic> msg) {
    final tempId = msg['tempId'] as String? ?? '';
    final text = msg['body'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
                title: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendMessage(retryText: text, failedTempId: tempId);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _localPendingMessages.removeWhere((m) => m['tempId'] == tempId);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(Map<String, dynamic> msg, bool isMe, ThemeData theme) {
    if (!isMe) return const SizedBox.shrink();

    final status = msg['status'] as String? ?? (msg['isRead'] == true ? 'read' : 'sent');

    if (status == 'failed') {
      return GestureDetector(
        onTap: () => _showFailedMessageOptions(msg),
        child: Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                'Not Delivered. Tap to retry',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'sending') {
      return Padding(
        padding: const EdgeInsets.only(top: 2, right: 4),
        child: Text(
          'Sending...',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    String labelText = 'Sent';
    IconData iconData = Icons.check_rounded;
    Color labelColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    if (status == 'read' || msg['isRead'] == true) {
      labelText = 'Read';
      iconData = Icons.done_all_rounded;
      labelColor = theme.colorScheme.primary;
    } else if (status == 'delivered') {
      labelText = 'Delivered';
      iconData = Icons.done_all_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelText,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: labelColor,
              fontWeight: status == 'read' ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 2),
          Icon(iconData, size: 12, color: labelColor),
        ],
      ),
    );
  }

  Widget _buildThreadSkeleton(ThemeData theme) {
    final partnerColor = theme.brightness == Brightness.dark
        ? const Color(0xFF2D2D30)
        : const Color(0xFFE8E8ED);
    final myColor = theme.colorScheme.primary.withValues(alpha: 0.85);

    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Left (partner) bubble 1
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Bone.circle(size: 28),
                const SizedBox(width: 8),
                Container(
                  width: 160,
                  height: 44,
                  decoration: BoxDecoration(
                    color: partnerColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right (me) bubble 2
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 200,
                  height: 52,
                  decoration: BoxDecoration(
                    color: myColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Left (partner) bubble 3
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Bone.circle(size: 28),
                const SizedBox(width: 8),
                Container(
                  width: 220,
                  height: 64,
                  decoration: BoxDecoration(
                    color: partnerColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right (me) bubble 4
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 130,
                  height: 40,
                  decoration: BoxDecoration(
                    color: myColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _showEmojiPicker = false;
  int _selectedEmojiCategory = 0;

  final Map<String, List<String>> _iosEmojiCategories = const {
    '😀': [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '🥲', '☺️',
      '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗',
      '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓',
      '😎', '🥸', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕',
      '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤',
      '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰',
      '😥', '😓', '🤗', '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑',
      '😬', '🙄', '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤',
    ],
    '👍': [
      '👋', '🤚', '🖐', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞',
      '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍',
      '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝',
      '🙏', '✍️', '💅', '🤳', '💪', '🧠', '👀', '👁', '👅', '👄',
    ],
    '❤️': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️',
      '✝️', '☪️', '🕉', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐',
    ],
    '🎉': [
      '🔥', '✨', '🎉', '🎊', '🎈', '🎁', '🏆', '🎖', '🏅', '🥇',
      '🥈', '🥉', '⚽️', '🏀', '🏈', '⚾️', '🥎', '🎾', '🏐', '🏉',
      '🎱', '🏓', '🏸', '🏒', '🎯', '🎮', '🎰', '🎲', '🧩', '🧸',
      '🎨', '📱', '💻', '🖥', '📸', '📹', '🎥', '📞', '📻', '🎙',
    ],
    '💡': [
      '💡', '🔦', '🕯', '💸', '💵', '🪙', '💰', '💳', '💎', '⚖️',
      '🛠', '🔑', '🗝', '📦', '🏷', '✉️', '📩', '📨', '📧', '💌',
      '📊', '📈', '📉', '🗓', '📅', '📋', '📁', '📂', '📌', '📍',
      '🚩', '🔍', '🔎', '🔒', '🔓', '🔏', '🔐', '🏷', '⚡️', '🌟',
    ],
  };

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    if (selection.start >= 0 && selection.end >= selection.start) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      _textController.text = newText;
      _textController.selection = TextSelection.collapsed(
        offset: selection.start + emoji.length,
      );
    } else {
      _textController.text += emoji;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    }
  }

  Color _getContactStatusColor(Map<String, dynamic>? c) {
    if (c == null) return Colors.grey;
    final status = (c['status'] as String? ?? 'Offline').trim().toLowerCase();
    final lastSeenStr = c['lastSeen'] as String? ?? '';

    if (lastSeenStr.isNotEmpty) {
      final lastSeen = DateTime.tryParse(lastSeenStr);
      if (lastSeen != null) {
        final diff = DateTime.now().difference(lastSeen);
        if (diff.inMinutes > 3) {
          return Colors.grey;
        }
      }
    }

    if (status == 'idle') {
      return Colors.amber;
    }
    if (status == 'online' || status == 'active') {
      return Colors.green;
    }
    return Colors.grey;
  }

  bool _isContactOnline(Map<String, dynamic>? c) {
    final color = _getContactStatusColor(c);
    return color == Colors.green || color == Colors.amber;
  }

  String _contactSearchQuery = '';
  List<String> _pinnedContactIds = [];
  List<String> _mutedContactIds = [];

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final pinned = prefs.getStringList('pinned_contacts_$currentUserId') ?? [];
    final muted = prefs.getStringList('muted_contacts_$currentUserId') ?? [];
    if (mounted) {
      setState(() {
        _pinnedContactIds = pinned;
        _mutedContactIds = muted;
      });
    }
  }

  Future<void> _togglePinContact(String targetId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'pinned_contacts_$currentUserId';
    List<String> list = prefs.getStringList(key) ?? [];
    if (list.contains(targetId)) {
      list.remove(targetId);
      if (mounted) showGlassSnackbar(context, 'Unpinned chat with $name');
    } else {
      list.add(targetId);
      if (mounted) showGlassSnackbar(context, 'Pinned chat with $name', type: SnackbarType.success);
    }
    await prefs.setStringList(key, list);
    setState(() => _pinnedContactIds = list);
  }

  Future<void> _toggleMuteContact(String targetId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'muted_contacts_$currentUserId';
    List<String> list = prefs.getStringList(key) ?? [];
    if (list.contains(targetId)) {
      list.remove(targetId);
      if (mounted) showGlassSnackbar(context, 'Unmuted notifications for $name');
    } else {
      list.add(targetId);
      if (mounted) showGlassSnackbar(context, 'Muted notifications for $name', type: SnackbarType.info);
    }
    await prefs.setStringList(key, list);
    setState(() => _mutedContactIds = list);
  }

  Future<void> _deleteConversation(String targetId, String targetEmail, String name) async {
    try {
      final allMsgs = await _firestore.getCollection('messages');
      for (final m in allMsgs) {
        final senderId = m['senderId'] as String? ?? '';
        final recipientId = m['recipientId'] as String? ?? '';
        final senderEmail = (m['senderEmail'] as String? ?? '').toLowerCase();
        final recipientEmail = (m['recipientEmail'] as String? ?? '').toLowerCase();
        final docId = m['id'] as String? ?? '';

        final match1 = (senderId == currentUserId || senderEmail == currentUserEmail.toLowerCase()) &&
            (recipientId == targetId || recipientEmail == targetEmail.toLowerCase());
        final match2 = (senderId == targetId || senderEmail == targetEmail.toLowerCase()) &&
            (recipientId == currentUserId || recipientEmail == currentUserEmail.toLowerCase());

        if ((match1 || match2) && docId.isNotEmpty) {
          await _firestore.deleteDocument('messages', docId);
        }
      }
      if (mounted) {
        showGlassSnackbar(context, 'Deleted conversation with $name', type: SnackbarType.info);
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackbar(context, 'Error deleting chat: $e', type: SnackbarType.error);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    final list = _contacts.where((c) {
      if (_contactSearchQuery.isEmpty) return true;
      final q = _contactSearchQuery.toLowerCase();
      final name = (c['name'] as String? ?? '').toLowerCase();
      final role = (c['role'] as String? ?? '').toLowerCase();
      final email = (c['email'] as String? ?? '').toLowerCase();
      return name.contains(q) || role.contains(q) || email.contains(q);
    }).toList();

    list.sort((a, b) {
      final idA = a['id'] as String? ?? a['uid'] as String? ?? '';
      final idB = b['id'] as String? ?? b['uid'] as String? ?? '';
      final emailA = a['email'] as String? ?? '';
      final emailB = b['email'] as String? ?? '';
      // 0. Nexus Announcement official channel ALWAYS at absolute top
      final isOfficialA = idA == 'nexus_announcement' || idA == 'excelerate_general' || (a['isOfficialChannel'] as bool? ?? false);
      final isOfficialB = idB == 'nexus_announcement' || idB == 'excelerate_general' || (b['isOfficialChannel'] as bool? ?? false);
      if (isOfficialA && !isOfficialB) return -1;
      if (!isOfficialA && isOfficialB) return 1;

      // 1. Pinned contacts first
      final isPinnedA = _pinnedContactIds.contains(idA);
      final isPinnedB = _pinnedContactIds.contains(idB);
      if (isPinnedA && !isPinnedB) return -1;
      if (!isPinnedA && isPinnedB) return 1;

      // 2. Unread messages second
      final unreadA = _getUnreadCountForContact(idA, emailA);
      final unreadB = _getUnreadCountForContact(idB, emailB);
      if (unreadA > 0 && unreadB == 0) return -1;
      if (unreadA == 0 && unreadB > 0) return 1;

      // 3. Most recent message timestamp third (Newest active conversation at top)
      final lastMsgA = _getLastMessageForContact(idA, emailA);
      final lastMsgB = _getLastMessageForContact(idB, emailB);
      final tsA = lastMsgA?['timestamp'] as String? ?? '';
      final tsB = lastMsgB?['timestamp'] as String? ?? '';

      if (tsA.isNotEmpty && tsB.isNotEmpty) {
        final cmp = tsB.compareTo(tsA);
        if (cmp != 0) return cmp;
      } else if (tsA.isNotEmpty && tsB.isEmpty) {
        return -1;
      } else if (tsA.isEmpty && tsB.isNotEmpty) {
        return 1;
      }

      // 4. Fallback alphabetical by name
      final nameA = (a['name'] as String? ?? '').toLowerCase();
      final nameB = (b['name'] as String? ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _selectedContact == null
            ? _buildInboxView(theme)
            : _buildChatThreadView(theme),
      ),
    );
  }

  /// Meta Messenger / Instagram Direct Style Inbox View
  Widget _buildInboxView(ThemeData theme) {
    final displayContacts = _isLoadingContacts
        ? List.generate(
            6,
            (i) => {
                  'id': 'skel_$i',
                  'name': i % 2 == 0 ? 'Alex Johnson' : 'Sarah Parker',
                  'role': 'Software Intern',
                  'avatar': 'preset_1',
                  'status': 'Online',
                  'email': 'user_$i@nexus.com',
                  'lastSeen': DateTime.now().toIso8601String(),
                })
        : _contacts;

    final filtered = _isLoadingContacts ? displayContacts : _filteredContacts;

    return Skeletonizer(
      enabled: _isLoadingContacts,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sheet Drag Handle & Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Direct Messages',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Kameron',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search Input Box
                TextField(
                  onChanged: (val) => setState(() => _contactSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search people by name or role...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.amber.shade900.withValues(alpha: 0.9),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Offline Mode • Waiting for network...',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),

          // Active People Horizontal Stories / Chatheads Bar
          if (displayContacts.isNotEmpty) ...[
            Builder(
              builder: (ctx) {
                final activeContacts = displayContacts.where((c) {
                  final color = _getContactStatusColor(c);
                  return color == Colors.green || color == Colors.amber;
                }).toList();
                final listToShow = activeContacts.isNotEmpty ? activeContacts : displayContacts;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 12, bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            'Active People',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (activeContacts.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${activeContacts.length} online',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: listToShow.length,
                        itemBuilder: (ctx, idx) {
                          final contact = listToShow[idx];
                          final statusColor = _getContactStatusColor(contact);
                          final name = contact['name'] as String? ?? 'User';
                          final firstName = name.trim().isNotEmpty ? name.trim().split(' ').first : 'User';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedContact = contact;
                                _subscribeToChat();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 58,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: statusColor.withValues(alpha: 0.8),
                                              width: 2,
                                            ),
                                          ),
                                          child: AvatarUtils.buildAvatarWidget(
                                            contact['avatar'] as String? ?? 'preset_1',
                                            radius: 20,
                                            fallbackLetter: name,
                                          ),
                                        ),
                                        Positioned(
                                          right: 2,
                                          bottom: 2,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: theme.colorScheme.surface,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      firstName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const Divider(height: 1),

          // Vertical Conversation / People List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.primary,
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'No people found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                    final contact = filtered[idx];
                    final contactId = contact['id'] as String? ?? contact['uid'] as String? ?? '';
                    final email = contact['email'] as String? ?? '';
                    final name = contact['name'] as String? ?? 'User';
                    final role = contact['role'] as String? ?? 'Intern';
                    final avatar = contact['avatar'] as String? ?? 'preset_1';
                    final statusColor = _getContactStatusColor(contact);
                    final isPinned = _pinnedContactIds.contains(contactId);
                    final isMuted = _mutedContactIds.contains(contactId);

                    final lastMsg = _getLastMessageForContact(contactId, email);
                    final unreadCount = _getUnreadCountForContact(contactId, email);
                    final isUnread = unreadCount > 0;
                    final previewText = lastMsg != null
                        ? (lastMsg['body'] as String? ?? lastMsg['content'] as String? ?? '')
                        : role;

                    return Dismissible(
                      key: Key('chat_item_$contactId'),
                      background: Container(
                        color: Colors.indigo.shade600,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            Icon(
                              isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isMuted ? 'Unmute' : 'Mute',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.redAccent.shade700,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await _toggleMuteContact(contactId, name);
                          return false;
                        } else if (direction == DismissDirection.endToStart) {
                          await _deleteConversation(contactId, email, name);
                          return true;
                        }
                        return false;
                      },
                      child: Material(
                        color: isUnread
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedContact = contact;
                              _subscribeToChat();
                            });
                          },
                          onLongPress: () => _togglePinContact(contactId, name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    AvatarUtils.buildAvatarWidget(
                                      avatar,
                                      radius: 24,
                                      fallbackLetter: name,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontFamily: 'Kameron',
                                              fontWeight: isUnread
                                                  ? FontWeight.w900
                                                  : (isPinned ? FontWeight.bold : FontWeight.w600),
                                              color: isUnread
                                                  ? theme.colorScheme.onSurface
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          if (contact['isOfficialChannel'] == true || name.contains('Nexus Announcement') || name.contains('Excelerate General')) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.verified,
                                              size: 15,
                                              color: Color(0xFF3897F0),
                                            ),
                                          ],
                                          if (isPinned) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.push_pin_rounded,
                                              size: 14,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ],
                                          if (isMuted) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.notifications_off_rounded,
                                              size: 14,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        previewText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: isUnread
                                            ? theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              )
                                            : theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedMessageEdit01,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ),
        ),
      ],
    ),
  );
}

  /// Meta Messenger 1-on-1 Chat Thread View
  Widget _buildChatThreadView(ThemeData theme) {
    final contactName = _selectedContact?['name'] as String? ?? 'Select Chat';
    final contactRole = _selectedContact?['role'] as String? ?? 'User';
    final contactAvatar = _selectedContact?['avatar'] as String? ?? 'preset_1';
    final activeDotColor = _getContactStatusColor(_selectedContact);

    return Stack(
      children: [
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Bar (Messenger Style with Back Button)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => setState(() => _selectedContact = null),
                  ),
                  Stack(
                    children: [
                      AvatarUtils.buildAvatarWidget(
                        contactAvatar,
                        radius: 18,
                        fallbackLetter: contactName,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: activeDotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.surface, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              contactName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'Kameron',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedContact?['isOfficialChannel'] == true || contactName.contains('Nexus Announcement') || contactName.contains('Excelerate General')) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: Color(0xFF3897F0),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _isPartnerTyping ? 'Typing...' : contactRole,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _isPartnerTyping ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            fontWeight: _isPartnerTyping ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            color: Colors.amber.shade900.withValues(alpha: 0.9),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Offline Mode • Waiting for network...',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // Chat Messages List (Messenger Style Bubbles with Partner Avatar)
        Expanded(
          child: () {
            if (_isLoadingThreadMessages) {
              return _buildThreadSkeleton(theme);
            }

            final allDisplayMessages = <Map<String, dynamic>>[..._messages];

            for (final pending in _localPendingMessages) {
              final tempId = pending['tempId'] as String? ?? '';
              final pBody = (pending['body'] as String? ?? '').trim();
              final pSender = pending['senderId'] as String? ?? '';

              final alreadyInStream = _messages.any((m) {
                final mId = m['id'] as String? ?? '';
                final mBody = (m['body'] as String? ?? m['content'] as String? ?? '').trim();
                final mSender = m['senderId'] as String? ?? '';

                if (tempId.isNotEmpty && mId == tempId) return true;
                return mBody == pBody && (mSender == pSender || mSender.isEmpty);
              });

              if (!alreadyInStream) {
                allDisplayMessages.add(pending);
              }
            }

            if (allDisplayMessages.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarUtils.buildAvatarWidget(
                        contactAvatar,
                        radius: 36,
                        fallbackLetter: contactName,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        contactName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'Kameron',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          contactRole,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet. Start the conversation!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: allDisplayMessages.length,
                    itemBuilder: (ctx, idx) {
                      final msg = allDisplayMessages[idx];
                      final body = msg['body'] as String? ?? msg['content'] as String? ?? '';
                      final isEdited = msg['isEdited'] as bool? ?? false;
                      final isUnsent = msg['isUnsent'] as bool? ?? false;
                      final replyToSenderName = msg['replyToSenderName'] as String? ?? '';
                      final replyToBody = msg['replyToBody'] as String? ?? '';
                      final sId = (msg['senderId'] as String? ?? '').toLowerCase();
                      final sEmail = (msg['senderEmail'] as String? ?? '').toLowerCase();
                      final sName = (msg['senderName'] as String? ?? '').toLowerCase();

                      final myId = currentUserId.toLowerCase();
                      final myEmail = currentUserEmail.toLowerCase();
                      final myName = (widget.authController.userDisplayName).toLowerCase();

                      final isMe = (myId.isNotEmpty && (sId == myId || sEmail == myId)) ||
                          (myEmail.isNotEmpty && (sEmail == myEmail || sId == myEmail)) ||
                          (myName.isNotEmpty && sName.isNotEmpty && sName == myName);

                      // Reactions on this message
                      final reactions = Map<String, dynamic>.from(msg['reactions'] as Map? ?? {});

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe) ...[
                                  AvatarUtils.buildAvatarWidget(
                                    contactAvatar,
                                    radius: 14,
                                    fallbackLetter: contactName,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: isUnsent
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: theme.colorScheme.outline.withValues(alpha: 0.15),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.block_rounded,
                                                size: 14,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'This message was unsent',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : GestureDetector(
                                          onLongPress: () => _showIosMessageContextMenu(msg, isMe),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width * 0.72,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMe
                                                  ? theme.colorScheme.primary
                                                  : (theme.brightness == Brightness.dark
                                                      ? const Color(0xFF2D2D30)
                                                      : const Color(0xFFE8E8ED)),
                                              border: isMe
                                                  ? null
                                                  : Border.all(
                                                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                                      width: 1,
                                                    ),
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(18),
                                                topRight: const Radius.circular(18),
                                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                                bottomRight: Radius.circular(isMe ? 4 : 18),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (replyToBody.isNotEmpty) ...[
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isMe
                                                          ? Colors.black.withValues(alpha: 0.15)
                                                          : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border(
                                                        left: BorderSide(
                                                          color: isMe
                                                              ? theme.colorScheme.onPrimary
                                                              : theme.colorScheme.primary,
                                                          width: 3,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          replyToSenderName,
                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 10,
                                                            color: isMe
                                                                ? theme.colorScheme.onPrimary
                                                                : theme.colorScheme.primary,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          replyToBody,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            fontSize: 11,
                                                            color: isMe
                                                                ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                                                                : theme.colorScheme.onSurface,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                Text(
                                                  body,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: isMe
                                                        ? theme.colorScheme.onPrimary
                                                        : (theme.brightness == Brightness.dark
                                                            ? Colors.white
                                                            : const Color(0xFF1C1C1E)),
                                                    fontWeight: isMe ? FontWeight.normal : FontWeight.w500,
                                                  ),
                                                ),
                                                 if (msg['isFeedbackResponse'] == true) ...[
                                                   const SizedBox(height: 8),
                                                   Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                     decoration: BoxDecoration(
                                                       color: Colors.amber.withValues(alpha: 0.15),
                                                       borderRadius: BorderRadius.circular(8),
                                                       border: Border.all(
                                                         color: Colors.amber.withValues(alpha: 0.4),
                                                       ),
                                                     ),
                                                     child: const Row(
                                                       mainAxisSize: MainAxisSize.min,
                                                       children: [
                                                         Icon(Icons.lock_outline, size: 12, color: Colors.amber),
                                                         SizedBox(width: 4),
                                                         Text(
                                                           'Private Feedback • Only you can see this',
                                                           style: TextStyle(
                                                             fontSize: 10,
                                                             fontWeight: FontWeight.w600,
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ),
                                                   const SizedBox(height: 6),
                                                   GestureDetector(
                                                     onTap: () async {
                                                       final fId = msg['feedbackId'] as String? ?? '';
                                                       if (fId.isNotEmpty) {
                                                         try {
                                                           await FirebaseFirestore.instance
                                                               .collection('feedback')
                                                               .doc(fId)
                                                               .update({'status': 'Done'});
                                                           if (context.mounted) {
                                                             showGlassSnackbar(
                                                               context,
                                                               'Feedback status updated to Done ✓',
                                                               type: SnackbarType.success,
                                                             );
                                                           }
                                                         } catch (_) {}
                                                       }
                                                     },
                                                     child: Container(
                                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                       decoration: BoxDecoration(
                                                         color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                         borderRadius: BorderRadius.circular(10),
                                                         border: Border.all(
                                                           color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                                         ),
                                                       ),
                                                       child: const Row(
                                                         mainAxisSize: MainAxisSize.min,
                                                         children: [
                                                           Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF10B981)),
                                                           SizedBox(width: 4),
                                                           Text(
                                                             'React / Mark Done',
                                                             style: TextStyle(
                                                               fontSize: 11,
                                                               fontWeight: FontWeight.w600,
                                                               color: Color(0xFF10B981),
                                                             ),
                                                           ),
                                                         ],
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                                 if (isEdited) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '(edited)',
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      fontSize: 10,
                                                      fontStyle: FontStyle.italic,
                                                      color: isMe
                                                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                                                          : theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            // Reaction badges below the bubble
                            if (reactions.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 2,
                                  left: isMe ? 0 : 36,
                                  right: isMe ? 4 : 0,
                                ),
                                child: Wrap(
                                  spacing: 4,
                                  children: reactions.entries.map((entry) {
                                    final emoji = entry.key;
                                    final users = List<String>.from(entry.value as List? ?? []);
                                    if (users.isEmpty) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(12),
                                        border: users.contains(currentUserId)
                                            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.6), width: 1.5)
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(emoji, style: const TextStyle(fontSize: 12)),
                                          if (users.length > 1) ...[
                                            const SizedBox(width: 2),
                                            Text(
                                              '${users.length}',
                                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                            // Status Indicator (Sent, Delivered, Read, Failed with resend)
                            _buildStatusIndicator(msg, isMe, theme),
                          ],
                        ),
                      );
                    },
                  );
          }(),
        ),

          // Real-Time Minimalist Typing Indicator Bubble
          if (_isPartnerTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  AvatarUtils.buildAvatarWidget(
                    contactAvatar,
                    radius: 12,
                    fallbackLetter: contactName,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'typing',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Complete Categorized iOS Emoji Keyboard Panel (High Performance 60fps PageView & RepaintBoundary)
          if (_showEmojiPicker) ...[
            Container(
              height: 44,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_iosEmojiCategories.keys.length, (idx) {
                        final catKey = _iosEmojiCategories.keys.elementAt(idx);
                        final isSelected = _selectedEmojiCategory == idx;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedEmojiCategory = idx);
                            _emojiPageController.animateToPage(
                              idx,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.fastOutSlowIn,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(catKey, style: const TextStyle(fontSize: 18)),
                          ),
                        );
                      }),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    onPressed: () {
                      final text = _textController.text;
                      if (text.isNotEmpty) {
                        _textController.text = text.substring(0, text.length - 1);
                        _textController.selection = TextSelection.collapsed(
                          offset: _textController.text.length,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _emojiPageController,
                onPageChanged: (idx) {
                  setState(() => _selectedEmojiCategory = idx);
                },
                itemCount: _iosEmojiCategories.length,
                itemBuilder: (ctx, catIdx) {
                  final emojis = _iosEmojiCategories.values.elementAt(catIdx);
                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (ctx, idx) {
                      final emoji = emojis[idx];
                      return RepaintBoundary(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _insertEmoji(emoji),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],

          // Reply Preview Banner
          if (_replyingToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${_replyingToMessage!['senderName'] ?? "User"}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _replyingToMessage!['body'] as String? ?? _replyingToMessage!['content'] as String? ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyingToMessage = null),
                    child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

          // Inline Edit Banner
          if (_editingDocId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editing message',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelInlineEdit,
                    child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

          // Read-Only Banner for Nexus Announcement vs Regular Input Bar
          if (_selectedContact?['isOfficialChannel'] == true || contactName.contains('Nexus Announcement') || contactName.contains('Excelerate General'))
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Only official announcements are posted in Nexus Announcement. Long-press any announcement to react with emojis.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Pure Floating 3D Liquid Glass Input Bar (Separate Floating Input Pill & Separate Floating 3D Send Button)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
                child: Row(
                  children: [
                    // Floating 3D Glass Input Pill
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF1E1E22).withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _editingDocId != null
                                    ? theme.colorScheme.primary
                                    : Colors.white.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.75),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.12),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  spreadRadius: -2,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              readOnly: _isSending,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: _onTypingChanged,
                              onSubmitted: (_) => _editingDocId != null ? _submitInlineEdit() : _sendMessage(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: _editingDocId != null
                                    ? 'Edit message...'
                                    : 'Message ${contactName.trim().isNotEmpty ? contactName.trim().split(' ').first : "User"}...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showEmojiPicker
                                        ? Icons.keyboard_hide_rounded
                                        : Icons.sentiment_satisfied_alt_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: _toggleEmojiPicker,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Standalone Liquid Glass Floating 3D Send Button (Matching Liquid Glass Glassmorphism)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF1E1E22).withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.88),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _editingDocId != null
                                  ? theme.colorScheme.primary
                                  : Colors.white.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.75),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.12),
                                blurRadius: 18,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 12,
                                spreadRadius: -2,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: _isSending
                                ? RotationTransition(
                                    turns: _getSpinController(),
                                    child: Image.asset(
                                      'assets/icons/app_logo.png',
                                      width: 22,
                                      height: 22,
                                    ),
                                  )
                                : Icon(
                                    _editingDocId != null ? Icons.check_rounded : Icons.send_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                            onPressed: _isSending
                                ? null
                                : (_editingDocId != null ? _submitInlineEdit : _sendMessage),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),

      // --- Scoped iOS Context Menu Overlay (blur covers chat UI only) ---
      if (_contextMenuMsg != null)
        Positioned.fill(
          child: _IosContextMenuOverlay(
            theme: theme,
            body: _contextMenuMsg!['body'] as String? ?? _contextMenuMsg!['content'] as String? ?? '',
            isMe: _contextMenuIsMe,
            docId: _contextMenuMsg!['id'] as String? ?? '',
            canEditUnsend: _contextMenuIsMe && _canEditOrUnsend(_contextMenuMsg!),
            onDismiss: _dismissContextMenu,
            onReact: (emoji) => _reactToMessage(
              _contextMenuMsg!['id'] as String? ?? '', emoji,
            ),
            onReply: () {
              final msg = _contextMenuMsg;
              _dismissContextMenu();
              if (msg != null) {
                setState(() {
                  _replyingToMessage = msg;
                });
              }
            },
            onCopy: () {
              _dismissContextMenu();
              final body = _contextMenuMsg!['body'] as String? ?? _contextMenuMsg!['content'] as String? ?? '';
              Clipboard.setData(ClipboardData(text: body));
              showGlassSnackbar(context, 'Copied to clipboard', type: SnackbarType.success);
            },
            onEdit: () {
              final docId = _contextMenuMsg!['id'] as String? ?? '';
              final body = _contextMenuMsg!['body'] as String? ?? _contextMenuMsg!['content'] as String? ?? '';
              _dismissContextMenu();
              _startInlineEdit(docId, body);
            },
            onUnsend: () async {
              final docId = _contextMenuMsg!['id'] as String? ?? '';
              _dismissContextMenu();
              if (docId.isNotEmpty) {
                try {
                  await _firestore.updateDocument('messages', docId, {
                    'body': 'This message was unsent',
                    'isUnsent': true,
                    'reactions': {},
                  });
                  if (mounted) {
                    showGlassSnackbar(context, 'Message unsent', type: SnackbarType.info);
                  }
                } catch (e) {
                  if (mounted) {
                    showGlassSnackbar(context, 'Error unsending message: $e', type: SnackbarType.error);
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

/// iOS iMessage-style context menu overlay (state-driven, scoped to chat UI).
/// Shows a blurred background, the message bubble preview,
/// a reaction emoji bar, and a floating rounded action menu.
class _IosContextMenuOverlay extends StatelessWidget {
  final ThemeData theme;
  final String body;
  final bool isMe;
  final String docId;
  final bool canEditUnsend;
  final VoidCallback onDismiss;
  final void Function(String emoji) onReact;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onUnsend;

  const _IosContextMenuOverlay({
    required this.theme,
    required this.body,
    required this.isMe,
    required this.docId,
    required this.canEditUnsend,
    required this.onDismiss,
    required this.onReact,
    required this.onReply,
    required this.onCopy,
    required this.onEdit,
    required this.onUnsend,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // absorb taps on content
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // --- Reaction emoji bar ---
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ['❤️', '👍', '👎', '😂', '‼️', '❓']
                              .map(
                                (emoji) => GestureDetector(
                                  onTap: () => onReact(emoji),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text(emoji,
                                        style: const TextStyle(fontSize: 26)),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      // --- Message bubble preview ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primary
                              : (theme.brightness == Brightness.dark
                                  ? const Color(0xFF2D2D30)
                                  : const Color(0xFFE8E8ED)),
                          border: isMe
                              ? null
                              : Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isMe
                                ? theme.colorScheme.onPrimary
                                : (theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1C1C1E)),
                            fontWeight: isMe ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- Floating action menu ---
                      Container(
                        width: 220,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Reply
                            _buildMenuItem(
                              label: 'Reply',
                              icon: Icons.reply_rounded,
                              onTap: onReply,
                            ),
                            _divider(),
                            // Copy
                            _buildMenuItem(
                              label: 'Copy',
                              icon: Icons.content_copy_rounded,
                              onTap: onCopy,
                            ),
                            // Edit (only for own unread/unreplied messages)
                            if (isMe && canEditUnsend) ...[
                              _divider(),
                              _buildMenuItem(
                                label: 'Edit',
                                icon: Icons.edit_rounded,
                                onTap: onEdit,
                              ),
                            ],
                            // Unsend (only for own unread/unreplied messages)
                            if (isMe && canEditUnsend) ...[
                              _divider(),
                              _buildMenuItem(
                                label: 'Unsend',
                                icon: Icons.arrow_back_rounded,
                                onTap: onUnsend,
                                isDestructive: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.redAccent
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ),
            Icon(icon, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: theme.colorScheme.outline.withValues(alpha: 0.15),
    );
  }
}
