 import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus/core/utils/legal_docs_sheets.dart';
import 'package:nexus/core/utils/app_version.dart';
import 'package:flutter/services.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';
import 'package:nexus/core/utils/avatar_utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';

/// Settings screen — shared across all roles, fully interactive.
class SettingsScreen extends StatefulWidget {
  final AuthController authController;
  final ThemeController? themeController;

  const SettingsScreen({
    super.key,
    required this.authController,
    this.themeController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = 'Nexus User';
  String _avatarKey = 'preset_1';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = widget.authController.currentUser;
    String name = widget.authController.userDisplayName;
    String avatar = 'preset_1';

    if (user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        name = prefs.getString('user_name_${user.uid}') ?? name;
        avatar = prefs.getString('user_avatar_${user.uid}') ?? 'preset_1';

        final repo = UserFirestoreRepository();
        final doc = await repo.getUser(user.uid);
        if (doc != null) {
          if ((doc['name'] as String? ?? '').isNotEmpty) name = doc['name'] as String;
          if ((doc['avatar'] as String? ?? '').isNotEmpty) avatar = doc['avatar'] as String;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _name = name;
        _avatarKey = avatar;
      });
    }
  }

  void _showProfileSheet(BuildContext context, ThemeData theme) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProfileSheetContent(theme: theme, authController: widget.authController),
    );
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = widget.authController.selectedRole;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 120, // Extra padding to clear the bottom navigation bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Kameron',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Profile card
          GestureDetector(
            onTap: () => _showProfileSheet(context, theme),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  AvatarUtils.buildAvatarWidget(_avatarKey, radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          role?.label ?? 'User',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Settings items
          _buildSettingsGroup(context, theme, [
            _SettingsItem(
              icon: HugeIcons.strokeRoundedNotification01,
              label: 'Notifications',
              onTap: () => _showNotificationPreferencesSheet(context, theme),
            ),
            _SettingsItem(
              icon: HugeIcons.strokeRoundedMoon02,
              label: 'Appearance',
              onTap: () => _showAppearanceSheet(context),
            ),
            _SettingsItem(
              icon: HugeIcons.strokeRoundedLockPassword,
              label: 'Privacy & Security',
              onTap: () => _showPrivacyAndSecuritySheet(context, theme),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSettingsGroup(context, theme, [
            _SettingsItem(
              icon: HugeIcons.strokeRoundedHelpCircle,
              label: 'Help & Support',
              onTap: () => context.go('/feedback'),
            ),
            _SettingsItem(
              icon: HugeIcons.strokeRoundedFile01,
              label: 'Terms of Service',
              onTap: () => showTosSheet(context, theme),
            ),
            _SettingsItem(
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              label: 'Privacy Policy',
              onTap: () => showPrivacySheet(context, theme),
            ),
            _SettingsItem(
              icon: HugeIcons.strokeRoundedInformationCircle,
              label: 'About Nexus',
              onTap: () => _showAboutSheet(context, theme),
            ),
            _SettingsItem(
              icon: HugeIcons.strokeRoundedClock01,
              label: 'Changelog',
              onTap: () => _showChangelogSheet(context, theme),
            ),
          ]),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: widget.authController.logout,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedLogout01,
                size: 18,
                color: Colors.red.shade400,
              ),
              label: Text(
                'Sign Out',
                style: TextStyle(color: Colors.red.shade400),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.red.shade400.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Nexus v${AppVersion.currentVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationPreferencesSheet(BuildContext context, ThemeData theme) async {
    final prefs = await SharedPreferences.getInstance();
    bool chatEnabled = prefs.getBool('chat_notifications_enabled') ?? true;
    bool announceEnabled = prefs.getBool('announcements_enabled') ?? true;
    bool soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
    bool vibrationEnabled = prefs.getBool('notification_vibration_enabled') ?? true;

    if (!context.mounted) return;

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
              Text(
                'Notification Preferences',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Kameron',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Chat Push Notifications'),
                subtitle: const Text('Receive heads-up banners for incoming messages'),
                value: chatEnabled,
                onChanged: (val) async {
                  await prefs.setBool('chat_notifications_enabled', val);
                  setSheetState(() => chatEnabled = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('System Announcements'),
                subtitle: const Text('Get notified of admin broadcasts and program updates'),
                value: announceEnabled,
                onChanged: (val) async {
                  await prefs.setBool('announcements_enabled', val);
                  setSheetState(() => announceEnabled = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notification Sound'),
                subtitle: const Text('Play sound on incoming notifications'),
                value: soundEnabled,
                onChanged: (val) async {
                  await prefs.setBool('notification_sound_enabled', val);
                  setSheetState(() => soundEnabled = val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vibration Alert'),
                subtitle: const Text('Vibrate on incoming notifications'),
                value: vibrationEnabled,
                onChanged: (val) async {
                  await prefs.setBool('notification_vibration_enabled', val);
                  setSheetState(() => vibrationEnabled = val);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    showGlassSnackbar(context, '$label — coming soon');
  }

  void _showSnack(BuildContext context, String msg, {SnackbarType type = SnackbarType.info}) {
    showGlassSnackbar(context, msg, type: type);
  }

  void _showPrivacyAndSecuritySheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Privacy & Security',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your security locks and session protection',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const _SettingsSwitchItem(
              icon: HugeIcons.strokeRoundedShield02,
              label: 'Biometric Authentication',
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedLockPassword,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              title: const Text('Session Security'),
              subtitle: const Text('Automatic session revocation on role changes or 3 failed biometric attempts'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAppearanceSheet(BuildContext context) {
    if (widget.themeController == null) {
      _showSnack(context, 'Appearance settings');
      return;
    }

    final tc = widget.themeController!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListenableBuilder(
        listenable: tc,
        builder: (innerContext, _) {
          final currentMode = tc.themeMode;
          final dynamicTheme = Theme.of(innerContext);

          return Padding(
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
                      color: dynamicTheme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Appearance',
                  style: dynamicTheme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Kameron',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your preferred theme mode',
                  style: dynamicTheme.textTheme.bodyMedium?.copyWith(
                    color: dynamicTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _AppearanceOption(
                  icon: Icons.brightness_auto_outlined,
                  label: 'System Default',
                  subtitle: 'Follows your device settings',
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () => tc.setThemeMode(ThemeMode.system),
                  theme: dynamicTheme,
                ),
                const SizedBox(height: 8),
                _AppearanceOption(
                  icon: Icons.light_mode_outlined,
                  label: 'Light',
                  subtitle: 'Always use light theme',
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () => tc.setThemeMode(ThemeMode.light),
                  theme: dynamicTheme,
                ),
                const SizedBox(height: 8),
                _AppearanceOption(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark',
                  subtitle: 'Always use dark theme',
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () => tc.setThemeMode(ThemeMode.dark),
                  theme: dynamicTheme,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // Profile sheet logic moved to _ProfileSheetContent

  void _showAboutSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Nexus',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version ${AppVersion.currentVersion}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Excelerate Nexus is the unified digital ecosystem for Excelerate. '
              'Centralizing program discovery, applications, internships, '
              'collaboration, learning, and evaluation on a single platform.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showChangelogSheet(BuildContext context, ThemeData theme) {
    String selectedFilter = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What\'s New in Nexus',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Kameron',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Release History & Feature Updates',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: FutureBuilder<String>(
                      future: rootBundle.loadString('CHANGELOG.md'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text('Failed to load changelog.'));
                        }
                        final mdData = snapshot.data ?? 'No changelog available.';
                        final allReleases = _parseChangelogData(mdData);

                        if (allReleases.isEmpty) {
                          return const Center(child: Text('No structured release notes found.'));
                        }

                        final filteredReleases = selectedFilter == 'All'
                            ? allReleases
                            : allReleases.where((r) => r.version == selectedFilter).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Version Filter Chips Bar (0 Scrolling Fatigue)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('All'),
                                    selected: selectedFilter == 'All',
                                    onSelected: (_) => setSheetState(() => selectedFilter = 'All'),
                                  ),
                                  ...allReleases.map((r) => Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: ChoiceChip(
                                      label: Text(r.version),
                                      selected: selectedFilter == r.version,
                                      onSelected: (_) => setSheetState(() => selectedFilter = r.version),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Release Accordion Cards
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                padding: EdgeInsets.zero,
                                itemCount: filteredReleases.length,
                                itemBuilder: (context, index) {
                                  final release = filteredReleases[index];
                                  final isLatest = release.version == allReleases.first.version;
                                  return _buildChangelogCard(context, theme, release, isLatest);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<_ChangelogRelease> _parseChangelogData(String mdData) {
    final releases = <_ChangelogRelease>[];
    final lines = mdData.split('\n');

    String? currentVersion;
    String currentDate = '';
    String? currentCategory;
    Map<String, List<_ChangelogItem>> currentCategories = {};

    void saveCurrent() {
      final v = currentVersion;
      if (v != null && currentCategories.isNotEmpty) {
        releases.add(_ChangelogRelease(
          version: v,
          date: currentDate,
          categories: Map.from(currentCategories),
        ));
      }
    }

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('## [')) {
        saveCurrent();
        currentCategories = {};
        currentCategory = null;

        final vMatch = RegExp(r'##\s*\[([^\]]+)\](?:\([^\)]+\))?\s*(?:-\s*|\()?(\d{4}-\d{2}-\d{2})?').firstMatch(line);
        if (vMatch != null) {
          currentVersion = 'v${vMatch.group(1)}';
          currentDate = vMatch.group(2) ?? '';
        } else {
          currentVersion = line.replaceFirst('##', '').trim();
          currentDate = '';
        }
      } else if (line.startsWith('### ')) {
        final cat = line.replaceFirst('### ', '').trim();
        currentCategory = cat;
        currentCategories.putIfAbsent(cat, () => []);
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        final rawItem = line.substring(2).trim();
        if (rawItem.isNotEmpty) {
          final cat = currentCategory ?? 'Updates';
          currentCategory = cat;
          currentCategories.putIfAbsent(cat, () => []);

          String title = '';
          String detail = rawItem;

          if (rawItem.contains('**')) {
            final parts = rawItem.split('**');
            if (parts.length >= 3) {
              title = parts[1].trim();
              detail = parts.sublist(2).join('**').trim();
              if (detail.startsWith(':')) {
                detail = detail.substring(1).trim();
              }
            }
          } else if (rawItem.contains(':')) {
            final idx = rawItem.indexOf(':');
            title = rawItem.substring(0, idx).trim();
            detail = rawItem.substring(idx + 1).trim();
          }

          currentCategories[cat]!.add(
            _ChangelogItem(title: title, detail: detail),
          );
        }
      }
    }
    saveCurrent();

    // Sort releases in strict numerical descending order (highest version number first)
    releases.sort((a, b) {
      final vA = a.version.replaceAll('v', '').trim();
      final vB = b.version.replaceAll('v', '').trim();
      return _compareSemVer(vB, vA);
    });

    return releases;
  }

  int _compareSemVer(String v1, String v2) {
    final p1 = v1.split('.').map((e) => int.tryParse(RegExp(r'\d+').stringMatch(e) ?? '0') ?? 0).toList();
    final p2 = v2.split('.').map((e) => int.tryParse(RegExp(r'\d+').stringMatch(e) ?? '0') ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final n1 = i < p1.length ? p1[i] : 0;
      final n2 = i < p2.length ? p2[i] : 0;
      if (n1 != n2) return n1.compareTo(n2);
    }
    return 0;
  }

  Widget _buildChangelogCard(
    BuildContext context,
    ThemeData theme,
    _ChangelogRelease release,
    bool isLatest,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.18),
          width: isLatest ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLatest
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isLatest,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLatest
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  release.version,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isLatest
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLatest) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LATEST',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF34C759),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (release.date.isNotEmpty)
                Text(
                  release.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: release.categories.entries.map((catEntry) {
                final catName = catEntry.key;
                final items = catEntry.value;

                Color catColor = theme.colorScheme.primary;
                IconData catIcon = Icons.stars_rounded;

                if (catName.toLowerCase().contains('add')) {
                  catColor = const Color(0xFF34C759);
                  catIcon = Icons.add_circle_outline_rounded;
                } else if (catName.toLowerCase().contains('change')) {
                  catColor = const Color(0xFF007AFF);
                  catIcon = Icons.published_with_changes_rounded;
                } else if (catName.toLowerCase().contains('fix')) {
                  catColor = const Color(0xFFAF52DE);
                  catIcon = Icons.bug_report_outlined;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag Badge
                      Row(
                        children: [
                          Icon(catIcon, color: catColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            catName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: catColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // List of item tiles
                      ...items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: catColor.withValues(alpha: 0.6),
                                width: 3.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.title.isNotEmpty)
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              if (item.title.isNotEmpty && item.detail.isNotEmpty)
                                const SizedBox(height: 4),
                              if (item.detail.isNotEmpty)
                                Text(
                                  item.detail,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    ThemeData theme,
    List<Widget> items,
  ) {
    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              item,
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 52,
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}

class _SettingsSwitchItem extends StatefulWidget {
  final List<List<dynamic>> icon;
  final String label;

  const _SettingsSwitchItem({
    required this.icon,
    required this.label,
  });

  @override
  State<_SettingsSwitchItem> createState() => _SettingsSwitchItemState();
}

class _SettingsSwitchItemState extends State<_SettingsSwitchItem> {
  bool _value = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _value = prefs.getBool('biometric_enabled') ?? false;
      });
    }
  }

  Future<void> _handleToggle(bool val) async {
    if (val) {
      try {
        final isAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (!isAvailable) {
          _showSnack('Biometric authentication is not supported on this device');
          return;
        }
        final authenticated = await _auth.authenticate(
          localizedReason: 'Authenticate to enable biometric login for Nexus',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (authenticated) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('biometric_enabled', true);
          if (mounted) setState(() => _value = true);
          _showSnack('Biometric login enabled', type: SnackbarType.success);
        }
      } catch (e) {
        _showSnack('Error enabling biometrics: $e', type: SnackbarType.error);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      if (mounted) setState(() => _value = false);
      _showSnack('Biometric login disabled', type: SnackbarType.warning);
    }
  }

  void _showSnack(String msg, {SnackbarType type = SnackbarType.info}) {
    if (mounted) showGlassSnackbar(context, msg, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: HugeIcon(
        icon: widget.icon,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(widget.label),
      value: _value,
      onChanged: _handleToggle,
    );
  }
}

class _ProfileSheetContent extends StatefulWidget {
  final ThemeData theme;
  final AuthController authController;

  const _ProfileSheetContent({required this.theme, required this.authController});

  @override
  State<_ProfileSheetContent> createState() => _ProfileSheetContentState();
}

class _ProfileSheetContentState extends State<_ProfileSheetContent> {
  bool _isEditing = false;
  bool _isLoading = true;
  String _name = 'Nexus User';
  String _email = 'user@nexus.com';
  String _selectedAvatar = 'preset_1';

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = widget.authController.currentUser;
    String name = widget.authController.userDisplayName;
    String email = widget.authController.userEmail;
    String avatar = 'preset_1';

    if (user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        name = prefs.getString('user_name_${user.uid}') ?? name;
        email = prefs.getString('user_email_${user.uid}') ?? email;
        avatar = prefs.getString('user_avatar_${user.uid}') ?? 'preset_1';

        final repo = UserFirestoreRepository();
        final doc = await repo.getUser(user.uid);
        if (doc != null) {
          if ((doc['name'] as String? ?? '').isNotEmpty) name = doc['name'] as String;
          if ((doc['email'] as String? ?? '').isNotEmpty) email = doc['email'] as String;
          if ((doc['avatar'] as String? ?? '').isNotEmpty) avatar = doc['avatar'] as String;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _name = name;
        _email = email;
        _selectedAvatar = avatar;
        _nameController = TextEditingController(text: _name);
        _emailController = TextEditingController(text: _email);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final user = widget.authController.currentUser;

    if (newName.isNotEmpty) {
      widget.authController.updateDisplayName(newName);
    }

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name_${user.uid}', newName);
      await prefs.setString('user_email_${user.uid}', newEmail);
      await widget.authController.updateAvatar(_selectedAvatar);
      try {
        final repo = UserFirestoreRepository();
        await repo.updateUser(user.uid, {
          'name': newName,
          'email': newEmail,
          'avatar': _selectedAvatar,
        });
      } catch (_) {}
    }

    widget.authController.signalChange();

    if (mounted) {
      setState(() {
        _name = newName;
        _email = newEmail;
        _isEditing = false;
      });
      _showSnack('Profile updated successfully!', type: SnackbarType.success);
    }
  }

  void _showSnack(String msg, {SnackbarType type = SnackbarType.info}) {
    if (mounted) showGlassSnackbar(context, msg, type: type);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: _isLoading,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing ? 'Edit Profile' : 'Profile',
              style: widget.theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  AvatarUtils.buildAvatarWidget(
                    _selectedAvatar,
                    radius: 36,
                    fallbackLetter: _name,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: const Text('Upload Custom Photo'),
                      onPressed: () async {
                        final photoBase64 = await AvatarUtils.pickCustomPhoto();
                        if (photoBase64 != null) {
                          setState(() => _selectedAvatar = photoBase64);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              _profileRow(widget.theme, 'Name', _name),
              _profileRow(widget.theme, 'Email', _email),
              _profileRow(
                widget.theme,
                'Role',
                widget.authController.selectedRole?.label ?? 'User',
              ),
              _profileRow(widget.theme, 'Joined', 'Jul 2026'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text('Edit Profile'),
                ),
              ),
            ] else ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveProfile,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    ),
    ),
    );
  }

  Widget _profileRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _AppearanceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
    );
  }
}

class _ChangelogRelease {
  final String version;
  final String date;
  final Map<String, List<_ChangelogItem>> categories;

  _ChangelogRelease({
    required this.version,
    required this.date,
    required this.categories,
  });
}

class _ChangelogItem {
  final String title;
  final String detail;

  _ChangelogItem({required this.title, required this.detail});
}

