import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/models/baseline_assessment.dart';
import 'package:samadhan_app/data/subjects_topics.dart';

class ClassLearningDistributionPage extends StatefulWidget {
  const ClassLearningDistributionPage({super.key});

  @override
  State<ClassLearningDistributionPage> createState() => _ClassLearningDistributionPageState();
}

class _ClassLearningDistributionPageState extends State<ClassLearningDistributionPage> {
  String? _selectedClass;
  String? _selectedSubject;

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
          'Class Learning Distribution',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer2<StudentProvider, UserProvider>(
        builder: (context, studentProvider, userProvider, child) {
          final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';
          final allStudents = studentProvider.getStudentsByCenter(selectedCenter);
          
          // Group students by class
          final classBatches = <String>{};
          for (var student in allStudents) {
            classBatches.add(student.classBatch);
          }
          
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Selection
                _buildSectionLabel('Select Class'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Choose a class',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  value: _selectedClass,
                  items: classBatches.map((classBatch) {
                    return DropdownMenuItem(
                      value: classBatch,
                      child: Text('Class $classBatch'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                      _selectedSubject = null; // Reset subject when class changes
                    });
                  },
                ),
                
                if (_selectedClass != null) ...[
                  const SizedBox(height: 20),
                  
                  // Subject Selection
                  _buildSectionLabel('Select Subject'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: 'Choose a subject',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    value: _selectedSubject,
                    items: SubjectsTopics.subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Learning Distribution Display
                  if (_selectedSubject != null)
                    _buildLearningDistribution(allStudents, _selectedClass!, _selectedSubject!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLearningDistribution(List<Student> allStudents, String selectedClass, String selectedSubject) {
    // Filter students by selected class
    final classStudents = allStudents.where((s) => s.classBatch == selectedClass).toList();
    
    if (classStudents.isEmpty) {
      return _buildEmptyState('No students found in Class $selectedClass');
    }

    // Count students by learning level
    int beginnerCount = 0;
    int basicCount = 0;
    int comfortableCount = 0;
    int noAssessmentCount = 0;

    List<String> weakTopics = [];

    for (var student in classStudents) {
      final assessment = student.baselineAssessments[selectedSubject];
      if (assessment != null) {
        switch (assessment.level) {
          case LearningLevel.beginner:
            beginnerCount++;
            break;
          case LearningLevel.basic:
            basicCount++;
            break;
          case LearningLevel.comfortable:
            comfortableCount++;
            break;
        }
      } else {
        noAssessmentCount++;
      }
    }

    // Calculate weak topics (>40% students need revision or not started)
    weakTopics = _calculateWeakTopics(classStudents, selectedSubject);

    final totalStudents = classStudents.length;
    final isMixedLevel = (beginnerCount > 0 && comfortableCount > 0) || 
                        (beginnerCount > totalStudents * 0.3 && comfortableCount > totalStudents * 0.3);

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Class $selectedClass',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          selectedSubject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Learning Level Distribution
                  Row(
                    children: [
                      _buildLevelIndicator('🟢', 'Comfortable', comfortableCount, const Color(0xFF10B981)),
                      const SizedBox(width: 16),
                      _buildLevelIndicator('🟡', 'Basic', basicCount, const Color(0xFFF59E0B)),
                      const SizedBox(width: 16),
                      _buildLevelIndicator('🔴', 'Beginner', beginnerCount, const Color(0xFFEF4444)),
                    ],
                  ),
                  
                  if (noAssessmentCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF6B7280), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$noAssessmentCount students need assessment',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Class Type Indicator
                  if (isMixedLevel) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFBBF24)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Mixed-level class',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Teaching Suggestion
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xFF3B82F6), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Suggested Approach:',
                                style: TextStyle(
                                  color: Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTeachingSuggestion(beginnerCount, basicCount, comfortableCount, totalStudents),
                                style: const TextStyle(
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Weak Topics Section
            if (weakTopics.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_down, color: Color(0xFFEF4444), size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Weakest Topics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Topics where >40% students need help',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...weakTopics.take(3).map((topic) {
                      final index = weakTopics.indexOf(topic) + 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$index',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                topic,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(String emoji, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count students',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTeachingSuggestion(int beginnerCount, int basicCount, int comfortableCount, int totalStudents) {
    final beginnerPercent = (beginnerCount / totalStudents * 100).round();
    final basicPercent = (basicCount / totalStudents * 100).round();
    final comfortablePercent = (comfortableCount / totalStudents * 100).round();

    if (beginnerPercent >= 60) {
      return 'Focus on foundational concepts with lots of examples and practice';
    } else if (comfortablePercent >= 60) {
      return 'Introduce advanced topics and challenging problems';
    } else if (basicPercent >= 50) {
      return 'Build on existing knowledge with guided practice';
    } else {
      return 'Start with basics, provide examples, then advance gradually';
    }
  }

  List<String> _calculateWeakTopics(List<Student> students, String subject) {
    final topicCounts = <String, Map<String, int>>{};
    final allTopics = SubjectsTopics.getTopicsForSubject(subject);
    
    // Initialize counts for all topics
    for (var topic in allTopics) {
      topicCounts[topic] = {
        'notStarted': 0,
        'needsRevision': 0,
        'understood': 0,
        'total': 0,
      };
    }
    
    // Count topic states for each student
    for (var student in students) {
      for (var topic in allTopics) {
        final key = '$subject:$topic';
        final progress = student.topicProgress[key];
        
        topicCounts[topic]!['total'] = topicCounts[topic]!['total']! + 1;
        
        if (progress != null) {
          switch (progress.state) {
            case TopicState.notStarted:
              topicCounts[topic]!['notStarted'] = topicCounts[topic]!['notStarted']! + 1;
              break;
            case TopicState.needsRevision:
              topicCounts[topic]!['needsRevision'] = topicCounts[topic]!['needsRevision']! + 1;
              break;
            case TopicState.understood:
              topicCounts[topic]!['understood'] = topicCounts[topic]!['understood']! + 1;
              break;
          }
        } else {
          // No progress recorded = not started
          topicCounts[topic]!['notStarted'] = topicCounts[topic]!['notStarted']! + 1;
        }
      }
    }
    
    // Find topics where >40% students need help (not started or needs revision)
    final weakTopics = <String>[];
    
    for (var entry in topicCounts.entries) {
      final topic = entry.key;
      final counts = entry.value;
      final total = counts['total']!;
      
      if (total > 0) {
        final needHelp = counts['notStarted']! + counts['needsRevision']!;
        final helpPercentage = (needHelp / total * 100);
        
        if (helpPercentage > 40) {
          weakTopics.add(topic);
        }
      }
    }
    
    return weakTopics;
  }

  Widget _buildEmptyState(String message) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }
}