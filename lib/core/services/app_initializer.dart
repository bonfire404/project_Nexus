import 'package:firebase_core/firebase_core.dart';
import 'package:nexus/core/services/firestore_seeder.dart';
import 'package:nexus/core/services/sync_controller.dart';
import 'package:nexus/firebase_options.dart';

/// Handles the full application startup pipeline (network, auth, offline data)
class AppInitializer {
  static Future<void> initialize() async {
    // 1. Initialize global offline-to-online sync controller
    SyncController().initialize();

    // 2. Ensure Firebase core SDK is initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 3. Seed default Firestore collections if empty
    await FirestoreSeeder.seedIfEmpty();

    // Artificial tiny delay to let splash animations play smoothly
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
