import 'package:flutter/widgets.dart';
import 'package:nexus/core/services/firestore_service.dart';

/// Central Service to track real-time user presence (Active, Idle, Offline)
class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirestoreService _firestore = FirestoreService();
  String? _currentUserId;
  bool _isInitialized = false;

  void initialize(String userId) {
    if (userId.isEmpty) return;
    _currentUserId = userId;
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addObserver(this);
    }
    updateStatus('Active');
  }

  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
    updateStatus('Offline');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        updateStatus('Active');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        updateStatus('Idle');
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        updateStatus('Idle');
        break;
    }
  }

  Future<void> updateStatus(String status) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      await _firestore.updateDocument('users', uid, {
        'status': status,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
