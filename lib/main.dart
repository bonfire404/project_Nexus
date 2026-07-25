import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nexus/app/app.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/core/utils/app_version.dart';
import 'package:nexus/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppVersion.init();
  final authController = AuthController();
  final themeController = ThemeController();
  runApp(NexusApp(
    authController: authController,
    themeController: themeController,
  ));
}
