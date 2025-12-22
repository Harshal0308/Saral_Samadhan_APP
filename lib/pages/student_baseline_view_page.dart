import 'package:flutter/material.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/models/baseline_assessment.dart';
import 'package:samadhan_app/data/subjects_topics.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class StudentBaselineViewPage extends StatefulWidget {
  final Student student;

  const StudentBaselineViewPage({super.key, required this.student});

  @override
  State<StudentBaselineViewPage> createState() => _StudentBaselineViewPageState();
}

class _StudentBaselineViewPageState extends State<StudentBaselineViewPage> {
  String _selectedSubject = 'Mathematics';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} - Learning Profile'),
        backgroundColor: SaralColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: SaralColors.primary,
                      child: Text(
                        widget.student.name.isNotEmpty ? widget.student.name[0].toUpperCase() : 'S',
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.student.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('Roll No: ${widget.student.rollNo}'),
                          Text('Class: ${widget.student.classBatch}'),
                          Text('Center: ${widget.student.centerName}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Baseline Assessments Section
            const Text(
              'Baseline Assessments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (widget.student.baselineAssessments.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No baseline assessments available. This helps volunteers understand where to start teaching.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...widget.student.baselineAssessments.entries.map((entry) {
                final subject = entry.key;
                final assessment = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getLevelColor(assessment.level),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getSubjectIcon(subject),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(subject),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getLevelColor(assessment.level),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                assessment.level.displayName,
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                            if (assessment.score != null) ...[
                              const SizedBox(width: 8),
                              Text('Score: ${assessment.score}/10'),
                            ],
                          ],
                        ),
                        if (assessment.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            assessment.notes!,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                    trailing: Text(
                      assessment.level.description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),

            // Topic Progress Section
            const Text(
              'Topic Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Subject selector
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Subject',
                border: OutlineInputBorder(),
              ),
              value: _selectedSubject,
              items: SubjectsTopics.subjects.map((subject) {
                return DropdownMenuItem(value: subject, child: Text(subject));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Topic progress for selected subject
            _buildTopicProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicProgress() {
    final topics = SubjectsTopics.getTopicsForSubject(_selectedSubject);
    final subjectProgress = widget.student.topicProgress.entries
        .where((entry) => entry.key.startsWith('$_selectedSubject:'))
        .toList();

    if (subjectProgress.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No topic progress recorded for $_selectedSubject yet. Volunteers can track progress after teaching.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group progress by state
    final progressByState = <TopicState, List<TopicProgress>>{};
    for (final entry in subjectProgress) {
      final progress = entry.value;
      progressByState[progress.state] ??= [];
      progressByState[progress.state]!.add(progress);
    }

    return Column(
      children: [
        // Progress summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress Summary',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: TopicState.values.map((state) {
                    final count = progressByState[state]?.length ?? 0;
                    return Column(
                      children: [
                        Text(
                          state.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          state.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Detailed progress by state
        ...TopicState.values.map((state) {
          final stateProgress = progressByState[state] ?? [];
          if (stateProgress.isEmpty) return const SizedBox.shrink();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Text(
                state.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              title: Text('${state.displayName} (${stateProgress.length})'),
              children: stateProgress.map((progress) {
                return ListTile(
                  title: Text(progress.topic),
                  subtitle: progress.updatedBy != null
                      ? Text('Updated by ${progress.updatedBy} on ${_formatDate(progress.lastUpdated)}')
                      : Text('Updated on ${_formatDate(progress.lastUpdated)}'),
                  dense: true,
                );
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getLevelColor(LearningLevel level) {
    switch (level) {
      case LearningLevel.beginner:
        return Colors.red.shade400;
      case LearningLevel.basic:
        return Colors.orange.shade400;
      case LearningLevel.comfortable:
        return Colors.green.shade400;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.language;
      case 'social science':
        return Icons.public;
      case 'computer':
        return Icons.computer;
      default:
        return Icons.book;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}