import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:nexus/core/utils/avatar_utils.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';
import 'package:nexus/features/admin/presentation/screens/users_screen.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/features/deliverables/data/repositories/task_firestore_repository.dart';
import 'package:nexus/features/learning/presentation/screens/learning_screen.dart';
import 'package:nexus/features/meetings/data/repositories/meeting_firestore_repository.dart';
import 'package:nexus/features/profile/presentation/screens/settings_screen.dart';
import 'package:nexus/features/programs/data/repositories/application_firestore_repository.dart';
import 'package:nexus/features/programs/data/repositories/program_firestore_repository.dart';
import 'package:nexus/features/programs/domain/entities/program.dart';
import 'package:nexus/features/programs/presentation/screens/applications_screen.dart';
import 'package:nexus/features/programs/presentation/screens/program_listing_screen.dart';
import 'package:nexus/core/services/firestore_service.dart';
import 'package:nexus/features/messages/presentation/screens/messenger_chat_sheet.dart';
import 'package:nexus/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus/core/services/notification_service.dart';
import 'package:nexus/core/services/presence_service.dart';

class HomeScreen extends StatefulWidget {
  final AuthController authController;
  final ThemeController? themeController;

  const HomeScreen({
    super.key,
    required this.authController,
    this.themeController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final uid = widget.authController.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      NotificationService().initialize(userId: uid);
      PresenceService().initialize(uid);
    } else {
      NotificationService().initialize();
    }
  }

  AuthController get _auth => widget.authController;

  /// Returns the nav items based on user role.
  List<_NavItem> get _navItems {
    final role = _auth.selectedRole;
    switch (role) {
      case UserRole.applicant:
        return const [
          _NavItem(label: 'Home', icon: HugeIcons.strokeRoundedHome01),
          _NavItem(label: 'Discover', icon: HugeIcons.strokeRoundedSearch01),
          _NavItem(label: 'Applications', icon: HugeIcons.strokeRoundedFile01),
          _NavItem(label: 'Settings', icon: HugeIcons.strokeRoundedSettings01),
        ];
      case UserRole.intern:
        return const [
          _NavItem(label: 'Home', icon: HugeIcons.strokeRoundedHome01),
          _NavItem(label: 'Learning', icon: HugeIcons.strokeRoundedBook01),
          _NavItem(
            label: 'Workspace',
            icon: HugeIcons.strokeRoundedBriefcase02,
          ),
          _NavItem(label: 'Settings', icon: HugeIcons.strokeRoundedSettings01),
        ];
      case UserRole.administrator:
        return const [
          _NavItem(
            label: 'Dashboard',
            icon: HugeIcons.strokeRoundedDashboardSquare01,
          ),
          _NavItem(label: 'Users', icon: HugeIcons.strokeRoundedUserGroup),
          _NavItem(label: 'Programs', icon: HugeIcons.strokeRoundedFolder01),
          _NavItem(label: 'Settings', icon: HugeIcons.strokeRoundedSettings01),
        ];
      case null:
        return const [
          _NavItem(label: 'Home', icon: HugeIcons.strokeRoundedHome01),
          _NavItem(label: 'Settings', icon: HugeIcons.strokeRoundedSettings01),
        ];
    }
  }

