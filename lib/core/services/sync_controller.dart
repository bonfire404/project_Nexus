import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Manages network connectivity and offline-to-online synchronization.
class SyncController extends ChangeNotifier {
  static final SyncController _instance = SyncController._internal();
  factory SyncController() => _instance;
  SyncController._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  void initialize() {
    // Initial check
    Connectivity().checkConnectivity().then(_updateStatus);

    // Listen to changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = !results.contains(ConnectivityResult.none);
    
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();

      if (_isOnline) {
        _syncOfflineQueue();
      }
    }
  }

  Future<void> _syncOfflineQueue() async {
    // TODO: This is where we will loop through Hive/SQLite or let Firebase automatically push data
    debugPrint('[SyncController] Back online! Syncing offline queue to backend...');
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }
}
