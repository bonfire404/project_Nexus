import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:nexus/core/utils/avatar_utils.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/features/admin/data/repositories/user_firestore_repository.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Role-tailored, minimalist onboarding screen with real biometric prompt & embedded live previews for ALL roles.
class RoleOnboardingScreen extends StatefulWidget {
  final AuthController authController;

  const RoleOnboardingScreen({super.key, required this.authController});

  @override
  State<RoleOnboardingScreen> createState() => _RoleOnboardingScreenState();
}

class _RoleOnboardingScreenState extends State<RoleOnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final UserFirestoreRepository _userRepo = UserFirestoreRepository();
  final LocalAuthentication _localAuth = LocalAuthentication();

  int _currentPage = 0;
  bool _enableBiometrics = false;
  bool _isAuthenticatingBiometrics = false;
  String _selectedAvatar = 'preset_1';

  UserRole get role => widget.authController.selectedRole ?? UserRole.applicant;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.authController.userDisplayName;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (!value) {
      setState(() => _enableBiometrics = false);
      return;
    }

    setState(() => _isAuthenticatingBiometrics = true);

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) {
        if (mounted) {
          showGlassSnackbar(
            context,
            'Biometric hardware is not available on this device.',
            type: SnackbarType.warning,
          );
        }
        setState(() => _isAuthenticatingBiometrics = false);
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or Face ID to enable quick biometric unlock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        setState(() {
          _enableBiometrics = true;
          _isAuthenticatingBiometrics = false;
        });
        if (mounted) {
          showGlassSnackbar(
            context,
            'Biometric authentication enabled successfully!',
            type: SnackbarType.success,
          );
        }
      } else {
        setState(() => _isAuthenticatingBiometrics = false);
      }
    } catch (e) {
      setState(() => _isAuthenticatingBiometrics = false);
      if (mounted) {
        showGlassSnackbar(
          context,
          'Biometric setup skipped or not supported.',
          type: SnackbarType.warning,
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      widget.authController.updateDisplayName(name);
      final user = widget.authController.currentUser;
      if (user != null) {
        try {
          await _userRepo.updateUser(user.uid, {'name': name, 'avatar': _selectedAvatar});
        } catch (_) {}
      }
    }

    final user = widget.authController.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed_${user.uid}', true);
      await prefs.setString('user_avatar_${user.uid}', _selectedAvatar);
      if (_enableBiometrics) {
        await prefs.setBool('biometrics_enabled_${user.uid}', true);
      }
    }

    if (mounted) {
      showGlassSnackbar(
        context,
        'Welcome to Nexus! Your ${role.label} workspace is active.',
        type: SnackbarType.success,
      );
      context.go('/home');
    }
  }

  List<_OnboardingSlide> _getSlidesForRole(ThemeData theme) {
    final commonProfileSlide = _OnboardingSlide(
      icon: HugeIcons.strokeRoundedUser,
      title: 'Welcome, ${role.label}',
      subtitle: 'Set up your display name & upload your profile photo.',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: AvatarUtils.buildAvatarWidget(
              _selectedAvatar,
              radius: 36,
              fallbackLetter: _nameController.text,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Preferred Full Name',
              hintText: 'e.g. Alex Morgan',
            ),
          ),
        ],
      ),
    );

    final commonBiometricSlide = _OnboardingSlide(
      icon: HugeIcons.strokeRoundedFingerPrint,
      title: 'Biometric Unlock',
      subtitle: 'Pair fingerprint or face recognition for instant login.',
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedFingerPrint,
                  color: Colors.blueAccent,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Fingerprint / Face ID',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _enableBiometrics
                            ? 'Biometric unlock active'
                            : 'Tap switch to trigger prompt',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _enableBiometrics
                              ? Colors.green
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isAuthenticatingBiometrics)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: _enableBiometrics,
                    onChanged: _toggleBiometrics,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (role == UserRole.applicant) {
      return [
        commonProfileSlide,
        commonBiometricSlide,
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedSearch01,
          title: 'Discover Career Tracks',
          subtitle: 'Explore available software engineering and tech career tracks.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildApplicantDiscoverDemo(theme),
          ),
        ),
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedFile01,
          title: 'Submit & Track Applications',
          subtitle: 'Monitor your application review status live with status tags.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildApplicantStatusDemo(theme),
          ),
        ),
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedMessage01,
          title: 'Direct Messaging & Updates',
          subtitle: 'Receive official announcements and interview updates from Administrators.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildApplicantMessagesDemo(theme),
          ),
        ),
      ];
    } else if (role == UserRole.administrator) {
      return [
        commonProfileSlide,
        commonBiometricSlide,
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedDashboardSquare01,
          title: 'Users Management & Real-time Sync',
          subtitle: 'Manage platform users with + Add User and Swipe-to-Delete real-time streaming.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildAdminUsersDemo(theme),
          ),
        ),
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedBriefcase02,
          title: 'Program & Curriculum Control',
          subtitle: 'Create and publish software development tracks and learning modules.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildAdminProgramsDemo(theme),
          ),
        ),
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedUserCheck01,
          title: 'Application Review & Promotion',
          subtitle: 'Evaluate incoming applications and auto-promote candidates to Interns.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildAdminApplicationsDemo(theme),
          ),
        ),
      ];
    } else {
      // Intern Role
      return [
        commonProfileSlide,
        commonBiometricSlide,
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedHome01,
          title: 'Module 1: Dashboard',
          subtitle: 'Real-time metrics, announcements, task progress, and activity streams.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildInternDashboardDemo(theme),
          ),
        ),
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedCode,
          title: 'Module 2: Programs',
          subtitle: 'Explore engineering tracks, program details, and curriculum milestones.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildInternProgramsDemo(theme),
          ),
        ),
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedBookOpen01,
          title: 'Module 3: Learning Center',
          subtitle: 'Access internship handbooks, onboarding guides, and video tutorials.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildInternLearningDemo(theme),
          ),
        ),
        _OnboardingSlide(
          icon: HugeIcons.strokeRoundedBriefcase01,
          title: 'Module 4: Workspace & Sync',
          subtitle: 'Submit weekly sprint tasks, track project deadlines, and join mentor syncs.',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildInternWorkspaceDemo(theme),
          ),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slides = _getSlidesForRole(theme);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${role.label.toUpperCase()} ONBOARDING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => slides[index],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (idx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == idx ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      child: Text(
                        _currentPage == slides.length - 1
                            ? 'Get Started'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // APPLICANT DEMOS
  Widget _buildApplicantDiscoverDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.rocket_launch, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mobile & Cloud Engineering Track', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('Tap "Enroll Now" to apply directly', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantStatusDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Submitted Application #1042', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text('Pending Review', style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantMessagesDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_chat_unread, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Notice: Interview Schedule Updated', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          Text('Just now', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ADMIN DEMOS
  Widget _buildAdminUsersDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_add, color: Colors.indigo, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Real-time Users Stream & Swipe Delete', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          const Icon(Icons.add_circle_outline, color: Colors.indigo, size: 18),
        ],
      ),
    );
  }

  Widget _buildAdminProgramsDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_box_outlined, color: Colors.teal, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Create & Publish New Program Tracks', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildAdminApplicationsDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Accept Candidate -> Auto Promote to Intern', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // INTERN DEMOS
  Widget _buildInternDashboardDemo(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Text('Completed Tasks', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text('12 / 15', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Text('Sprint Hours', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text('38.5 hrs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInternProgramsDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.code, color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full-Stack Software Track', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('12-Week Intensive Curriculum', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternLearningDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.orange, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Internship Orientation Guide', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.video_library, color: Colors.purple, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Architecture & Systems Video (24m)', style: theme.textTheme.bodyMedium)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInternWorkspaceDemo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, color: Colors.blue, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Sprint 1 Deliverable', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('In Review', style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue)),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.groups, color: Colors.teal, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Weekly Mentor Sync Meeting', style: theme.textTheme.bodyMedium)),
              Text('Fri 2 PM', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final Widget? child;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
