import 'package:flutter/material.dart';
import 'package:samadhan_app/models/baseline_assessment.dart';
import 'package:samadhan_app/data/subjects_topics.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:provider/provider.dart';

class TopicProgressWidget extends StatefulWidget {
  final List<Student> students;
  final String volunteerName;

  const TopicProgressWidget({
    super.key,
    required this.students,
    required this.volunteerName,
  });

  @override
  State<TopicProgressWidget> createState() => _TopicProgressWidgetState();
}

class _TopicProgressWidgetState extends State<TopicProgressWidget> {
  String _selectedSubject = 'Mathematics';
  String _searchQuery = '';
  final Map<int, Map<String, TopicState>> _pendingUpdates = {};

  @override
  Widget build(BuildContext context) {
    final topics = SubjectsTopics.getTopicsForSubject(_selectedSubject);
    final filteredTopics = _searchQuery.isEmpty
        ? topics
        : topics.where((topic) => topic.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Topic Progress Tracking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mark topic understanding for students after class. Use bulk update for efficiency.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Subject selector
        Row(
          children: [
            const Text('Subject: ', style: TextStyle(fontWeight: FontWeight.w500)),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedSubject,
                isExpanded: true,
                items: SubjectsTopics.subjects.map((subject) {
                  return DropdownMenuItem(value: subject, child: Text(subject));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value!;
                    _searchQuery = '';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Topic search
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search topics',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Bulk actions
        if (_pendingUpdates.isNotEmpty) ...[
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_pendingUpdates.length} student(s) have pending updates',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _pendingUpdates.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: _savePendingUpdates,
                    child: const Text('Save All'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Topics list
        Expanded(
          child: ListView.builder(
            itemCount: filteredTopics.length,
            itemBuilder: (context, index) {
              final topic = filteredTopics[index];
              return _buildTopicCard(topic);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(String topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          topic,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bulk update row
                Row(
                  children: [
                    const Text('Bulk Update: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    ...TopicState.values.map((state) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ElevatedButton.icon(
                          onPressed: () => _bulkUpdateTopic(topic, state),
                          icon: Text(state.emoji),
                          label: Text(state.displayName),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getStateColor(state),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Individual student rows
                ...widget.students.map((student) {
                  final topicKey = '$_selectedSubject:$topic';
                  final currentProgress = student.topicProgress[topicKey];
                  final pendingState = _pendingUpdates[student.id]?[topicKey];
                  final displayState = pendingState ?? currentProgress?.state ?? TopicState.notStarted;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${student.name} (${student.rollNo})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: TopicState.values.map((state) {
                              final isSelected = displayState == state;
                              final isPending = pendingState != null && pendingState == state;
                              
                              return GestureDetector(
                                onTap: () => _updateStudentTopic(student.id, topicKey, state),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _getStateColor(state) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isPending ? Border.all(color: Colors.blue, width: 2) : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(state.emoji),
                                      const SizedBox(width: 4),
                                      Text(
                                        state.displayName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontWeight: isPending ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateStudentTopic(int studentId, String topicKey, TopicState state) {
    setState(() {
      _pendingUpdates[studentId] ??= {};
      _pendingUpdates[studentId]![topicKey] = state;
    });
  }

  void _bulkUpdateTopic(String topic, TopicState state) {
    final topicKey = '$_selectedSubject:$topic';
    setState(() {
      for (final student in widget.students) {
        _pendingUpdates[student.id] ??= {};
        _pendingUpdates[student.id]![topicKey] = state;
      }
    });
  }

  Future<void> _savePendingUpdates() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    for (final entry in _pendingUpdates.entries) {
      final studentId = entry.key;
      final updates = entry.value;
      
      final student = widget.students.firstWhere((s) => s.id == studentId);
      
      // Update topic progress
      for (final topicEntry in updates.entries) {
        final topicKey = topicEntry.key;
        final state = topicEntry.value;
        final parts = topicKey.split(':');
        final subject = parts[0];
        final topic = parts[1];
        
        student.topicProgress[topicKey] = TopicProgress(
          subject: subject,
          topic: topic,
          state: state,
          lastUpdated: DateTime.now(),
          updatedBy: widget.volunteerName,
        );
      }
      
      // Save to database
      await studentProvider.updateStudent(student);
    }
    
    setState(() {
      _pendingUpdates.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Topic progress updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Color _getStateColor(TopicState state) {
    switch (state) {
      case TopicState.notStarted:
        return Colors.red.shade400;
      case TopicState.needsRevision:
        return Colors.orange.shade400;
      case TopicState.understood:
        return Colors.green.shade400;
    }
  }
}