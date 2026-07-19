import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus/core/utils/legal_docs_sheets.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _name = prefs.getString('user_name') ?? 'Nexus User';
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
      padding: const EdgeInsets.all(24),
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                  ),
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
              onTap: () => _showComingSoon(context, 'Notification preferences'),
            ),
            _SettingsItem(
              icon: HugeIcons.strokeRoundedMoon02,
              label: 'Appearance',
              onTap: () => _showAppearanceSheet(context),
            ),
            _SettingsItem(
              icon: HugeIcons.strokeRoundedLockPassword,
              label: 'Privacy & Security',
              onTap: () => _showComingSoon(context, 'Privacy & Security settings'),
            ),
            _SettingsSwitchItem(
              icon: HugeIcons.strokeRoundedShield02,
              label: 'Biometric Authentication',
            ),
          ]),
          const SizedBox(height: 16),
          _buildSettingsGroup(context, theme, [
            _SettingsItem(
              icon: HugeIcons.strokeRoundedHelpCircle,
              label: 'Help & Support',
              onTap: () => _showSupportSheet(context, theme),
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
              'Nexus v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    showGlassSnackbar(context, '$label — coming soon');
  }

  void _showSnack(BuildContext context, String msg, {SnackbarType type = SnackbarType.info}) {
    showGlassSnackbar(context, msg, type: type);
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
              'Version 1.0.0',
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

  void _showSupportSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
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
              'Help & Support',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'How can we help you?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showSnack(context, 'Message sent', type: SnackbarType.success);
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Send Message'),
              ),
            ),
            const SizedBox(height: 24),
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

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? 'Nexus User';
      _email = prefs.getString('user_email') ?? 'user@nexus.com';
      _nameController = TextEditingController(text: _name);
      _emailController = TextEditingController(text: _email);
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_email', _emailController.text);
    setState(() {
      _name = _nameController.text;
      _email = _emailController.text;
      _isEditing = false;
    });
    _showSnack('Profile updated', type: SnackbarType.success);
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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
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
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
    );
  }
}

