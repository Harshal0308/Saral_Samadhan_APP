import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/admin/providers/admin_data_provider.dart';
import 'package:samadhan_app/admin/widgets/record_detail_dialog.dart';
import 'package:samadhan_app/admin/widgets/edit_record_dialog.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class DataTableView extends StatefulWidget {
  final String title;
  final String tableName;
  final List<Map<String, dynamic>> data;
  final List<String> columns;
  final Map<String, String> columnLabels;

  const DataTableView({
    super.key,
    required this.title,
    required this.tableName,
    required this.data,
    required this.columns,
    required this.columnLabels,
  });

  @override
  State<DataTableView> createState() => _DataTableViewState();
}

class _DataTableViewState extends State<DataTableView> {
  String _searchQuery = '';
  String? _selectedCenter;
  String? _selectedClass;
  int _currentPage = 0;
  final int _rowsPerPage = 20;

  List<Map<String, dynamic>> get filteredData {
    var filtered = widget.data;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((row) {
        return row.values.any((value) =>
            value.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    if (_selectedCenter != null && _selectedCenter!.isNotEmpty) {
      filtered = filtered.where((row) =>
          row['center_name']?.toString() == _selectedCenter).toList();
    }
    
    if (_selectedClass != null && _selectedClass!.isNotEmpty) {
      filtered = filtered.where((row) =>
          row['class_batch']?.toString() == _selectedClass).toList();
    }
    
    return filtered;
  }

  List<Map<String, dynamic>> get paginatedData {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredData.length);
    return filteredData.sublist(start, end);
  }

  int get totalPages => (filteredData.length / _rowsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<AdminDataProvider>(context);
    final centers = dataProvider.getUniqueCenters();
    final classes = dataProvider.getUniqueClasses();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: SaralColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filteredData.length} records',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    });
                  },
                ),
              ),
              if (centers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text('All Centers'),
                      value: _selectedCenter,
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All Centers')),
                        ...centers.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCenter = value?.isEmpty == true ? null : value;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                ),
              if (classes.isNotEmpty && widget.tableName == 'students')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text('All Classes'),
                      value: _selectedClass,
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All Classes')),
                        ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClass = value?.isEmpty == true ? null : value;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: filteredData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No data found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  SaralColors.muted,
                                ),
                                columns: [
                                  ...widget.columns.map((col) => DataColumn(
                                    label: Text(
                                      widget.columnLabels[col] ?? col,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )),
                                  const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: paginatedData.map((row) {
                                  return DataRow(
                                    cells: [
                                      ...widget.columns.map((col) => DataCell(
                                        InkWell(
                                          onTap: () => _showRecordDetail(row),
                                          child: Text(
                                            _formatCellValue(row[col]),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility, size: 20),
                                              color: SaralColors.primary,
                                              tooltip: 'View Details',
                                              onPressed: () => _showRecordDetail(row),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              color: Colors.orange,
                                              tooltip: 'Edit',
                                              onPressed: () => _showEditDialog(row),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20),
                                              color: Colors.red,
                                              tooltip: 'Delete',
                                              onPressed: () => _confirmDelete(row),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                  
                  // Pagination
                  if (totalPages > 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.first_page),
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage = 0)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: SaralColors.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Page ${_currentPage + 1} of $totalPages',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.last_page),
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage = totalPages - 1)
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is Map) return '${value.length} items';
    if (value is List) return '${value.length} items';
    final str = value.toString();
    if (str.length > 50) return '${str.substring(0, 50)}...';
    return str;
  }

  void _showRecordDetail(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => RecordDetailDialog(
        tableName: widget.title,
        record: record,
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => EditRecordDialog(
        tableName: widget.tableName,
        record: record,
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this ${widget.title.toLowerCase().replaceAll('s', '')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final dataProvider = Provider.of<AdminDataProvider>(context, listen: false);
              final success = await dataProvider.deleteRecord(widget.tableName, record['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Record deleted successfully' : 'Failed to delete record'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
