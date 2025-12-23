import 'package:flutter/material.dart';
import 'package:samadhan_app/pages/add_student_page.dart';
import 'package:samadhan_app/pages/take_attendance_page.dart';
import 'package:samadhan_app/pages/view_attendance_page.dart';
import 'package:samadhan_app/pages/student_report_page.dart';
import 'package:samadhan_app/pages/volunteer_daily_report_page.dart';
import 'package:samadhan_app/pages/volunteer_test_report_page.dart';
import 'package:samadhan_app/pages/topic_tracking_page.dart';
import 'package:samadhan_app/pages/volunteer_reports_list_page.dart';
import 'package:samadhan_app/pages/analytics_dashboard_page.dart';
import 'package:samadhan_app/pages/class_learning_distribution_page.dart';
import 'package:samadhan_app/pages/monthly_reports_page.dart';
import 'package:samadhan_app/pages/class_scheduler_page.dart';
import 'package:samadhan_app/pages/events_activities_page.dart';
import 'package:samadhan_app/pages/photo_gallery_page.dart';
import 'package:samadhan_app/pages/exported_reports_page.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Add initial greeting message
    Future.delayed(const Duration(milliseconds: 300), () {
      _addMessage(ChatMessage(
        text: "Hi! I'm your assistant. What would you like to do today?",
        isUser: false,
        type: MessageType.greeting,
      ));
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToAttendanceWithToday() {
    final today = DateTime.now();
    _navigateToPage(ViewAttendancePage(initialDate: today));
  }

  void _showQuickActions() {
    _addMessage(ChatMessage(
      text: "Here are the main tasks you can perform:",
      isUser: false,
      type: MessageType.options,
    ));

    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(ChatMessage(
        text: "Choose a category:",
        isUser: false,
        type: MessageType.categories,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: SaralColors.primary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: SaralColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Assistant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_messages.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: SaralColors.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading assistant...',
                    style: TextStyle(
                      color: SaralColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    switch (message.type) {
      case MessageType.greeting:
        return _buildGreetingMessage(message);
      case MessageType.options:
        return _buildOptionsMessage(message);
      case MessageType.categories:
        return _buildCategoriesMessage(message);
      case MessageType.categoryOptions:
        return _buildCategoryOptionsMessage(message);
      default:
        return _buildTextMessage(message);
    }
  }

  Widget _buildGreetingMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SaralColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _showQuickActions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SaralColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Show me what I can do'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SaralColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOptionsMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SaralColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionsGrid(message.options ?? []),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SaralColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'icon': Icons.people, 'title': 'Attendance & Students', 'color': SaralColors.attendanceColor},
      {'icon': Icons.assignment, 'title': 'Reports & Tracking', 'color': SaralColors.volunteersColor},
      {'icon': Icons.analytics, 'title': 'Analytics & Insights', 'color': SaralColors.analyticsColor},
      {'icon': Icons.build, 'title': 'Tools & Management', 'color': SaralColors.scheduleColor},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(
          category['icon'] as IconData,
          category['title'] as String,
          category['color'] as Color,
          index,
        );
      },
    );
  }

  Widget _buildOptionsGrid(List<Map<String, dynamic>> options) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return _buildOptionButton(option);
      }).toList(),
    );
  }

  Widget _buildOptionButton(Map<String, dynamic> option) {
    return ElevatedButton.icon(
      onPressed: option['action'] as VoidCallback?,
      icon: Icon(option['icon'] as IconData?, size: 18),
      label: Text(option['title'] as String),
      style: ElevatedButton.styleFrom(
        backgroundColor: SaralColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String title, Color color, int categoryIndex) {
    return GestureDetector(
      onTap: () => _showCategoryOptions(categoryIndex),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryOptions(int categoryIndex) {
    final options = [
      // Attendance & Students
      [
        {'icon': Icons.person_add, 'title': 'Add New Student', 'action': () => _handleOptionSelection('Add New Student', () => _navigateToPage(const AddStudentPage()))},
        {'icon': Icons.check_circle, 'title': 'Take Attendance', 'action': () => _handleOptionSelection('Take Attendance', () => _navigateToPage(const TakeAttendancePage()))},
        {'icon': Icons.visibility, 'title': 'View Attendance', 'action': () => _handleOptionSelection('View Attendance', _navigateToAttendanceWithToday)},
        {'icon': Icons.people, 'title': 'Manage Students', 'action': () => _handleOptionSelection('Manage Students', () => _navigateToPage(const StudentReportPage()))},
      ],
      // Reports & Tracking
      [
        {'icon': Icons.assignment, 'title': 'Submit Daily Report', 'action': () => _handleOptionSelection('Submit Daily Report', () => _navigateToPage(const VolunteerDailyReportPage()))},
        {'icon': Icons.quiz, 'title': 'Submit Test Report', 'action': () => _handleOptionSelection('Submit Test Report', () => _navigateToPage(const VolunteerTestReportPage()))},
        {'icon': Icons.track_changes, 'title': 'Track Topic Progress', 'action': () => _handleOptionSelection('Track Topic Progress', () => _navigateToPage(const TopicTrackingPage()))},
        {'icon': Icons.history, 'title': 'View My Reports', 'action': () => _handleOptionSelection('View My Reports', () => _navigateToPage(const VolunteerReportsListPage()))},
      ],
      // Analytics & Insights
      [
        {'icon': Icons.analytics, 'title': 'Analytics Dashboard', 'action': () => _handleOptionSelection('Analytics Dashboard', () => _navigateToPage(const AnalyticsDashboardPage()))},
        {'icon': Icons.pie_chart, 'title': 'Learning Distribution', 'action': () => _handleOptionSelection('Learning Distribution', () => _navigateToPage(const ClassLearningDistributionPage()))},
        {'icon': Icons.calendar_month, 'title': 'Monthly Reports', 'action': () => _handleOptionSelection('Monthly Reports', () => _navigateToPage(const MonthlyReportsPage()))},
      ],
      // Tools & Management
      [
        {'icon': Icons.schedule, 'title': 'Schedule Classes', 'action': () => _handleOptionSelection('Schedule Classes', () => _navigateToPage(const ClassSchedulerPage()))},
        {'icon': Icons.event, 'title': 'Manage Events', 'action': () => _handleOptionSelection('Manage Events', () => _navigateToPage(const EventsActivitiesPage()))},
        {'icon': Icons.photo_library, 'title': 'Photo Gallery', 'action': () => _handleOptionSelection('Photo Gallery', () => _navigateToPage(const PhotoGalleryPage()))},
        {'icon': Icons.file_download, 'title': 'Export Data', 'action': () => _handleOptionSelection('Export Data', () => _navigateToPage(const ExportedReportsPage()))},
      ],
    ];

    final categoryOptions = options[categoryIndex];
    final categoryTitles = ['Attendance & Students', 'Reports & Tracking', 'Analytics & Insights', 'Tools & Management'];

    _addMessage(ChatMessage(
      text: '${categoryTitles[categoryIndex]} options:',
      isUser: false,
      type: MessageType.categoryOptions,
      options: categoryOptions,
    ));
  }

  void _handleOptionSelection(String optionText, VoidCallback navigationAction) {
    // Add user message showing what they selected
    _addMessage(ChatMessage(
      text: optionText,
      isUser: true,
      type: MessageType.text,
    ));

    // Show categories again immediately after user message
    Future.delayed(const Duration(milliseconds: 300), () {
      _showCategoriesAgain();
    });

    // Navigate after showing categories
    Future.delayed(const Duration(milliseconds: 1000), () {
      navigationAction();
    });
  }

  void _showCategoriesAgain() {
    _addMessage(ChatMessage(
      text: "Choose a category:",
      isUser: false,
      type: MessageType.categories,
    ));
  }

  Widget _buildTextMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? SaralColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

enum MessageType {
  text,
  greeting,
  options,
  categories,
  categoryOptions,
}

class ChatMessage {
  final String text;
  final bool isUser;
  final MessageType type;
  final List<Map<String, dynamic>>? options;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.options,
  });
}