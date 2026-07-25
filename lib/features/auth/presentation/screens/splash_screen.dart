import 'package:flutter/material.dart';
import 'package:nexus/core/services/app_initializer.dart';

/// Full-screen splash with rotating logo and app branding. Auto-navigates after minimum animation period.
class SplashScreen extends StatefulWidget {
  final VoidCallback onInitialized;

  const SplashScreen({super.key, required this.onInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _spinController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    await AppInitializer.initialize();
    
    // Ensure smooth minimum rotation time (2.2s) so the logo rotation plays gracefully on startup
    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 2200);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (mounted) {
      widget.onInitialized();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: RotationTransition(
            turns: _spinController,
            child: Image.asset(
              'assets/icons/app_logo.png',
              width: 120,
              height: 120,
            ),
          ),
        ),
      ),
    );
  }
}
