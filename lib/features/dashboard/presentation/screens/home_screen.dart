import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';

/// Main shell with bottom navigation — role-aware tabs.
class HomeScreen extends StatefulWidget {
  final AuthController authController;

  const HomeScreen({super.key, required this.authController});

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
          _NavItem(label: 'Tasks', icon: HugeIcons.strokeRoundedTask01),
          _NavItem(label: 'Schedule', icon: HugeIcons.strokeRoundedCalendar01),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = _auth.selectedRole;
    final items = _navItems;

    // Reset index if out of bounds (e.g. role change)
    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      extendBody: true, // Allows body to flow behind the floating nav bar
      appBar: AppBar(
        title: Text(
          'Nexus',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Kameron',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Sign out',
            onPressed: _auth.logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: items.map((item) {
          if (item.label == 'Home' || item.label == 'Dashboard') {
            return _HomeDashboard(role: role, theme: theme);
          }
          return _PlaceholderTab(label: item.label, theme: theme);
        }).toList(),
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

/// Home dashboard tab content.
class _HomeDashboard extends StatelessWidget {
  final UserRole? role;
  final ThemeData theme;

  const _HomeDashboard({required this.role, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${role?.label ?? 'User'}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Kameron',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your dashboard will appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder tab for unbuilt features.
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
