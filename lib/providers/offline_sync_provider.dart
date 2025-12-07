import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:samadhan_app/services/sync_queue_service.dart';

class OfflineSyncProvider with ChangeNotifier {
  int _pendingChanges = 0;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String _syncStatusMessage = "Checking connection...";
  bool _isOnline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  final _cloudSyncV2 = CloudSyncServiceV2();
  final _syncQueue = SyncQueueService();

  int get pendingChanges => _pendingChanges;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get syncStatusMessage => _syncStatusMessage;
  bool get isOnline => _isOnline;

  OfflineSyncProvider() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _initConnectivity();
    _startPeriodicSync();
    _updatePendingCount(); // Initial count
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);
    
    if (_isOnline) {
      _syncStatusMessage = "Connected. Ready to sync.";
      // Auto-sync when coming online
      if (!wasOnline) {
        print('📡 Network reconnected - triggering auto-sync');
        triggerSync();
      }
    } else {
      _syncStatusMessage = "Offline. Changes will be synced when online.";
    }
    notifyListeners();
  }

  /// Start periodic sync every 5 minutes if online
  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_isOnline && !_isSyncing) {
        await _updatePendingCount();
        if (_pendingChanges > 0) {
          print('⏰ Periodic sync triggered - $_pendingChanges items pending');
          await triggerSync();
        }
      }
    });
  }

  /// Update pending changes count from sync queue
  Future<void> _updatePendingCount() async {
    try {
      final stats = await _syncQueue.getSyncStats();
      final newCount = stats['pending'] ?? 0;
      if (newCount != _pendingChanges) {
        _pendingChanges = newCount;
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Error updating pending count: $e');
    }
  }

  void addPendingChange() {
    _pendingChanges++;
    notifyListeners();
  }

  void removePendingChange() {
    if (_pendingChanges > 0) {
      _pendingChanges--;
      notifyListeners();
    }
  }

  /// Trigger actual cloud sync using CloudSyncServiceV2
  Future<void> triggerSync() async {
    if (_isSyncing || !_isOnline) {
      print('⚠️ Cannot sync: ${!_isOnline ? "Offline" : "Already syncing"}');
      return;
    }

    _isSyncing = true;
    _syncStatusMessage = "Syncing in progress...";
    notifyListeners();

    try {
      print('🔄 Starting sync via OfflineSyncProvider...');
      
      // Process the sync queue
      final result = await _cloudSyncV2.processSyncQueue();
      
      // Update pending count
      await _updatePendingCount();
      
      _lastSyncTime = DateTime.now();
      
      if (result['success'] == true) {
        final successCount = result['successCount'] ?? 0;
        final failureCount = result['failureCount'] ?? 0;
        
        if (failureCount > 0) {
          _syncStatusMessage = "Sync completed with errors: $successCount synced, $failureCount failed";
        } else if (successCount > 0) {
          _syncStatusMessage = "Sync complete. $successCount items uploaded.";
        } else {
          _syncStatusMessage = "No pending changes to sync.";
        }
      } else {
        _syncStatusMessage = "Sync failed: ${result['message']}";
      }
      
      print('✅ Sync completed: ${result['message']}');
    } catch (e) {
      print('❌ Sync error: $e');
      _syncStatusMessage = "Sync error: $e";
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}
