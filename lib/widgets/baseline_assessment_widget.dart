import 'package:flutter/material.dart';
import 'package:samadhan_app/models/baseline_assessment.dart';
import 'package:samadhan_app/data/subjects_topics.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class BaselineAssessmentWidget extends StatefulWidget {
  final Map<String, BaselineAssessment> initialAssessments;
  final Function(Map<String, BaselineAssessment>) onAssessmentsChanged;

  const BaselineAssessmentWidget({
    super.key,
    required this.initialAssessments,
    required this.onAssessmentsChanged,
  });

  @override
  State<BaselineAssessmentWidget> createState() => _BaselineAssessmentWidgetState();
}

class _BaselineAssessmentWidgetState extends State<BaselineAssessmentWidget> {
  late Map<String, BaselineAssessment> _assessments;
  final List<String> _subjects = SubjectsTopics.subjects;

  @override
  void initState() {
    super.initState();
    _assessments = Map.from(widget.initialAssessments);
  }

  void _showAssessmentDialog(String subject) {
    final existingAssessment = _assessments[subject];
    LearningLevel selectedLevel = existingAssessment?.level ?? LearningLevel.beginner;
    int? manualScore = existingAssessment?.score;
    final notesController = TextEditingController(text: existingAssessment?.notes ?? '');
    final scoreController = TextEditingController(text: manualScore?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Baseline Assessment - $subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Learning Level:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...LearningLevel.values.map((level) {
                  return RadioListTile<LearningLevel>(
                    title: Text(level.displayName),
                    subtitle: Text(level.description, style: const TextStyle(fontSize: 12)),
                    value: level,
                    groupValue: selectedLevel,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLevel = value!;
                      });
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Manual Score (Optional):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: scoreController,
                  decoration: const InputDecoration(
                    labelText: 'Score out of 10',
                    hintText: 'e.g., 7',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final score = int.tryParse(value);
                    if (score != null && score >= 0 && score <= 10) {
                      manualScore = score;
                    } else {
                      manualScore = null;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Additional observations...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Remove assessment
                setState(() {
                  _assessments.remove(subject);
                });
                widget.onAssessmentsChanged(_assessments);
                Navigator.pop(context);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                final assessment = BaselineAssessment(
                  subject: subject,
                  level: selectedLevel,
                  score: manualScore,
                  assessedOn: DateTime.now(),
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                );
                
                setState(() {
                  _assessments[subject] = assessment;
                });
                widget.onAssessmentsChanged(_assessments);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Baseline Assessment (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Assess student\'s current level in each subject. This helps volunteers understand where to start.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        
        // Subject selection chips
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _subjects.map((subject) {
            final hasAssessment = _assessments.containsKey(subject);
            final assessment = _assessments[subject];
            
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(subject),
                  if (hasAssessment) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getLevelColor(assessment!.level),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        assessment.level.displayName,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
              selected: hasAssessment,
              onSelected: (_) => _showAssessmentDialog(subject),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue.shade50,
            );
          }).toList(),
        ),
        
        if (_assessments.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Current Assessments:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ..._assessments.entries.map((entry) {
            final subject = entry.key;
            final assessment = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
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
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showAssessmentDialog(subject),
                ),
              ),
            );
          }).toList(),
        ],
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
}