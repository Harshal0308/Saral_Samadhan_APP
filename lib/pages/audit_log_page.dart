import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<AuditEntry> _auditLogs = [];
  bool _isLoading = true;
  String? _filterTable;
  String? _filterUser;
  bool _showConflictsOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user's center
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentCenter = userProvider.userSettings.selectedCenter;
      
      if (currentCenter == null || currentCenter.isEmpty) {
        setState(() {
          _auditLogs = [];
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a center first')),
          );
        }
        return;
      }
      
      // Build query with filters BEFORE order and limit
      dynamic query = Supabase.instance.client
          .from('audit_log')
          .select()
          .eq('center_name', currentCenter); // ✅ Filter by current center
      
      // Apply additional filters
      if (_filterTable != null) {
        query = query.eq('table_name', _filterTable!);
      }
      if (_filterUser != null) {
        query = query.eq('user_email', _filterUser!);
      }
      if (_showConflictsOnly) {
        query = query.eq('conflict_detected', true);
      }
      
      // Then apply order and limit
      final response = await query.order('timestamp', ascending: false).limit(100);
      
      setState(() {
        _auditLogs = (response as List)
            .map((e) => AuditEntry.fromMap(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching audit logs: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading audit logs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAuditLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_filterTable != null || _filterUser != null || _showConflictsOnly)
            Container(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filterTable != null)
                    Chip(
                      label: Text('Table: $_filterTable'),
                      onDeleted: () {
                        setState(() => _filterTable = null);
                        _fetchAuditLogs();
                      },
                    ),
                  if (_filterUser != null)
                    Chip(
                      label: Text('User: $_filterUser'),
                      onDeleted: () {
                        setState(() => _filterUser = null);
                        _fetchAuditLogs();
                      },
                    ),
                  if (_showConflictsOnly)
                    Chip(
                      label: const Text('Conflicts Only'),
                      backgroundColor: Colors.red.shade100,
                      onDeleted: () {
                        setState(() => _showConflictsOnly = false);
                        _fetchAuditLogs();
                      },
                    ),
                ],
              ),
            ),
          
          // Audit log list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _auditLogs.isEmpty
                    ? const Center(child: Text('No audit logs found'))
                    : ListView.builder(
                        itemCount: _auditLogs.length,
                        itemBuilder: (context, index) {
                          final entry = _auditLogs[index];
                          return _buildAuditLogCard(entry);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(AuditEntry entry) {
    final operationColor = entry.operation == 'CREATE'
        ? Colors.green
        : entry.operation == 'UPDATE'
            ? Colors.blue
            : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: operationColor.withOpacity(0.2),
          child: Icon(
            entry.operation == 'CREATE'
                ? Icons.add
                : entry.operation == 'UPDATE'
                    ? Icons.edit
                    : Icons.delete,
            color: operationColor,
          ),
        ),
        title: Text(
          '${entry.operation} - ${entry.tableName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By: ${entry.userEmail}'),
            Text(
              DateFormat('MMM dd, yyyy HH:mm:ss').format(entry.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (entry.conflictDetected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '⚠️ CONFLICT DETECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.changes != null && entry.changes!.isNotEmpty) ...[
                  const Text(
                    'Changes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...entry.changes!.entries.map((change) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            change.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Old: ${change.value['old']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward, size: 16),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'New: ${change.value['new']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                if (entry.notes != null) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${entry.notes}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Audit Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Table'),
              value: _filterTable,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Tables')),
                DropdownMenuItem(value: 'students', child: Text('Students')),
                DropdownMenuItem(
                    value: 'attendance_records', child: Text('Attendance')),
                DropdownMenuItem(
                    value: 'volunteer_reports', child: Text('Volunteer Reports')),
              ],
              onChanged: (value) {
                setState(() => _filterTable = value);
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Show Conflicts Only'),
              value: _showConflictsOnly,
              onChanged: (value) {
                setState(() => _showConflictsOnly = value ?? false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchAuditLogs();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class AuditEntry {
  final int id;
  final String tableName;
  final String recordId;
  final String operation;
  final String userEmail;
  final String? userName;
  final String? centerName;
  final DateTime timestamp;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final Map<String, dynamic>? changes;
  final bool conflictDetected;
  final String? conflictResolution;
  final String? notes;

  AuditEntry({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.userEmail,
    this.userName,
    this.centerName,
    required this.timestamp,
    this.oldData,
    this.newData,
    this.changes,
    required this.conflictDetected,
    this.conflictResolution,
    this.notes,
  });

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      operation: map['operation'],
      userEmail: map['user_email'],
      userName: map['user_name'],
      centerName: map['center_name'],
      timestamp: DateTime.parse(map['timestamp']),
      oldData: map['old_data'],
      newData: map['new_data'],
      changes: map['changes'],
      conflictDetected: map['conflict_detected'] ?? false,
      conflictResolution: map['conflict_resolution'],
      notes: map['notes'],
    );
  }
}
