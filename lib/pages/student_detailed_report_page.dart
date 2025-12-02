import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class StudentDetailedReportPage extends StatelessWidget {
  final Student student;

  const StudentDetailedReportPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${student.name}\'s Report'),
        backgroundColor: SaralColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to Student Report Page
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Section
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: SaralColors.accent,
                        child: Icon(Icons.person, size: 60, color: SaralColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Name: ${student.name}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Roll No: ${student.rollNo}', style: Theme.of(context).textTheme.bodyLarge),
                    Text('Class: ${student.classBatch}', style: Theme.of(context).textTheme.bodyLarge),
                    Text('Center: Center A - Mumbai', style: Theme.of(context).textTheme.bodyLarge), // Placeholder
                  ],
                ),
              ),
            ),

            // 2. Attendance Summary
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance Summary', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: SaralColors.inputBackground,
                        borderRadius: BorderRadius.circular(SaralRadius.radius),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Monthly Attendance Graph (Placeholder)'),
                    ),
                    const SizedBox(height: 10),
                    Text('Percentage: 85%', style: Theme.of(context).textTheme.bodyLarge), // Placeholder
                    Text('Total classes present: 120/140', style: Theme.of(context).textTheme.bodyLarge), // Placeholder
                  ],
                ),
              ),
            ),

            // 3. Academic Progress
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Academic Progress', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text('Lesson Learned', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    if (student.lessonsLearned.isEmpty)
                      const Text('No lessons recorded yet.')
                    else
                      ...student.lessonsLearned.map((lesson) => ListTile(
                        leading: const Icon(Icons.check, color: Colors.green),
                        title: Text(lesson),
                      )).toList(),
                  ],
                ),
              ),
            ),

            // 4. Test Results
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test Results', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (student.testResults.isEmpty)
                      const Text('No test results recorded yet.')
                    else
                      ...student.testResults.entries.map((entry) => ListTile(
                        leading: const Icon(Icons.assignment, color: Colors.blue),
                        title: Text(entry.key),
                        subtitle: Text('Marks/Grade: ${entry.value}'),
                      )).toList(),
                  ],
                ),
              ),
            ),

            // 5. Additional Metrics
            Card(
              color: SaralColors.card,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SaralRadius.radius2xl)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Additional Metrics', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text('Volunteer effectiveness score: 4.5/5', style: Theme.of(context).textTheme.bodyLarge), // Placeholder
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
