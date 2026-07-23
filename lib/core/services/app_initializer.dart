import 'package:nexus/core/services/sync_controller.dart';

/// Handles the full application startup pipeline (network, auth, offline data)
class AppInitializer {
  static Future<void> initialize() async {
    // 1. Initialize global offline-to-online sync controller
    SyncController().initialize();

    // 2. (Future) Hydrate Hive databases or other offline stores h ere
    // Local preferences are handled lazily by respective controllers

    // 3. (Future) Initialize Firebase or custom backend SDK here
    
    // 4. (Future) Validate Auth Token here to determine initial route

    // Artificial tiny delay to let splash animations play smoothly
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
