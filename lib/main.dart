import 'package:flutter/material.dart';
import 'package:nexus/app/app.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authController = AuthController();
  runApp(NexusApp(authController: authController));
}