  /// Returns the screen widget for a given nav item label.
  Widget _screenForLabel(String label, ThemeData theme) {
    switch (label) {
      case 'Home':
      case 'Dashboard':
        return _HomeDashboard(
          authController: _auth,
          theme: theme,
          onExplorePressed: () {
            final items = _navItems;
            final discoverIndex = items.indexWhere(
              (i) => i.label == 'Discover' || i.label == 'Programs',
            );
            if (discoverIndex != -1) {
              setState(() => _currentIndex = discoverIndex);
            }
          },
        );
      case 'Discover':
        return ProgramListingScreen(authController: _auth);
      case 'Applications':
        return const ApplicationsScreen();
      case 'Learning':
        return const LearningScreen();
      case 'Workspace':
        return const WorkspaceScreen();
      case 'Users':
        return const UsersScreen();
      case 'Programs':
        return ProgramListingScreen(authController: _auth);
      case 'Settings':
        return SettingsScreen(
          authController: _auth,
          themeController: widget.themeController,
        );
      default:
        return _PlaceholderTab(label: label, theme: theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _navItems;

    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Excelerate Nexus',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: _AnimatedIndexedStack(
        index: _currentIndex,
        children: items
            .map((item) => _screenForLabel(item.label, theme))
            .toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: _FloatingNavBar(
                  items: items,
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() => _currentIndex = index);
                  },
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => MessengerChatSheet(
                      authController: widget.authController,
                    ),
                  );
                },
                child: StreamBuilder<int>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .snapshots()
                      .map((snap) {
                    final uid = widget.authController.currentUser?.uid ?? '';
                    final email = widget.authController.userEmail.trim().toLowerCase();
                    if (uid.isEmpty) return 0;

                    return snap.docs.where((doc) {
                      final data = doc.data();
                      final senderId = (data['senderId'] as String? ?? '').trim();
                      final senderEmail = (data['senderEmail'] as String? ?? '').trim().toLowerCase();
                      final recipientId = (data['recipientId'] as String? ?? '').trim();
                      final recipientEmail = (data['recipientEmail'] as String? ?? '').trim().toLowerCase();
                      final isRead = data['isRead'] as bool? ?? false;
                      final isUnsent = data['isUnsent'] as bool? ?? false;

                      final isFromOther = senderId.isNotEmpty ? (senderId != uid) : (senderEmail.isNotEmpty && senderEmail != email);
                      final isForMe = (recipientId.isNotEmpty && recipientId == uid) || (email.isNotEmpty && recipientEmail == email);

                      return isForMe && isFromOther && !isRead && !isUnsent;
                    }).length;
                  }),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedBubbleChat,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
}

class _FloatingNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final isSelected = currentIndex == index;
          final item = items[index];

          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: item.icon,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 4 : 0,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Home dashboard tab content — live system database integrated.
class _HomeDashboard extends StatefulWidget {
  final AuthController authController;
  final ThemeData theme;
  final VoidCallback onExplorePressed;

  const _HomeDashboard({
    required this.authController,
    required this.theme,
    required this.onExplorePressed,
  });

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  final ProgramFirestoreRepository _programRepo = ProgramFirestoreRepository();
  final ApplicationFirestoreRepository _appRepo = ApplicationFirestoreRepository();
  final UserFirestoreRepository _userRepo = UserFirestoreRepository();
  final TaskFirestoreRepository _taskRepo = TaskFirestoreRepository();
  final MeetingFirestoreRepository _meetingRepo = MeetingFirestoreRepository();

  bool _isLoading = true;
  String _userAvatar = 'preset_1';
  List<Map<String, dynamic>> _liveStats = [];
  List<Map<String, dynamic>> _liveActivity = [];
  Map<String, dynamic>? _latestApplication;
  Map<String, dynamic>? _nextMeeting;

  ThemeData get theme => widget.theme;
  UserRole? get role => widget.authController.selectedRole;
  String get userDisplayName => widget.authController.userDisplayName;

  String get userInitials {
    final name = userDisplayName.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String get effectiveUserAvatar {
    final authAvatar = widget.authController.avatarUrl;
    if (authAvatar != null && authAvatar.isNotEmpty) {
      return authAvatar;
    }
    return _userAvatar;
  }

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthChanged);
    _checkRoleOnboarding();
    _loadDashboardData();
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkRoleOnboarding() async {
    final user = widget.authController.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('onboarding_completed_${user.uid}') ?? false;
      if (!completed && mounted) {
        context.go('/onboarding');
      }
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = widget.authController.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedAvatar = prefs.getString('user_avatar_${user.uid}');
        if (savedAvatar != null && savedAvatar.isNotEmpty) {
          _userAvatar = savedAvatar;
        }

        final doc = await _userRepo.getUserProfile(user.uid);
        if (doc != null) {
          final docName = doc['name'] as String?;
          final docAvatar = doc['avatar'] as String?;
          if (docName != null && docName.isNotEmpty) {
            widget.authController.updateDisplayName(docName);
          }
          if (docAvatar != null && docAvatar.isNotEmpty) {
            _userAvatar = docAvatar;
          }
        }
      }

