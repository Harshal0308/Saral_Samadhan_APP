import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:samadhan_app/pages/events_activities_page.dart';
import 'package:samadhan_app/pages/photo_viewer_page.dart'; // New import

class PhotoGalleryPage extends StatelessWidget {
  const PhotoGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Gallery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to Dashboard
          },
        ),
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          final allPhotoPaths = eventProvider.events.expand((event) => event.photoPaths).toList();

          return Column(
            children: [
              Expanded(
                child: allPhotoPaths.isEmpty
                    ? const Center(child: Text('No photos uploaded yet.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: allPhotoPaths.length,
                        itemBuilder: (context, index) {
                          final photoPath = allPhotoPaths[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhotoViewerPage(imagePath: photoPath),
                                ),
                              );
                              print('Tapped on photo: $photoPath');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(photoPath)), // Display actual image from path
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EventsActivitiesPage()),
                    );
                    print('Navigate to Add Event to add photos');
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add New Event Photos', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
