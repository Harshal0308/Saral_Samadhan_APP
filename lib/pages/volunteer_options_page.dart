import 'package:flutter/material.dart';
import 'package:samadhan_app/pages/volunteer_daily_report_page.dart';
import 'package:samadhan_app/pages/volunteer_reports_list_page.dart';

class VolunteerOptionsPage extends StatelessWidget {
  const VolunteerOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Options'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to Dashboard
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VolunteerDailyReportPage()),
                  );
                  print('Submit Daily Report button pressed');
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit Daily Report'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VolunteerReportsListPage()),
                  );
                  print('View Past Reports button pressed');
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Past Reports'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