      final currentUserId = widget.authController.currentUser?.uid ?? 'guest_user';

      if (role == UserRole.administrator) {
        final users = await _userRepo.getAllUsers();
        final programs = await _programRepo.getPrograms();

        if (mounted) {
          setState(() {
            _liveStats = [
              {
                'label': 'Total Users',
                'value': '${users.length}',
                'icon': HugeIcons.strokeRoundedUserGroup,
              },
              {
                'label': 'Programs',
                'value': '${programs.length}',
                'icon': HugeIcons.strokeRoundedBriefcase02,
              },
              {
                'label': 'System Active',
                'value': '${users.where((u) => u['status'] == 'Active').length}',
                'icon': HugeIcons.strokeRoundedTime02,
              },
            ];

            _liveActivity = users.take(3).map((u) => {
              'title': 'User Registered',
              'subtitle': u['name'] as String? ?? 'New User',
              'time': 'Recent',
              'icon': HugeIcons.strokeRoundedUserAdd01,
            }).toList();

            _isLoading = false;
          });
        }
      } else if (role == UserRole.intern) {
        final tasks = await _taskRepo.getUserTasks(currentUserId);
        final meetings = await _meetingRepo.getUserMeetings(currentUserId);

        final pendingTasks = tasks.where((t) => (t['status'] as String? ?? '') != 'Completed').length;
        final completedTasks = tasks.where((t) => (t['status'] as String? ?? '') == 'Completed').length;

        if (mounted) {
          setState(() {
            _liveStats = [
              {
                'label': 'Tasks Due',
                'value': '$pendingTasks',
                'icon': HugeIcons.strokeRoundedTask01,
              },
              {
                'label': 'Meetings',
                'value': '${meetings.length}',
                'icon': HugeIcons.strokeRoundedCalendar01,
              },
              {
                'label': 'Completed',
                'value': '$completedTasks',
                'icon': HugeIcons.strokeRoundedCheckmarkBadge01,
              },
            ];

            _nextMeeting = meetings.isNotEmpty ? meetings.first : null;

            _liveActivity = tasks.take(3).map((t) => {
              'title': 'Task Update',
              'subtitle': t['title'] as String? ?? 'Deliverable',
              'time': 'Recent',
              'icon': HugeIcons.strokeRoundedTaskDone01,
            }).toList();

            _isLoading = false;
          });
        }
      } else {
        // Applicant or Guest
        final apps = await _appRepo.getUserApplications(currentUserId);
        final pendingApps = apps.where((a) => (a['status'] as String? ?? '') == 'Pending').length;
        final acceptedApps = apps.where((a) => (a['status'] as String? ?? '') == 'Accepted').length;

        if (mounted) {
          setState(() {
            _liveStats = [
              {
                'label': 'Applications',
                'value': '${apps.length}',
                'icon': HugeIcons.strokeRoundedFolder01,
              },
              {
                'label': 'Pending',
                'value': '$pendingApps',
                'icon': HugeIcons.strokeRoundedTime02,
              },
              {
                'label': 'Accepted',
                'value': '$acceptedApps',
                'icon': HugeIcons.strokeRoundedCheckmarkBadge01,
              },
            ];

            _latestApplication = apps.isNotEmpty ? apps.first : null;

            _liveActivity = apps.take(3).map((a) => {
              'title': 'Application Status',
              'subtitle': a['programName'] as String? ?? 'Program',
              'time': 'Recent',
              'icon': HugeIcons.strokeRoundedFile01,
            }).toList();

            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liveStats = [
            {'label': 'Records', 'value': '0', 'icon': HugeIcons.strokeRoundedFolder01},
            {'label': 'Status', 'value': 'Active', 'icon': HugeIcons.strokeRoundedTime02},
            {'label': 'Updates', 'value': '0', 'icon': HugeIcons.strokeRoundedCheckmarkBadge01},
          ];
          _liveActivity = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: _isLoading,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 36),
            _buildHeroCard(context),
            const SizedBox(height: 36),
            _buildStatsRow(context),
            const SizedBox(height: 36),
            Card(
              child: ListTile(
                leading: const Icon(Icons.explore),
                title: const Text('Explore Programs'),
                subtitle: const Text('Find available career development opportunities'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onExplorePressed,
              ),
            ),
            const SizedBox(height: 36),
            _buildActivitySection(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good evening';
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  color: widget.theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userDisplayName,
                style: widget.theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Kameron',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        AvatarUtils.buildAvatarWidget(
          effectiveUserAvatar,
          radius: 24,
          fallbackLetter: userDisplayName,
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    switch (role) {
      case UserRole.applicant:
        return _ApplicantHero(
          theme: theme,
          latestApp: _latestApplication,
        );
      case UserRole.intern:
        return _InternHero(
          theme: theme,
          nextMeeting: _nextMeeting,
        );
      case UserRole.administrator:
        return _AdminHero(theme: theme);
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatsRow(BuildContext context) {
    if (role == UserRole.administrator) {
      return _buildAdminSparklineHUD(context);
    } else {
      return _buildUnifiedDataBar(context);
    }
  }

  Widget _buildUnifiedDataBar(BuildContext context) {
    if (_liveStats.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          if (_liveStats.isNotEmpty)
            Expanded(child: _UnifiedDataSegment(stat: _liveStats[0], theme: theme)),
          if (_liveStats.length > 1) ...[
            Container(width: 1, height: 60, color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            Expanded(child: _UnifiedDataSegment(stat: _liveStats[1], theme: theme)),
          ],
          if (_liveStats.length > 2) ...[
            Container(width: 1, height: 60, color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            Expanded(child: _UnifiedDataSegment(stat: _liveStats[2], theme: theme)),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminSparklineHUD(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userRepo.streamAllUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        final totalUsersCount = users.isNotEmpty ? users.length : (_liveStats.isNotEmpty ? int.tryParse(_liveStats[0]['value'] as String? ?? '0') ?? 0 : 0);
        final activeUsersCount = users.where((u) {
          final status = (u['status'] as String? ?? '').trim().toLowerCase();
          final lastSeenStr = u['lastSeen'] as String? ?? '';
          if (status == 'active' || status == 'online') return true;
          if (lastSeenStr.isNotEmpty) {
            final ls = DateTime.tryParse(lastSeenStr);
            if (ls != null && DateTime.now().difference(ls).inMinutes <= 3) {
              return true;
            }
          }
          return false;
        }).length;

        final programsCount = _liveStats.length > 1 ? _liveStats[1]['value'] as String? ?? '0' : '0';

        final updatedStats = [
          {
            'label': 'Total Users',
            'value': '$totalUsersCount',
            'icon': HugeIcons.strokeRoundedUserGroup,
          },
          {
            'label': 'Programs',
            'value': programsCount,
            'icon': HugeIcons.strokeRoundedBriefcase02,
          },
          {
            'label': 'System Active',
            'value': '$activeUsersCount',
            'icon': HugeIcons.strokeRoundedTime02,
          },
        ];

        return Container(
          height: 160,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                top: 40,
                child: CustomPaint(
                  painter: _SparklinePainter(color: theme.colorScheme.primary),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(child: _UnifiedDataSegment(stat: updatedStats[0], theme: theme, isTransparent: true)),
                    Expanded(child: _UnifiedDataSegment(stat: updatedStats[1], theme: theme, isTransparent: true)),
                    Expanded(child: _UnifiedDataSegment(stat: updatedStats[2], theme: theme, isTransparent: true)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _liveActivity.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No recent system activity.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Column(
                children: _liveActivity.map((activity) {
                  return _ModernActivityRow(
                    title: activity['title'] as String? ?? '',
                    subtitle: activity['subtitle'] as String? ?? '',
                    time: activity['time'] as String? ?? '',
                    icon: activity['icon'] as List<List<dynamic>>,
                    theme: theme,
                  );
                }).toList(),
              ),
      ],
    );
  }
}

class _ApplicantHero extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic>? latestApp;

  const _ApplicantHero({required this.theme, this.latestApp});

  @override
  Widget build(BuildContext context) {
    final title = latestApp?['programName'] as String? ?? 'No Active Application';
    final status = latestApp?['status'] as String? ?? 'Pending';
    final isReviewed = status == 'Accepted' || status == 'Reviewed';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBriefcase02,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Application Status',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildStep('Submitted', true),
              _buildLine(isReviewed),
              _buildStep('Review', isReviewed),
              _buildLine(status == 'Accepted'),
              _buildStep('Decision', status == 'Accepted'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? theme.colorScheme.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: active
              ? Center(
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
      ),
    );
  }
}

class _InternHero extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic>? nextMeeting;

  const _InternHero({required this.theme, this.nextMeeting});

  @override
  Widget build(BuildContext context) {
    final title = nextMeeting?['title'] as String? ?? 'Sprint 1 Standup & Code Review';
    final subtitle = nextMeeting?['description'] as String? ?? 'Weekly mentor sync with engineering leads';
    final timeStr = nextMeeting?['time'] as String? ?? 'Today • 2:00 PM';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UP NEXT • SPRINT SYNC',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Kameron',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.video_call_rounded, size: 20),
                label: const Text('Join Live Session'),
                onPressed: () {
                  showGlassSnackbar(
                    context,
                    'Joining $title...',
                    type: SnackbarType.info,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  showGlassSnackbar(
                    context,
                    'Meeting invite copied to clipboard!',
                    type: SnackbarType.success,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Copy Link'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminHero extends StatelessWidget {
  final ThemeData theme;
  const _AdminHero({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAction(
              context,
              HugeIcons.strokeRoundedUserAdd01,
              'Add User',
              theme,
              () => _handleAddUser(context, theme),
            ),
            _buildAction(
              context,
              HugeIcons.strokeRoundedFolderAdd,
              'New Program',
              theme,
              () => _handleNewProgram(context, theme),
            ),
            _buildAction(
              context,
              HugeIcons.strokeRoundedAnalytics01,
              'Reports',
              theme,
              () => _handleReports(context, theme),
            ),
            _buildAction(
              context,
              HugeIcons.strokeRoundedNotification01,
              'Broadcast',
              theme,
              () => _handleBroadcast(context, theme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAction(
    BuildContext context,
    List<List<dynamic>> icon,
    String label,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                size: 24,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(
    BuildContext context,
    ThemeData theme,
    String title,
    Widget content,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
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
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Kameron',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                content,
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAddUser(BuildContext context, ThemeData theme) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final userRepo = UserFirestoreRepository();
    String selectedRole = 'Intern';

    _showActionSheet(
      context,
      theme,
      'Add New User',
      StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Assigned Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Intern', 'Applicant', 'Administrator']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setSheetState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty || email.isEmpty) return;

                    Navigator.pop(context);
                    try {
                      final docId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
                      await userRepo.setUserProfile(
                        uid: docId,
                        name: name,
                        email: email,
                        role: selectedRole,
                      );
                      if (context.mounted) {
                        showGlassSnackbar(
                          context,
                          'Added $selectedRole "$name" to system database',
                          type: SnackbarType.success,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
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
          );
        },
      ),
    );
  }

  void _handleNewProgram(BuildContext context, ThemeData theme) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final programRepo = ProgramFirestoreRepository();

    _showActionSheet(
      context,
      theme,
      'Create New Program',
      Column(
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Program Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(context);
                try {
                  await programRepo.addProgram(Program(
                    id: '',
                    title: name,
                    description: desc.isNotEmpty ? desc : 'Program description',
                    imageUrl: '',
                    duration: '12 Weeks',
                    level: 'Intermediate',
                  ));
                  if (context.mounted) {
                    showGlassSnackbar(
                      context,
                      'Program created in system database',
                      type: SnackbarType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showGlassSnackbar(
                      context,
                      'Error creating program: $e',
                      type: SnackbarType.error,
                    );
                  }
                }
              },
              child: const Text('Create Program'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleReports(BuildContext context, ThemeData theme) {
    _showActionSheet(
      context,
      theme,
      'Generate System Report',
      Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.picture_as_pdf,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Export as PDF'),
            onTap: () {
              Navigator.pop(context);
              showGlassSnackbar(context, 'Exporting PDF system report...');
            },
          ),
          ListTile(
            leading: Icon(Icons.table_chart, color: theme.colorScheme.primary),
            title: const Text('Export as CSV'),
            onTap: () {
              Navigator.pop(context);
              showGlassSnackbar(context, 'Exporting CSV data sheet...');
            },
          ),
        ],
      ),
    );
  }

  void _handleBroadcast(BuildContext context, ThemeData theme) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String targetAudience = 'All Users';

    _showActionSheet(
      context,
      theme,
      'Send System Broadcast',
      StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Announcement Title',
                hintText: 'e.g. System Maintenance / Live Q&A',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message Content',
                hintText: 'Write broadcast details for target users...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: targetAudience,
              decoration: InputDecoration(
                labelText: 'Target Audience',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ['All Users', 'Interns', 'Applicants']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setSheetState(() => targetAudience = val);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send Broadcast'),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final msg = messageController.text.trim();
                  if (title.isEmpty || msg.isEmpty) return;

                  Navigator.pop(context);
                  try {
                    final firestore = FirestoreService();
                    final timestamp = DateTime.now().toIso8601String();
                    await firestore.addDocument('announcements', {
                      'title': title,
                      'content': msg,
                      'target': targetAudience,
                      'timestamp': timestamp,
                    });

                    final broadCastText = title.isNotEmpty ? '$title\n\n$msg' : msg;
                    await firestore.addDocument('messages', {
                      'senderId': 'nexus_announcement',
                      'senderName': 'Nexus Announcement',
                      'senderEmail': 'announcement@nexus.com',
                      'recipientId': 'general',
                      'recipientName': 'Nexus Announcement',
                      'recipientEmail': 'announcement@nexus.com',
                      'targetAudience': targetAudience,
                      'body': broadCastText,
                      'content': broadCastText,
                      'avatar': 'assets/icons/app_logo.png',
                      'timestamp': timestamp,
                      'isBroadcast': true,
                      'isGeneral': true,
                      'isRead': false,
                      'reactions': {},
                    });

                    NotificationService().showChatPushNotification(
                      senderName: 'Nexus Announcement 📢',
                      messageText: title.isNotEmpty ? title : msg,
                    );

                    if (context.mounted) {
                      showGlassSnackbar(
                        context,
                        'Announcement broadcast to Nexus Announcement!',
                        type: SnackbarType.success,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showGlassSnackbar(
                        context,
                        'Error sending broadcast: $e',
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
    );
  }
}

class _UnifiedDataSegment extends StatelessWidget {
  final Map<String, dynamic> stat;
  final ThemeData theme;
  final bool isTransparent;

  const _UnifiedDataSegment({
    required this.stat,
    required this.theme,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (stat['icon'] != null) ...[
          HugeIcon(
            icon: stat['icon'] as List<List<dynamic>>,
            color: isTransparent
                ? theme.colorScheme.onSurface
                : theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          stat['value'] as String? ?? '0',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Kameron',
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat['label'] as String? ?? 'Record',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.9,
      size.width * 0.4,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.1,
      size.width * 0.8,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.6,
      size.width,
      size.height * 0.3,
    );

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModernActivityRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final List<List<dynamic>> icon;
  final ThemeData theme;

  const _ModernActivityRow({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                size: 22,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _PlaceholderTab({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final List<List<dynamic>> icon;

  const _NavItem({required this.label, required this.icon});
}

class _AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _AnimatedIndexedStack({
    required this.index,
    required this.children,
  });

  @override
  State<_AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<_AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() => _currentIndex = widget.index);
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: IndexedStack(index: _currentIndex, children: widget.children),
      ),
    );
  }
}
