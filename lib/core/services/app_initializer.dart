import 'package:nexus/core/services/sync_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles the full application startup pipeline (network, auth, offline data)
class AppInitializer {
  static Future<void> initialize() async {
    // 1. Initialize global offline-to-online sync controller
    SyncController().initialize();

    // 2. Hydrate local preferences / Hive databases
    await SharedPreferences.getInstance();

    // 3. (Future) Initialize Firebase or custom backend SDK here
    
    // 4. (Future) Validate Auth Token here to determine initial route

    // Artificial tiny delay to let splash animations play smoothly
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
