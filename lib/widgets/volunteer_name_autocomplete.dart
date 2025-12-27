import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/volunteer_management_provider.dart';
import 'package:samadhan_app/models/volunteer.dart';

class VolunteerNameAutocomplete extends StatefulWidget {
  final String centerName;
  final Function(String) onVolunteerSelected;
  final String? initialValue;
  final String? hintText;
  final bool enabled;

  const VolunteerNameAutocomplete({
    Key? key,
    required this.centerName,
    required this.onVolunteerSelected,
    this.initialValue,
    this.hintText,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<VolunteerNameAutocomplete> createState() => _VolunteerNameAutocompleteState();
}

class _VolunteerNameAutocompleteState extends State<VolunteerNameAutocomplete> {
  late TextEditingController _controller;
  List<VolunteerSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<VolunteerManagementProvider>(context, listen: false);
      final suggestions = await provider.getVolunteerSuggestions(widget.centerName);
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading volunteer suggestions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<VolunteerSuggestion>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _suggestions.take(10); // Show top 10 when empty
            }
            
            return _suggestions.where((suggestion) {
              return suggestion.name
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            }).take(10);
          },
          displayStringForOption: (VolunteerSuggestion option) => option.name,
          onSelected: (VolunteerSuggestion selection) {
            _controller.text = selection.name;
            widget.onVolunteerSelected(selection.name);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Sync our controller with the autocomplete controller
            if (controller.text != _controller.text) {
              controller.text = _controller.text;
            }
            
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              decoration: InputDecoration(
                labelText: 'Volunteer Name',
                hintText: widget.hintText ?? 'Enter or select volunteer name',
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter volunteer name';
                }
                return null;
              },
              onChanged: (value) {
                _controller.text = value;
                widget.onVolunteerSelected(value);
              },
              onFieldSubmitted: (value) {
                onFieldSubmitted();
                widget.onVolunteerSelected(value);
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            option.attendanceCount.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        title: Text(
                          option.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${option.attendanceCount} reports • Last: ${_formatDate(option.lastReportDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (_suggestions.isNotEmpty && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${_suggestions.length} volunteers available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}