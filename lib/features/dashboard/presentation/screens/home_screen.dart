import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:nexus/features/programs/presentation/screens/discover_screen.dart';
import 'package:nexus/features/programs/presentation/screens/applications_screen.dart';
import 'package:nexus/features/learning/presentation/screens/learning_screen.dart';
import 'package:nexus/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:nexus/features/admin/presentation/screens/users_screen.dart';
import 'package:nexus/features/admin/presentation/screens/programs_management_screen.dart';
import 'package:nexus/features/profile/presentation/screens/settings_screen.dart';

/// Main shell with bottom navigation — role-aware tabs.
class HomeScreen extends StatefulWidget {
  final AuthController authController;
  final ThemeController? themeController;

  const HomeScreen({super.key, required this.authController, this.themeController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
          _NavItem(label: 'Workspace', icon: HugeIcons.strokeRoundedBriefcase02),
          _NavItem(label: 'Settings', icon: HugeIcons.strokeRoundedSettings01),
        ];
      case UserRole.administrator:
        return const [
          _NavItem(label: 'Dashboard', icon: HugeIcons.strokeRoundedDashboardSquare01),
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
        return _HomeDashboard(role: _auth.selectedRole, theme: theme);
      case 'Discover':
        return const DiscoverScreen();
      case 'Applications':
        return const ApplicationsScreen();
      case 'Learning':
        return const LearningScreen();
      case 'Workspace':
        return const WorkspaceScreen();
      case 'Users':
        return const UsersScreen();
      case 'Programs':
        return const ProgramsManagementScreen();
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

    // Reset index if out of bounds (e.g. role change)
    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      extendBody: true, // Allows body to flow behind the floating nav bar
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
        children: items.map((item) => _screenForLabel(item.label, theme)).toList(),
      ),
      bottomNavigationBar: _FloatingNavBar(
        items: items,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

/// Custom aesthetic floating navigation bar.
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
                  width: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: item.icon,
                        size: 22,
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
        ),
      ),
    );
  }
}

/// Home dashboard tab content — role-aware.
class _HomeDashboard extends StatelessWidget {
  final UserRole? role;
  final ThemeData theme;

  const _HomeDashboard({required this.role, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          _buildActivitySection(context),
          const SizedBox(height: 80),
        ],
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role?.label ?? 'User',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedUserCircle,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    switch (role) {
      case UserRole.applicant:
        return _ApplicantHero(theme: theme);
      case UserRole.intern:
        return _InternHero(theme: theme);
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
    final stats = _statsCards;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(child: _UnifiedDataSegment(stat: stats[0], theme: theme)),
          Container(width: 1, height: 60, color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          Expanded(child: _UnifiedDataSegment(stat: stats[1], theme: theme)),
          Container(width: 1, height: 60, color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          Expanded(child: _UnifiedDataSegment(stat: stats[2], theme: theme)),
        ],
      ),
    );
  }

  Widget _buildAdminSparklineHUD(BuildContext context) {
    final stats = _statsCards;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
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
                Expanded(child: _UnifiedDataSegment(stat: stats[0], theme: theme, isTransparent: true)),
                Expanded(child: _UnifiedDataSegment(stat: stats[1], theme: theme, isTransparent: true)),
                Expanded(child: _UnifiedDataSegment(stat: stats[2], theme: theme, isTransparent: true)),
              ],
            ),
          ),
        ],
      ),
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
        ..._recentActivity.map((activity) => _ModernActivityRow(
              title: activity['title'] as String,
              subtitle: activity['subtitle'] as String,
              time: activity['time'] as String,
              icon: activity['icon'] as List<List<dynamic>>,
              theme: theme,
            )),
      ],
    );
  }

  List<Map<String, dynamic>> get _statsCards {
    switch (role) {
      case UserRole.applicant:
        return [
          {'label': 'Applications', 'value': '3', 'icon': HugeIcons.strokeRoundedFolder01},
          {'label': 'Pending', 'value': '1', 'icon': HugeIcons.strokeRoundedTime02},
          {'label': 'Accepted', 'value': '1', 'icon': HugeIcons.strokeRoundedCheckmarkBadge01},
        ];
      case UserRole.intern:
        return [
          {'label': 'Tasks Due', 'value': '3', 'icon': HugeIcons.strokeRoundedTask01},
          {'label': 'Meetings', 'value': '2', 'icon': HugeIcons.strokeRoundedCalendar01},
          {'label': 'Completed', 'value': '5', 'icon': HugeIcons.strokeRoundedCheckmarkBadge01},
        ];
      case UserRole.administrator:
        return [
          {'label': 'Users', 'value': '42', 'icon': HugeIcons.strokeRoundedUserGroup},
          {'label': 'Programs', 'value': '3', 'icon': HugeIcons.strokeRoundedBriefcase02},
          {'label': 'Pending', 'value': '8', 'icon': HugeIcons.strokeRoundedTime02},
        ];
      case null:
        return [{'label': 'Status', 'value': '—'}];
    }
  }

  List<Map<String, dynamic>> get _recentActivity {
    switch (role) {
      case UserRole.applicant:
        return [
          {'title': 'Application Submitted', 'subtitle': 'Frontend Web Dev', 'time': '2h ago', 'icon': HugeIcons.strokeRoundedFile01},
          {'title': 'Status Updated', 'subtitle': 'Data Science Internship', 'time': '1d ago', 'icon': HugeIcons.strokeRoundedNotification01},
        ];
      case UserRole.intern:
        return [
          {'title': 'Task Completed', 'subtitle': 'Weekly Progress Report', 'time': '1h ago', 'icon': HugeIcons.strokeRoundedTaskDone01},
          {'title': 'Meeting Scheduled', 'subtitle': 'Mentor Check-in', 'time': '3h ago', 'icon': HugeIcons.strokeRoundedCalendar01},
        ];
      case UserRole.administrator:
        return [
          {'title': 'New Application', 'subtitle': 'James Chen', 'time': '30m ago', 'icon': HugeIcons.strokeRoundedUserAdd01},
          {'title': 'Program Updated', 'subtitle': 'Frontend Web Dev', 'time': '1d ago', 'icon': HugeIcons.strokeRoundedFolder01},
        ];
      case null:
        return [];
    }
  }
}

