import 'package:flutter/material.dart';
import 'package:samadhan_app/pages/add_student_page.dart';
import 'package:samadhan_app/pages/take_attendance_page.dart';
import 'package:samadhan_app/pages/view_attendance_page.dart'; // New import
import 'package:samadhan_app/theme/saral_theme.dart';

class AttendanceOptionsPage extends StatelessWidget {
  const AttendanceOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Options'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to Dashboard
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Info box at top (no AI wording)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SaralColors.muted,
                    borderRadius: BorderRadius.circular(SaralRadius.radius),
                  ),
                  child: Text(
                    'Use quick capture for attendance or mark manually',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 18),

                // Tiles
                _buildOptionTile(
                  context,
                  icon: Icons.person_add,
                  iconBg: Color(0xFFEFF6FF),
                  title: 'Add Student',
                  subtitle: 'Register new student',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddStudentPage())),
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  context,
                  icon: Icons.camera_alt,
                  iconBg: Color(0xFFCCFFDD),
                  title: 'Take Attendance',
                  subtitle: 'Photo + Manual marking',
                  accentColor: Colors.green,
                  note: 'Capture group photo to mark attendance',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TakeAttendancePage())),
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  context,
                  icon: Icons.list_alt,
                  iconBg: Color(0xFFE6F0FF),
                  title: "View Today's Attendance",
                  subtitle: 'See marked attendance',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ViewAttendancePage(initialDate: DateTime.now()))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required Color iconBg, required String title, required String subtitle, Color? accentColor, String? note, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: accentColor ?? Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 12),
              Text(note, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
            ]
          ],
        ),
      ),
    );
  }
}
