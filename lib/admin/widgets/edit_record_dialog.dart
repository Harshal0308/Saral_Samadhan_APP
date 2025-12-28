import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/admin/providers/admin_data_provider.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class EditRecordDialog extends StatefulWidget {
  final String tableName;
  final Map<String, dynamic> record;

  const EditRecordDialog({
    super.key,
    required this.tableName,
    required this.record,
  });

  @override
  State<EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<EditRecordDialog> {
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = false;

  // Fields that should not be edited
  static const _readOnlyFields = ['id', 'created_at', 'updated_at'];
  
  // Fields that are complex types (maps, lists)
  List<String> _complexFields = [];

  @override
  void initState() {
    super.initState();
    _controllers = {};
    
    for (var entry in widget.record.entries) {
      if (entry.value is Map || entry.value is List) {
        _complexFields.add(entry.key);
      } else {
        _controllers[entry.key] = TextEditingController(
          text: entry.value?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    final updatedData = <String, dynamic>{};
    
    for (var entry in _controllers.entries) {
      if (!_readOnlyFields.contains(entry.key)) {
        final originalValue = widget.record[entry.key];
        final newValue = entry.value.text;
        
        // Try to preserve the original type
        if (originalValue is int) {
          updatedData[entry.key] = int.tryParse(newValue) ?? 0;
        } else if (originalValue is double) {
          updatedData[entry.key] = double.tryParse(newValue) ?? 0.0;
        } else if (originalValue is bool) {
          updatedData[entry.key] = newValue.toLowerCase() == 'true';
        } else {
          updatedData[entry.key] = newValue;
        }
      }
    }

    final dataProvider = Provider.of<AdminDataProvider>(context, listen: false);
    final success = await dataProvider.updateRecord(
      widget.tableName,
      widget.record['id'],
      updatedData,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Record updated successfully' : 'Failed to update record'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit ${widget.tableName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._controllers.entries.map((entry) {
                      final isReadOnly = _readOnlyFields.contains(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: entry.value,
                          readOnly: isReadOnly,
                          decoration: InputDecoration(
                            labelText: _formatKey(entry.key),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: isReadOnly,
                            fillColor: isReadOnly ? Colors.grey[100] : null,
                            suffixIcon: isReadOnly
                                ? const Icon(Icons.lock, size: 18)
                                : null,
                          ),
                        ),
                      );
                    }),
                    
                    if (_complexFields.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Complex fields (not editable here):',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _complexFields.map((field) {
                          return Chip(
                            label: Text(field),
                            backgroundColor: Colors.grey[200],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SaralColors.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
