import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class RecordDetailDialog extends StatelessWidget {
  final String tableName;
  final Map<String, dynamic> record;

  const RecordDetailDialog({
    super.key,
    required this.tableName,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
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
                color: SaralColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$tableName Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    tooltip: 'Copy JSON',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: record.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: record.entries.map((entry) {
                    return _buildField(entry.key, entry.value);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String key, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatKey(key),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          _buildValue(value),
        ],
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

  Widget _buildValue(dynamic value) {
    if (value == null) {
      return Text(
        'null',
        style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
      );
    }

    if (value is bool) {
      return Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(value ? 'Yes' : 'No'),
        ],
      );
    }

    if (value is Map) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: value.entries.take(10).map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Text(
                      e.value.toString(),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    if (value is List) {
      if (value.isEmpty) {
        return Text(
          'Empty list',
          style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
        );
      }
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: value.take(10).map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: SaralColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.toString())),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return SelectableText(
      value.toString(),
      style: const TextStyle(fontSize: 14),
    );
  }
}
