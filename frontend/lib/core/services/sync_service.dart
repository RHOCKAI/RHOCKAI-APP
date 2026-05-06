import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/camera_ai/session/session_storage.dart';


import '../providers/api_client_provider.dart';

final syncServiceProvider = Provider((ref) => SyncService(ref));

class SyncService {
  final Ref _ref;
  final SessionStorage _storage = SessionStorage();
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._ref);

  /// Initialize the sync service
  void init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // connectivity_plus 6.x returns a List<ConnectivityResult>
      if (results.any((result) => result != ConnectivityResult.none)) {
        _syncPendingSessions();
      }
    });
    
    // Initial sync check
    _syncPendingSessions();
  }

  /// Sync all pending sessions to the cloud
  Future<void> _syncPendingSessions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await _storage.getPendingSessions();
      if (pending.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('🔄 Found ${pending.length} pending sessions to sync...');
      
      final apiClient = _ref.read(apiClientProvider);
      
      for (final session in pending) {
        try {
          await apiClient.post('/sessions', data: session.toJson());
          await _storage.markAsSynced(session.id);
          debugPrint('✅ Synced session ${session.id}');
        } catch (e) {
          debugPrint('❌ Failed to sync session ${session.id}: $e');
          // Stop sync on first error (likely server down or auth issue)
          break;
        }
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
