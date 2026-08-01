import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nexus/app/app.dart';
import 'package:nexus/app/theme_controller.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/core/utils/app_version.dart';
import 'package:nexus/firebase_options.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nexus/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv initialization skipped: $e");
  }

  // Safely initialize Firebase SDK & messaging
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization deferred/failed: $e");
  }

  try {
    await AppVersion.init();
  } catch (e) {
    debugPrint("AppVersion init skipped: $e");
  }

  final authController = AuthController();
  final themeController = ThemeController();
  runApp(NexusApp(
    authController: authController,
    themeController: themeController,
  ));
}
