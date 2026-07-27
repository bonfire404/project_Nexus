import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:nexus/core/utils/avatar_utils.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';

/// Ultra-fast, optimized Welcome Back screen featuring crisp growing profile avatar,
/// responsive status dot badge, conditional biometric holding, and instant transition to Home.
class WelcomeResumeScreen extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onProceed;

  const WelcomeResumeScreen({
    super.key,
    required this.authController,
    required this.onProceed,
  });

  @override
  State<WelcomeResumeScreen> createState() => _WelcomeResumeScreenState();
}

class _WelcomeResumeScreenState extends State<WelcomeResumeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeInController;
  late final AnimationController _avatarGrowController;
  late final AnimationController _badgeAnimController;
  late final AnimationController _logoSpinController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _avatarScale;
  late final Animation<Color?> _badgeColorTween;
  late final Animation<double> _badgeScale;
  Timer? _autoProceedTimer;

  bool _isBiometricsActive = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeIn = CurvedAnimation(parent: _fadeInController, curve: Curves.easeOut);
    _fadeInController.forward();

    // Fast, Crisp Avatar Grow Effect Animation (400ms)
    _avatarGrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _avatarScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _avatarGrowController, curve: Curves.easeOutCubic),
    );
    _avatarGrowController.forward();

    // Responsive Status Dot Badge Animation (500ms)
    _badgeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _badgeColorTween = ColorTween(
      begin: const Color(0xFF8E8E93), // Inactive grey
      end: const Color(0xFF34C759),   // Active vibrant green
    ).animate(
      CurvedAnimation(
        parent: _badgeAnimController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeInOut),
      ),
    );

    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _badgeAnimController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeInOut),
      ),
    );

    // Smooth Rotating App Logo Preloader Animation
    _logoSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _checkAndInitializeBiometrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache app logo image to eliminate decoding delays
    precacheImage(const AssetImage('assets/icons/app_logo.png'), context);
  }

  Future<void> _checkAndInitializeBiometrics() async {
    final user = widget.authController.currentUser;
    final uid = user?.uid ?? '';
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = (uid.isNotEmpty && (prefs.getBool('biometrics_enabled_$uid') ?? false)) ||
        (prefs.getBool('biometric_enabled') ?? false);

    if (!mounted) return;

    if (isEnabled) {
      setState(() {
        _isBiometricsActive = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerBiometricAuth();
      });
    } else {
      // Biometrics disabled: transition status badge to green & auto-proceed smoothly
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _badgeAnimController.forward();
      });
      _autoProceedTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) widget.onProceed();
      });
    }
  }

  Future<void> _triggerBiometricAuth() async {
    try {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        _onBiometricSuccess();
        return;
      }

      final authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to resume session in Nexus',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _onBiometricSuccess();
      } else {
        _onBiometricFailure();
      }
    } catch (_) {
      _onBiometricFailure();
    }
  }

  void _onBiometricSuccess() {
    if (!mounted) return;
    _badgeAnimController.forward();
    showGlassSnackbar(context, 'Biometric authentication verified', type: SnackbarType.success);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) widget.onProceed();
    });
  }

  void _onBiometricFailure() {
    if (!mounted) return;
    setState(() {
      _failedAttempts++;
    });

    if (_failedAttempts >= 3) {
      showGlassSnackbar(
        context,
        'Multiple failed biometric attempts. Session logged out.',
        type: SnackbarType.error,
      );
      widget.authController.logout();
    } else {
      showGlassSnackbar(
        context,
        'Biometric verification failed (${3 - _failedAttempts} attempt(s) remaining)',
        type: SnackbarType.error,
      );
    }
  }

  @override
  void dispose() {
    _autoProceedTimer?.cancel();
    _fadeInController.dispose();
    _avatarGrowController.dispose();
    _badgeAnimController.dispose();
    _logoSpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.authController.userDisplayName;
    final role = widget.authController.selectedRole ?? UserRole.applicant;
    final avatarUrl = widget.authController.avatarUrl;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: GestureDetector(
        onTap: () {
          if (!_isBiometricsActive) {
            _autoProceedTimer?.cancel();
            widget.onProceed();
          } else {
            _triggerBiometricAuth();
          }
        },
        child: SizedBox.expand(
          child: Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Larger Round Profile Avatar with Grow Effect & Status Dot Badge
                  ScaleTransition(
                    scale: _avatarScale,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Larger Circular Profile Avatar (112px)
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AvatarUtils.buildAvatarWidget(
                            avatarUrl,
                            radius: 56,
                            fallbackLetter: displayName,
                          ),
                        ),

                        // Status Dot Badge (Changes from Inactive Grey to Active Green)
                        AnimatedBuilder(
                          animation: _badgeAnimController,
                          builder: (context, child) {
                            final color = _badgeColorTween.value ?? const Color(0xFF8E8E93);
                            return Transform.scale(
                              scale: _badgeScale.value,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 4.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // "Welcome Back, [Role]" Headline Text
                  Text(
                    'Welcome Back, ${role.label}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Kameron',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),

                  // Conditional Biometric Authentication Lock or Rotating Logo Preloader
                  if (_isBiometricsActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _triggerBiometricAuth,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.fingerprint_rounded,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to unlock with Biometrics',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: RotationTransition(
                        turns: _logoSpinController,
                        child: Image.asset(
                          'assets/icons/app_logo.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
