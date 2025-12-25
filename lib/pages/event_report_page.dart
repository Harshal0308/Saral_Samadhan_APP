import 'dart:io';
import 'package:flutter/material.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:samadhan_app/pages/event_photo_viewer_page.dart';

class EventReportPage extends StatelessWidget {
  final Event event;

  const EventReportPage({super.key, required this.event});

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
          'Event Report',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today, event.date.toLocal().toString().split(' ')[0]),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time, event.time.format(context)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, event.centerName.isNotEmpty ? event.centerName : 'No center specified'),
                  if (event.classBatch.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.class_, 'Class ${event.classBatch}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Attendance Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.people, color: Color(0xFF16A34A), size: 24),
                      const SizedBox(width: 12),
                      Text(
                        event.attendanceSummary,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  if (event.presentStudentRolls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Present Students: ${event.presentStudentRolls.join(", ")}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Topics Covered
            if (event.topics.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Topics Covered',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.topics.map((topic) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            topic,
                            style: const TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Photos
            if (event.photoPaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          '${event.photoPaths.length} photos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: event.photoPaths.length,
                      itemBuilder: (context, index) {
                        final photoPath = event.photoPaths[index];
                        final isLocal = !photoPath.startsWith('http://') && !photoPath.startsWith('https://');
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventPhotoViewerPage(
                                  photoUrls: event.photoPaths,
                                  initialIndex: index,
                                  eventTitle: event.title,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isLocal
                                ? Image.file(
                                    File(photoPath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: photoPath,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error, color: Colors.red),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
