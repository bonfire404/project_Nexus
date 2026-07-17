import 'package:flutter/material.dart';
import 'package:nexus/app/theme.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:nexus/app/router.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class NexusApp extends StatefulWidget {
  final AuthController authController;
  final ThemeController themeController;

  const NexusApp({
    super.key,
    required this.authController,
    required this.themeController,
  });

  @override
  State<NexusApp> createState() => _NexusAppState();
}

class _NexusAppState extends State<NexusApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = NexusRouter.create(
      widget.authController,
      themeController: widget.themeController,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.themeController,
      builder: (context, _) {
        // Resolve the active theme manually so MaterialApp's internal AnimatedTheme 
        // properly crossfades the colors over the 600ms duration instead of snapping.
        final platformBrightness = View.of(context).platformDispatcher.platformBrightness;
        final isDark = widget.themeController.themeMode == ThemeMode.dark ||
            (widget.themeController.themeMode == ThemeMode.system &&
                platformBrightness == Brightness.dark);

        final activeTheme = isDark ? NexusTheme.dark : NexusTheme.light;

        return MaterialApp.router(
          title: 'Nexus',
          debugShowCheckedModeBanner: false,
          theme: activeTheme,
          themeAnimationDuration: const Duration(milliseconds: 600),
          themeAnimationCurve: Curves.easeInOutCubic,
          routerConfig: _router,
          builder: (context, child) {
            return _PremiumThemeWrapper(
              themeMode: widget.themeController.themeMode,
              child: child!,
            );
          },
        );
      },
    );
  }
}

/// Adds a premium, subtle scaling pulse effect to the entire app during theme switches.
class _PremiumThemeWrapper extends StatefulWidget {
  final ThemeMode themeMode;
  final Widget child;

  const _PremiumThemeWrapper({required this.themeMode, required this.child});

  @override
  State<_PremiumThemeWrapper> createState() => _PremiumThemeWrapperState();
}

class _PremiumThemeWrapperState extends State<_PremiumThemeWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.97)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 1,
      ),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(covariant _PremiumThemeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.themeMode != oldWidget.themeMode) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