class _ApplicantHero extends StatelessWidget {
  final ThemeData theme;
  const _ApplicantHero({required this.theme});

  @override
  Widget build(BuildContext context) {
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
              HugeIcon(icon: HugeIcons.strokeRoundedBriefcase02, size: 20, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text('Application Status', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Frontend Web Development', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimaryContainer)),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildStep('Applied', true),
              _buildLine(true),
              _buildStep('Review', true),
              _buildLine(false),
              _buildStep('Decision', false),
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
              color: active ? theme.colorScheme.primary : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: active ? Center(child: Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)) : null,
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: active ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
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
        color: active ? theme.colorScheme.primary : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
      ),
    );
  }
}

class _InternHero extends StatelessWidget {
  final ThemeData theme;
  const _InternHero({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: theme.colorScheme.onPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('Up Next', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text('In 30 mins', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.9))),
            ],
          ),
          const SizedBox(height: 24),
          Text('Mentor Sync: Sprint Review', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary)),
          const SizedBox(height: 8),
          Text('Video call with Sarah Jenkins', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.9))),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Join Call', style: TextStyle(fontWeight: FontWeight.w700)),
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
        Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAction(context, HugeIcons.strokeRoundedUserAdd01, 'Add User', theme, () => _handleAddUser(context, theme)),
            _buildAction(context, HugeIcons.strokeRoundedFolderAdd, 'New Program', theme, () => _handleNewProgram(context, theme)),
            _buildAction(context, HugeIcons.strokeRoundedAnalytics01, 'Reports', theme, () => _handleReports(context, theme)),
            _buildAction(context, HugeIcons.strokeRoundedSettings02, 'Settings', theme, () => _handleSettings(context, theme)),
          ],
        ),
      ],
    );
  }

  Widget _buildAction(BuildContext context, List<List<dynamic>> icon, String label, ThemeData theme, VoidCallback onTap) {
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
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: Center(child: HugeIcon(icon: icon, size: 24, color: theme.colorScheme.primary)),
          ),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, ThemeData theme, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
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
    _showActionSheet(context, theme, 'Add New User', Column(
      children: [
        TextField(decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 16),
        TextField(decoration: InputDecoration(labelText: 'Role (e.g. Intern, Manager)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () { Navigator.pop(context); showGlassSnackbar(context, 'Invite sent', type: SnackbarType.success); },
            child: const Text('Send Invite'),
          ),
        )
      ]
    ));
  }

  void _handleNewProgram(BuildContext context, ThemeData theme) {
    _showActionSheet(context, theme, 'Create New Program', Column(
      children: [
        TextField(decoration: InputDecoration(labelText: 'Program Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 16),
        TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () { Navigator.pop(context); showGlassSnackbar(context, 'Program created', type: SnackbarType.success); },
            child: const Text('Create Program'),
          ),
        )
      ]
    ));
  }

  void _handleReports(BuildContext context, ThemeData theme) {
    _showActionSheet(context, theme, 'Generate Report', Column(
      children: [
        ListTile(
          leading: Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
          title: const Text('Export as PDF'),
          onTap: () { Navigator.pop(context); showGlassSnackbar(context, 'Downloading PDF...'); },
        ),
        ListTile(
          leading: Icon(Icons.table_chart, color: theme.colorScheme.primary),
          title: const Text('Export as CSV'),
          onTap: () { Navigator.pop(context); showGlassSnackbar(context, 'Downloading CSV...'); },
        ),
      ]
    ));
  }

  void _handleSettings(BuildContext context, ThemeData theme) {
     showGlassSnackbar(context, 'Use the Settings tab below to configure platform preferences.');
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
            color: isTransparent ? theme.colorScheme.onSurface : theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          stat['value'] as String,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Kameron',
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat['label'] as String,
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
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.9, size.width * 0.4, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.1, size.width * 0.8, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.6, size.width, size.height * 0.3);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.0),
        ],
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
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: HugeIcon(icon: icon, size: 22, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Placeholder tab for any remaining unbuilt features.
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

/// Internal model for nav items.
class _NavItem {
  final String label;
  final List<List<dynamic>> icon;

  const _NavItem({required this.label, required this.icon});
}

class _AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _AnimatedIndexedStack({
    Key? key,
    required this.index,
    required this.children,
  }) : super(key: key);

  @override
  State<_AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<_AnimatedIndexedStack> with SingleTickerProviderStateMixin {
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
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
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
        child: IndexedStack(
          index: _currentIndex,
          children: widget.children,
        ),
      ),
    );
  }
}

