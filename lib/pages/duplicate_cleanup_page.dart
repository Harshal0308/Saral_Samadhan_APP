import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/services/sync_queue_service.dart';

class DuplicateCleanupPage extends StatefulWidget {
  const DuplicateCleanupPage({super.key});

  @override
  State<DuplicateCleanupPage> createState() => _DuplicateCleanupPageState();
}

class _DuplicateCleanupPageState extends State<DuplicateCleanupPage> {
  bool _isCleaningUp = false;
  String _statusMessage = '';
  final _syncQueue = SyncQueueService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cleanup Duplicates',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duplicate Report Cleanup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will remove duplicate volunteer reports that may have been created due to sync issues. Only the most recent report for each volunteer/center/date combination will be kept.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCleaningUp ? null : _cleanupDuplicateReports,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isCleaningUp
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Cleaning up...'),
                                ],
                              )
                            : const Text('Clean Up Duplicate Reports'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clear Sync Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will clear all pending sync operations. Use this if you have many failed sync attempts clogging the queue.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCleaningUp ? null : _clearSyncQueue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Clear Sync Queue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cleanupDuplicateReports() async {
    setState(() {
      _isCleaningUp = true;
      _statusMessage = 'Starting cleanup...';
    });

    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
      
      // Get initial count
      final initialCount = volunteerProvider.reports.length;
      
      // Cleanup duplicates
      await volunteerProvider.cleanupDuplicateReports();
      
      // Get final count
      final finalCount = volunteerProvider.reports.length;
      final removedCount = initialCount - finalCount;
      
      setState(() {
        _statusMessage = removedCount > 0 
            ? 'Cleanup completed! Removed $removedCount duplicate reports.'
            : 'No duplicate reports found.';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during cleanup: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleanup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCleaningUp = false;
      });
    }
  }

  Future<void> _clearSyncQueue() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sync Queue'),
        content: const Text(
          'This will permanently remove all pending sync operations. '
          'Any unsaved changes will be lost. Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Queue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCleaningUp = true;
      _statusMessage = 'Clearing sync queue...';
    });

    try {
      await _syncQueue.clearAllItems();
      
      setState(() {
        _statusMessage = 'Sync queue cleared successfully.';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync queue cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing sync queue: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear sync queue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCleaningUp = false;
      });
    }
  }
}