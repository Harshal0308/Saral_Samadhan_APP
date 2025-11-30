import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';

class OfflineModeSyncPage extends StatelessWidget {
  const OfflineModeSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to previous page (e.g., Dashboard or Settings)
          },
        ),
      ),
      body: Consumer<OfflineSyncProvider>(
        builder: (context, offlineSyncProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Changes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total: ${offlineSyncProvider.pendingChanges} items awaiting sync',
                          style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        // Placeholder for detailed pending changes, if needed
                        if (offlineSyncProvider.pendingChanges > 0)
                          const Text('• Some attendance records'),
                        if (offlineSyncProvider.pendingChanges > 0)
                          const Text('• Some volunteer reports'),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto-Sync Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.sync, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(offlineSyncProvider.syncStatusMessage),
                          ],
                        ),
                        if (offlineSyncProvider.lastSyncTime != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Text('Last sync: ${offlineSyncProvider.lastSyncTime!.toLocal().toString().split('.')[0]}'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: offlineSyncProvider.isSyncing ? null : () => offlineSyncProvider.triggerSync(),
                  icon: const Icon(Icons.sync),
                  label: Text(offlineSyncProvider.isSyncing ? 'Syncing...' : 'Retry Sync', style: const TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
