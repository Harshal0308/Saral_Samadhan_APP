import 'package:sembast/sembast.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/models/sync_queue_item.dart';

/// Service to manage sync queue for reliable data synchronization
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final _syncQueueStore = intMapStoreFactory.store('sync_queue');
  final DatabaseService _dbService = DatabaseService();

  // Maximum retry attempts before marking as failed
  static const int maxRetryAttempts = 5;

  /// Add item to sync queue
  Future<int> addToQueue({
    required SyncEntityType entityType,
    required SyncOperation operation,
    required int entityId,
    required Map<String, dynamic> data,
    required String centerName,
  }) async {
    final db = await _dbService.database;

    final queueItem = SyncQueueItem(
      id: 0, // Sembast will generate
      entityType: entityType,
      operation: operation,
      entityId: entityId,
      data: data,
      centerName: centerName,
      createdAt: DateTime.now(),
      status: SyncStatus.pending,
    );

    final id = await _syncQueueStore.add(db, queueItem.toMap());
    print('✅ Added to sync queue: ${entityType.name} ${operation.name} (ID: $id)');
    return id;
  }

  /// Get all pending items from queue
  Future<List<SyncQueueItem>> getPendingItems() async {
    final db = await _dbService.database;
    
    final finder = Finder(
      filter: Filter.equals('status', SyncStatus.pending.name),
      sortOrders: [SortOrder('createdAt', true)], // Oldest first
    );

    final snapshots = await _syncQueueStore.find(db, finder: finder);
    return snapshots.map((snapshot) {
      return SyncQueueItem.fromMap(snapshot.value, snapshot.key);
    }).toList();
  }

  /// Get all items (for debugging/logs)
  Future<List<SyncQueueItem>> getAllItems() async {
    final db = await _dbService.database;
    
    final finder = Finder(
      sortOrders: [SortOrder('createdAt', false)], // Newest first
    );

    final snapshots = await _syncQueueStore.find(db, finder: finder);
    return snapshots.map((snapshot) {
      return SyncQueueItem.fromMap(snapshot.value, snapshot.key);
    }).toList();
  }

  /// Get items by status
  Future<List<SyncQueueItem>> getItemsByStatus(SyncStatus status) async {
    final db = await _dbService.database;
    
    final finder = Finder(
      filter: Filter.equals('status', status.name),
      sortOrders: [SortOrder('createdAt', false)],
    );

    final snapshots = await _syncQueueStore.find(db, finder: finder);
    return snapshots.map((snapshot) {
      return SyncQueueItem.fromMap(snapshot.value, snapshot.key);
    }).toList();
  }

  /// Get failed items that can be retried
  Future<List<SyncQueueItem>> getRetryableItems() async {
    final db = await _dbService.database;
    
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('status', SyncStatus.failed.name),
        Filter.lessThan('attemptCount', maxRetryAttempts),
      ]),
      sortOrders: [SortOrder('createdAt', true)],
    );

    final snapshots = await _syncQueueStore.find(db, finder: finder);
    return snapshots.map((snapshot) {
      return SyncQueueItem.fromMap(snapshot.value, snapshot.key);
    }).toList();
  }

  /// Update queue item status
  Future<void> updateItemStatus({
    required int itemId,
    required SyncStatus status,
    String? errorMessage,
  }) async {
    final db = await _dbService.database;
    
    final snapshot = await _syncQueueStore.record(itemId).get(db);
    if (snapshot == null) return;

    final item = SyncQueueItem.fromMap(snapshot, itemId);
    final updatedItem = item.copyWith(
      status: status,
      lastAttemptAt: DateTime.now(),
      attemptCount: status == SyncStatus.failed ? item.attemptCount + 1 : item.attemptCount,
      errorMessage: errorMessage,
    );

    await _syncQueueStore.record(itemId).update(db, updatedItem.toMap());
    
    if (status == SyncStatus.completed) {
      print('✅ Sync completed: ${item.entityType.name} ${item.operation.name} (ID: $itemId)');
    } else if (status == SyncStatus.failed) {
      print('❌ Sync failed (attempt ${updatedItem.attemptCount}): ${item.entityType.name} ${item.operation.name} - $errorMessage');
    }
  }

  /// Mark item as in progress
  Future<void> markInProgress(int itemId) async {
    await updateItemStatus(itemId: itemId, status: SyncStatus.inProgress);
  }

  /// Mark item as completed and remove from queue
  Future<void> markCompleted(int itemId) async {
    final db = await _dbService.database;
    await _syncQueueStore.record(itemId).delete(db);
    print('🗑️ Removed completed item from queue: $itemId');
  }

  /// Mark item as failed
  Future<void> markFailed(int itemId, String errorMessage) async {
    await updateItemStatus(
      itemId: itemId,
      status: SyncStatus.failed,
      errorMessage: errorMessage,
    );
  }

  /// Get count of pending items
  Future<int> getPendingCount() async {
    final db = await _dbService.database;
    
    return await _syncQueueStore.count(
      db,
      filter: Filter.equals('status', SyncStatus.pending.name),
    );
  }

  /// Get count of failed items
  Future<int> getFailedCount() async {
    final db = await _dbService.database;
    
    return await _syncQueueStore.count(
      db,
      filter: Filter.equals('status', SyncStatus.failed.name),
    );
  }

  /// Clear completed items older than specified days
  Future<void> clearOldCompletedItems({int daysOld = 7}) async {
    final db = await _dbService.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('status', SyncStatus.completed.name),
        Filter.lessThan('createdAt', cutoffDate.toIso8601String()),
      ]),
    );

    final count = await _syncQueueStore.delete(db, finder: finder);
    print('🗑️ Cleared $count old completed items from sync queue');
  }

  /// Clear all items (use with caution!)
  Future<void> clearAllItems() async {
    final db = await _dbService.database;
    await _syncQueueStore.delete(db);
    print('🗑️ Cleared all items from sync queue');
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final db = await _dbService.database;
    
    final pending = await _syncQueueStore.count(
      db,
      filter: Filter.equals('status', SyncStatus.pending.name),
    );
    
    final inProgress = await _syncQueueStore.count(
      db,
      filter: Filter.equals('status', SyncStatus.inProgress.name),
    );
    
    final failed = await _syncQueueStore.count(
      db,
      filter: Filter.equals('status', SyncStatus.failed.name),
    );
    
    final total = await _syncQueueStore.count(db);

    return {
      'pending': pending,
      'inProgress': inProgress,
      'failed': failed,
      'total': total,
    };
  }
}
