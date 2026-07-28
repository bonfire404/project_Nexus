import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/core/utils/avatar_utils.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Admin's user management screen — minimalist with + Add User and Swipe-to-Delete.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserFirestoreRepository _repository = UserFirestoreRepository();
  final _searchController = TextEditingController();
  StreamSubscription<List<Map<String, dynamic>>>? _usersSubscription;
  String _searchQuery = '';
  String _roleFilter = 'All';
  bool _isLoading = true;
  List<Map<String, String>> _users = [];

  @override
  void initState() {
    super.initState();
    _subscribeToUsers();
  }

  String _computeUserStatus(Map<String, dynamic> u) {
    final status = (u['status'] as String? ?? 'Offline').trim();
    final lastSeenStr = u['lastSeen'] as String? ?? '';
    if (status.toLowerCase() == 'online' && lastSeenStr.isNotEmpty) {
      final lastSeen = DateTime.tryParse(lastSeenStr);
      if (lastSeen != null) {
        final diff = DateTime.now().difference(lastSeen);
        if (diff.inMinutes <= 2) return 'Online';
      }
    }
    return 'Offline';
  }

  void _subscribeToUsers() {
    _usersSubscription = _repository.streamAllUsers().listen(
      (firestoreUsers) {
        if (mounted) {
          setState(() {
            _users = firestoreUsers.map((u) => {
              'uid': u['id'] as String? ?? u['uid'] as String? ?? '',
              'name': u['name'] as String? ?? 'User',
              'role': u['role'] as String? ?? 'Intern',
              'status': _computeUserStatus(u),
              'email': u['email'] as String? ?? 'user@example.com',
              'avatar': u['avatar'] as String? ?? u['photoUrl'] as String? ?? '',
            }).toList();
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  List<Map<String, String>> get _filtered {
    return _users.where((u) {
      final matchesSearch = _searchQuery.isEmpty ||
          u['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u['email']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _roleFilter == 'All' ||
          (_roleFilter == 'Interns' && u['role'] == 'Intern') ||
          (_roleFilter == 'Applicants' && u['role'] == 'Applicant');
      return matchesSearch && matchesRole;
    }).toList();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddUserSheet() {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String defaultRole = _roleFilter == 'Applicants' ? 'Applicant' : 'Intern';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                    'Add User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Kameron',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Jordan Lee',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'jordan@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: defaultRole,
                    decoration: const InputDecoration(labelText: 'Assigned Role'),
                    items: ['Intern', 'Applicant', 'Administrator']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => defaultRole = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();
                        if (name.isEmpty || email.isEmpty) return;

                        Navigator.pop(ctx);
                        final newUid = 'usr_${DateTime.now().millisecondsSinceEpoch}';
                        try {
                          await _repository.setUserProfile(
                            uid: newUid,
                            name: name,
                            email: email,
                            role: defaultRole,
                          );
                          if (mounted) {
                            showGlassSnackbar(
                              context,
                              'Added $defaultRole "$name" successfully!',
                              type: SnackbarType.success,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            showGlassSnackbar(
                              context,
                              'Error adding user: $e',
                              type: SnackbarType.error,
                            );
                          }
                        }
                      },
                      child: const Text('Add User'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetail(Map<String, String> user) {
    final theme = Theme.of(context);
    final statusStr = (user['status'] ?? 'Offline').trim().toLowerCase();
    final statusColor = statusStr == 'idle'
        ? Colors.amber
        : ((statusStr == 'online' || statusStr == 'active') ? Colors.green : Colors.grey);
    String currentRole = user['role'] ?? 'Intern';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      user['name']!.isNotEmpty ? user['name']![0] : 'U',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name']!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Kameron',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user['email']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user['role']!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user['status']!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: ['Intern', 'Applicant', 'Administrator'].contains(currentRole) ? currentRole : 'Intern',
                decoration: const InputDecoration(
                  labelText: 'Change Role / Promote User',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ['Applicant', 'Intern', 'Administrator']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (newRole) async {
                  if (newRole != null && newRole != currentRole) {
                    final uid = user['uid']!;
                    if (uid.isNotEmpty) {
                      try {
                        await _repository.updateUser(uid, {'role': newRole});
                        setSheetState(() => currentRole = newRole);
                        if (mounted) {
                          showGlassSnackbar(
                            context,
                            'Updated "${user['name']}" role to $newRole',
                            type: SnackbarType.success,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showGlassSnackbar(
                            context,
                            'Error updating role: $e',
                            type: SnackbarType.error,
                          );
                        }
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showGlassSnackbar(
                          context,
                          'Message sent to ${user['name']}',
                          type: SnackbarType.success,
                        );
                      },
                      child: const Text('Message'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final uid = user['uid']!;
                        Navigator.pop(ctx);
                        if (uid.isNotEmpty) {
                          try {
                            await _repository.deleteUser(uid);
                            if (mounted) {
                              showGlassSnackbar(
                                context,
                                'User "${user['name']}" removed from database.',
                                type: SnackbarType.warning,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showGlassSnackbar(
                                context,
                                'Error removing user: $e',
                                type: SnackbarType.error,
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Remove User'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _filtered;

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
                  'Users Management',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Kameron',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add User',
                  onPressed: _showAddUserSheet,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Filter chips
            Wrap(
              spacing: 8,
              children: ['All', 'Interns', 'Applicants'].map((label) {
                final isSelected = _roleFilter == label;
                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _roleFilter = label),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  checkmarkColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '${results.length} user${results.length == 1 ? '' : 's'} (Swipe left to delete)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'No users found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = results[index];
                        final status = (user['status'] ?? 'Offline').trim().toLowerCase();
                        final lastSeenStr = user['lastSeen'] ?? '';
                        bool isStale = false;
                        if (lastSeenStr.isNotEmpty) {
                          final ls = DateTime.tryParse(lastSeenStr);
                          if (ls != null && DateTime.now().difference(ls).inMinutes > 3) {
                            isStale = true;
                          }
                        }
                        final statusDotColor = isStale
                            ? const Color(0xFF8E8E93)
                            : (status == 'idle'
                                ? Colors.amber
                                : ((status == 'online' || status == 'active') ? const Color(0xFF34C759) : const Color(0xFF8E8E93)));

                        return Dismissible(
                          key: Key('${user['uid']}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (direction) async {
                            final uid = user['uid']!;
                            final name = user['name']!;
                            if (uid.isNotEmpty) {
                              try {
                                await _repository.deleteUser(uid);
                                if (mounted) {
                                  showGlassSnackbar(
                                    context,
                                    'Deleted "$name" from system database.',
                                    type: SnackbarType.warning,
                                  );
                                }
                              } catch (_) {}
                            }
                          },
                          child: GestureDetector(
                            onTap: () => _showUserDetail(user),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      AvatarUtils.buildAvatarWidget(
                                        user['avatar'],
                                        radius: 20,
                                        fallbackLetter: user['name'],
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 11,
                                          height: 11,
                                          decoration: BoxDecoration(
                                            color: statusDotColor,
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name']!,
                                          style:
                                              theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          user['role']!,
                                          style:
                                              theme.textTheme.bodySmall?.copyWith(
                                            color:
                                                theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
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
        ),
      ),
    );
  }
}
