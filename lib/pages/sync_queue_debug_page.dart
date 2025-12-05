import 'package:flutter/material.dart';
import 'package:samadhan_app/services/sync_queue_service.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:samadhan_app/models/sync_queue_item.dart';

class SyncQueueDebugPage extends StatefulWidget {
  const SyncQueueDebugPage({super.key});

  @override
  State<SyncQueueDebugPage> createState() => _SyncQueueDebugPageState();
}

class _SyncQueueDebugPageState extends State<SyncQueueDebugPage> {
  final _syncQueue = SyncQueueService();
  final _cloudSync = CloudSyncServiceV2();
  
  List<SyncQueueItem> _allItems = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadQueueData();
  }

  Future<void> _loadQueueData() async {
    setState(() => _isLoading = true);
    
    try {
      final items = await _syncQueue.getAllItems();
      final stats = await _syncQueue.getSyncStats();
      
      setState(() {
        _allItems = items;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading queue data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processQueue() async {
    setState(() => _isProcessing = true);
    
    try {
      final result = await _cloudSync.processSyncQueue();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Sync completed'),
            backgroundColor: result['success'] ? Colors.green : Colors.orange,
          ),
        );
      }
      
      await _loadQueueData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _retryFailed() async {
    setState(() => _isProcessing = true);
    
    try {
      await _cloudSync.retryFailedItems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retrying failed items...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      await _loadQueueData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _clearQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Queue'),
        content: const Text('Are you sure you want to clear all items from the sync queue? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _syncQueue.clearAllItems();
      await _loadQueueData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Queue Debug'),
        backgroundColor: const Color(0xFF5B5FFF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQueueData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Queue Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Pending',
                              _stats['pending'] ?? 0,
                              Colors.orange,
                            ),
                            _buildStatItem(
                              'In Progress',
                              _stats['inProgress'] ?? 0,
                              Colors.blue,
                            ),
                            _buildStatItem(
                              'Failed',
                              _stats['failed'] ?? 0,
                              Colors.red,
                            ),
                            _buildStatItem(
                              'Total',
                              _stats['total'] ?? 0,
                              Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _processQueue,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: const Text('Process Queue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing || (_stats['failed'] ?? 0) == 0
                              ? null
                              : _retryFailed,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Failed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _clearQueue,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Queue Items List
                Expanded(
                  child: _allItems.isEmpty
                      ? const Center(
                          child: Text(
                            'No items in sync queue',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _allItems.length,
                          itemBuilder: (context, index) {
                            final item = _allItems[index];
                            return _buildQueueItem(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(SyncQueueItem item) {
    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case SyncStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case SyncStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case SyncStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case SyncStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          '${item.entityType.name} - ${item.operation.name}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Center: ${item.centerName} • ${_formatDate(item.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: item.attemptCount > 0
            ? Chip(
                label: Text(
                  'Attempts: ${item.attemptCount}',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.red.shade100,
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', item.id.toString()),
                _buildDetailRow('Entity ID', item.entityId.toString()),
                _buildDetailRow('Status', item.status.name),
                _buildDetailRow('Created', _formatDateTime(item.createdAt)),
                if (item.lastAttemptAt != null)
                  _buildDetailRow('Last Attempt', _formatDateTime(item.lastAttemptAt!)),
                if (item.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Error:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Data:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.data.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
