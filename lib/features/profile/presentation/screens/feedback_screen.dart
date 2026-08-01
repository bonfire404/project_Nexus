import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/features/profile/data/repositories/feedback_firestore_repository.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FeedbackScreen extends StatefulWidget {
  final AuthController? authController;

  const FeedbackScreen({super.key, this.authController});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final FeedbackFirestoreRepository _repository = FeedbackFirestoreRepository();
  String _category = 'General';
  bool _isSubmitting = false;
  bool _isLoadingAdmin = true;
  List<Map<String, dynamic>> _adminFeedbackList = [];

  bool get _isAdmin => widget.authController?.selectedRole == UserRole.administrator;

  @override
  void initState() {
    super.initState();
    if (_isAdmin) {
      _loadAdminFeedback();
    }
  }

  Future<void> _loadAdminFeedback() async {
    try {
      final items = await _repository.getAllFeedback();
      if (mounted) {
        setState(() {
          _adminFeedbackList = items;
          _isLoadingAdmin = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _adminFeedbackList = [];
          _isLoadingAdmin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _repository.submitFeedback(
        email: _emailController.text.trim(),
        category: _category,
        message: _messageController.text.trim(),
        userId: widget.authController?.currentUser?.uid,
      );
      if (mounted) {
        showGlassSnackbar(
          context,
          'Feedback submitted successfully! Thank you.',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackbar(
          context,
          'Error submitting feedback: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showRespondSheet(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final responseController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
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
                'Respond to Feedback',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Kameron',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'From: ${item['email'] ?? 'User'} (${item['category'] ?? 'General'})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['message'] as String? ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Your Response',
                  hintText: 'Type your official response to the user...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final responseText = responseController.text.trim();
                    if (responseText.isEmpty) return;
                    Navigator.pop(ctx);

                    try {
                      final docId = item['id'] as String? ?? '';
                      if (docId.isNotEmpty) {
                        await _repository.respondToFeedback(
                          docId,
                          responseText,
                          recipientEmail: item['email'] as String?,
                          recipientUserId: item['userId'] as String?,
                        );
                      }
                      if (mounted) {
                        showGlassSnackbar(
                          context,
                          'Response sent successfully!',
                          type: SnackbarType.success,
                        );
                        _loadAdminFeedback();
                      }
                    } catch (e) {
                      if (mounted) {
                        showGlassSnackbar(
                          context,
                          'Error sending response: $e',
                          type: SnackbarType.error,
                        );
                      }
                    }
                  },
                  child: const Text('Send Response'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Feedback Inbox'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Skeletonizer(
          enabled: _isLoadingAdmin,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feedback Submissions Inbox',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Kameron',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and respond to feedback submitted by applicants and interns.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _adminFeedbackList.isEmpty
                      ? Center(
                          child: Text(
                            'No feedback submissions found.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _adminFeedbackList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _adminFeedbackList[index];
                            final status = item['status'] as String? ?? 'Pending';
                            final isResponded = status == 'Responded';

                            return GestureDetector(
                              onTap: () => _showRespondSheet(item),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item['category'] as String? ?? 'General',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isResponded
                                                ? Colors.green.withValues(alpha: 0.1)
                                                : Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: isResponded ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item['message'] as String? ?? '',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['email'] as String? ?? '',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
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
        ),
      );
    }

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !Navigator.canPop(context)) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Send Feedback'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/home');
              }
            },
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We value your feedback',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Kameron',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us improve the Excelerate Nexus experience.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFilter,
                    size: 20,
                    color: Colors.transparent,
                  ),
                ),
                items: ['General', 'Bug Report', 'Feature Request', 'Content']
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  hintText: 'you@example.com',
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMail01,
                    size: 20,
                    color: Colors.transparent,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  hintText: 'Tell us what you think...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your message';
                  }
                  if (value.trim().length < 10) {
                    return 'Message must be at least 10 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
