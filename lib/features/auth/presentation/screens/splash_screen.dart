import 'package:flutter/material.dart';
import 'package:nexus/core/services/app_initializer.dart';

/// Full-screen splash with app name. Auto-navigates after 2 seconds.
/// Navigation is handled by the router's redirect logic — this screen
/// simply waits, then signals readiness.
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
      duration: const Duration(seconds: 2),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await AppInitializer.initialize();
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
