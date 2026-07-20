import 'package:flutter/material.dart';
import 'package:nexus/app/app.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/core/utils/app_version.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppVersion.init();
  final authController = AuthController();
  final themeController = ThemeController();
  runApp(NexusApp(
    authController: authController,
    themeController: themeController,
  ));
}
