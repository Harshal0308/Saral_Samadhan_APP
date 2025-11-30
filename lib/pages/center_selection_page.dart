import 'package:flutter/material.dart';
import 'package:samadhan_app/pages/main_dashboard_page.dart';

class CenterSelectionPage extends StatelessWidget {
  const CenterSelectionPage({super.key});

  final List<String> centers = const [
    'Center A - Mumbai',
    'Center B - Delhi',
    'Center C - Bangalore',
    'Center D - Pune',
    'Center E - Chennai',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page (Language Selection)
          },
        ),
        title: const Text('Select Your Center'),
      ),
      body: ListView.builder(
        itemCount: centers.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(centers[index]),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement logic to save selected center
                print('Selected Center: ${centers[index]}');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainDashboardPage()),
                  (Route<dynamic> route) => false, // Remove all previous routes
                );
              },
            ),
          );
        },
      ),
    );
  }
}
