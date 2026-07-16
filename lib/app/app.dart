import 'package:flutter/material.dart';
import 'package:nexus/app/theme.dart';
import 'package:nexus/app/router.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class NexusApp extends StatefulWidget {
  final AuthController authController;

  const NexusApp({super.key, required this.authController});

  @override
  State<NexusApp> createState() => _NexusAppState();
}

class _NexusAppState extends State<NexusApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = NexusRouter.create(widget.authController);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      theme: NexusTheme.light,
      darkTheme: NexusTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
