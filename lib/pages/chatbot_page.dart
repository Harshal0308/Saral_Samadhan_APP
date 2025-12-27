import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/pages/add_student_page.dart';
import 'package:samadhan_app/pages/take_attendance_page.dart';
import 'package:samadhan_app/pages/view_attendance_page.dart';
import 'package:samadhan_app/pages/student_report_page.dart';
import 'package:samadhan_app/pages/volunteer_daily_report_page.dart';
import 'package:samadhan_app/pages/volunteer_test_report_page.dart';
import 'package:samadhan_app/pages/topic_tracking_page.dart';
import 'package:samadhan_app/pages/volunteer_reports_list_page.dart';
import 'package:samadhan_app/pages/analytics_dashboard_page.dart';
import 'package:samadhan_app/pages/monthly_reports_page.dart';
import 'package:samadhan_app/pages/class_scheduler_page.dart';
import 'package:samadhan_app/pages/events_activities_page.dart';
import 'package:samadhan_app/pages/photo_gallery_page.dart';
import 'package:samadhan_app/pages/exported_reports_page.dart';
import 'package:samadhan_app/theme/saral_theme.dart';
import 'package:samadhan_app/l10n/app_localizations.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/utils/language_constants.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late AnimationController _slideController;
  
  // Session-based language selection state
  bool _languageSelected = false;
  String? _sessionLanguage;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Add initial language selection message after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLanguageSelectionFirst();
    });
  }

  void _showLanguageSelectionFirst() {
    // Show language selection as the first step
    _addMessage(ChatMessage(
      text: "Hello! I'm SAATHI 👋\nPlease choose your preferred language to continue.",
      isUser: false,
      type: MessageType.languageSelection,
    ));
  }

  void _onLanguageSelected(String languageCode, String languageName) {
    // Store session language
    _sessionLanguage = languageCode;
    _languageSelected = true;
    
    // Update the app language via UserProvider (session-based, not database)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.updateLanguage(languageCode);
    
    // Add user's selection as a message
    _addMessage(ChatMessage(
      text: languageName,
      isUser: true,
      type: MessageType.text,
    ));
    
    // Show confirmation and continue with normal flow
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _addMessage(ChatMessage(
          text: "Great! I'll continue in $languageName. 🎉",
          isUser: false,
          type: MessageType.text,
        ));
        
        // After confirmation, show the normal greeting
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _addInitialGreeting();
          }
        });
      }
    });
  }

  void _addInitialGreeting() {
    final currentLanguage = Provider.of<UserProvider>(context, listen: false).userSettings.language;
    final languageNames = {
      'en': 'English',
      'hi': 'हिन्दी',
      'as': 'অসমীয়া',
      'bn': 'বাংলা',
      'brx': 'बर\'',
      'doi': 'डोगरी',
      'gu': 'ગુજરાતી',
      'kn': 'ಕನ್ನಡ',
      'ks': 'کٲشُر',
      'kok': 'कोंकणी',
      'mai': 'मैथिली',
      'ml': 'മലയാളം',
      'mni': 'মৈতৈলোন্',
      'mr': 'मराठी',
      'ne': 'नेपाली',
      'or': 'ଓଡ଼ିଆ',
      'pa': 'ਪੰਜਾਬੀ',
      'sa': 'संस्कृतम्',
      'sat': 'ᱥᱟᱱᱛᱟᱲᱤ',
      'sd': 'سنڌي',
      'ta': 'தமிழ்',
      'te': 'తెలుగు',
      'ur': 'اردو',
    };
    
    _addMessage(ChatMessage(
      text: AppLocalizations.of(context)!.chatbotGreeting,
      isUser: false,
      type: MessageType.greeting,
      languageInfo: LanguageConstants.getLanguageName(currentLanguage),
    ));
  }

  void _showLanguageSelector() {
    final languages = LanguageConstants.getAllLanguageEntries()
        .map((entry) => {
              'code': entry.key,
              'name': entry.key == 'en' ? 'English' : 
                     entry.key == 'hi' ? 'Hindi' :
                     entry.key == 'as' ? 'Assamese' :
                     entry.key == 'bn' ? 'Bengali' :
                     entry.key == 'brx' ? 'Bodo' :
                     entry.key == 'doi' ? 'Dogri' :
                     entry.key == 'gu' ? 'Gujarati' :
                     entry.key == 'kn' ? 'Kannada' :
                     entry.key == 'ks' ? 'Kashmiri' :
                     entry.key == 'kok' ? 'Konkani' :
                     entry.key == 'mai' ? 'Maithili' :
                     entry.key == 'ml' ? 'Malayalam' :
                     entry.key == 'mni' ? 'Manipuri' :
                     entry.key == 'mr' ? 'Marathi' :
                     entry.key == 'ne' ? 'Nepali' :
                     entry.key == 'or' ? 'Odia' :
                     entry.key == 'pa' ? 'Punjabi' :
                     entry.key == 'sa' ? 'Sanskrit' :
                     entry.key == 'sat' ? 'Santali' :
                     entry.key == 'sd' ? 'Sindhi' :
                     entry.key == 'ta' ? 'Tamil' :
                     entry.key == 'te' ? 'Telugu' :
                     entry.key == 'ur' ? 'Urdu' : entry.key.toUpperCase(),
              'nativeName': entry.value,
            })
        .toList();

    final currentLanguage = Provider.of<UserProvider>(context, listen: false).userSettings.language;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.language, color: SaralColors.primary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.selectLanguage),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                final isSelected = currentLanguage == language['code'];
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? SaralColors.primary.withOpacity(0.1) : null,
                  child: ListTile(
                    leading: isSelected 
                      ? Icon(Icons.check_circle, color: SaralColors.primary)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                    title: Text(
                      language['name']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? SaralColors.primary : null,
                      ),
                    ),
                    subtitle: Text(
                      language['nativeName']!,
                      style: TextStyle(
                        color: isSelected ? SaralColors.primary : Colors.grey[600],
                      ),
                    ),
                    onTap: () async {
                      if (!isSelected) {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        await userProvider.updateLanguage(language['code']!);
                        
                        if (mounted) {
                          Navigator.of(context).pop();
                          
                          // Clear messages and show new greeting in selected language
                          setState(() {
                            _messages.clear();
                          });
                          
                          // Add greeting in new language after a short delay
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              _addInitialGreeting();
                            }
                          });
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
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
    final localizations = AppLocalizations.of(context)!;
    _addMessage(ChatMessage(
      text: localizations.chatbotMainTasks,
      isUser: false,
      type: MessageType.options,
    ));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _addMessage(ChatMessage(
          text: localizations.chatbotChooseCategory,
          isUser: false,
          type: MessageType.categories,
        ));
      }
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
            Text(
              AppLocalizations.of(context)!.chatbotTitle,
              style: const TextStyle(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: _showLanguageSelector,
            tooltip: AppLocalizations.of(context)!.selectLanguage,
          ),
        ],
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
                    AppLocalizations.of(context)!.chatbotLoadingAssistant,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showLanguageSelector,
        backgroundColor: SaralColors.primary,
        child: const Icon(Icons.language, color: Colors.white),
        tooltip: AppLocalizations.of(context)!.selectLanguage,
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    switch (message.type) {
      case MessageType.languageSelection:
        return _buildLanguageSelectionMessage(message);
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

  Widget _buildLanguageSelectionMessage(ChatMessage message) {
    // Primary languages to show as buttons
    final primaryLanguages = [
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
      {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
      {'code': 'mr', 'name': 'Marathi', 'nativeName': 'मराठी'},
      {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
      {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
      {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
    ];

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
                  const SizedBox(height: 16),
                  // Language selection buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: primaryLanguages.map((lang) {
                      return ElevatedButton(
                        onPressed: () => _onLanguageSelected(lang['code']!, lang['nativeName']!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SaralColors.primary.withOpacity(0.1),
                          foregroundColor: SaralColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: SaralColors.primary.withOpacity(0.3)),
                          ),
                        ),
                        child: Text(
                          lang['nativeName']!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // More languages button
                  TextButton.icon(
                    onPressed: _showAllLanguagesSelector,
                    icon: Icon(Icons.language, size: 18, color: SaralColors.primary),
                    label: Text(
                      'More languages...',
                      style: TextStyle(color: SaralColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllLanguagesSelector() {
    final allLanguages = LanguageConstants.getAllLanguageEntries()
        .map((entry) => {
              'code': entry.key,
              'name': entry.key == 'en' ? 'English' : 
                     entry.key == 'hi' ? 'Hindi' :
                     entry.key == 'as' ? 'Assamese' :
                     entry.key == 'bn' ? 'Bengali' :
                     entry.key == 'brx' ? 'Bodo' :
                     entry.key == 'doi' ? 'Dogri' :
                     entry.key == 'gu' ? 'Gujarati' :
                     entry.key == 'kn' ? 'Kannada' :
                     entry.key == 'ks' ? 'Kashmiri' :
                     entry.key == 'kok' ? 'Konkani' :
                     entry.key == 'mai' ? 'Maithili' :
                     entry.key == 'ml' ? 'Malayalam' :
                     entry.key == 'mni' ? 'Manipuri' :
                     entry.key == 'mr' ? 'Marathi' :
                     entry.key == 'ne' ? 'Nepali' :
                     entry.key == 'or' ? 'Odia' :
                     entry.key == 'pa' ? 'Punjabi' :
                     entry.key == 'sa' ? 'Sanskrit' :
                     entry.key == 'sat' ? 'Santali' :
                     entry.key == 'sd' ? 'Sindhi' :
                     entry.key == 'ta' ? 'Tamil' :
                     entry.key == 'te' ? 'Telugu' :
                     entry.key == 'ur' ? 'Urdu' : entry.key.toUpperCase(),
              'nativeName': entry.value,
            })
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.language, color: SaralColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Language',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: allLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = allLanguages[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SaralColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.translate, color: SaralColors.primary, size: 20),
                        ),
                        title: Text(lang['name']!),
                        subtitle: Text(lang['nativeName']!),
                        onTap: () {
                          Navigator.pop(context);
                          _onLanguageSelected(lang['code']!, lang['nativeName']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  if (message.languageInfo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: SaralColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language, size: 14, color: SaralColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            message.languageInfo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: SaralColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    child: Text(AppLocalizations.of(context)!.chatbotShowOptions),
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
    final localizations = AppLocalizations.of(context)!;
    final categories = [
      {'icon': Icons.people, 'title': localizations.categoryAttendanceStudents, 'color': SaralColors.attendanceColor},
      {'icon': Icons.assignment, 'title': localizations.categoryReportsTracking, 'color': SaralColors.volunteersColor},
      {'icon': Icons.analytics, 'title': localizations.categoryAnalyticsInsights, 'color': SaralColors.analyticsColor},
      {'icon': Icons.build, 'title': localizations.categoryToolsManagement, 'color': SaralColors.scheduleColor},
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
    final localizations = AppLocalizations.of(context)!;
    final options = [
      // Attendance & Students
      [
        {'icon': Icons.person_add, 'title': localizations.optionAddStudent, 'action': () => _handleOptionSelection(localizations.optionAddStudent, () => _navigateToPage(const AddStudentPage()))},
        {'icon': Icons.check_circle, 'title': localizations.optionTakeAttendance, 'action': () => _handleOptionSelection(localizations.optionTakeAttendance, () => _navigateToPage(const TakeAttendancePage()))},
        {'icon': Icons.visibility, 'title': localizations.optionViewAttendance, 'action': () => _handleOptionSelection(localizations.optionViewAttendance, _navigateToAttendanceWithToday)},
        {'icon': Icons.people, 'title': localizations.optionManageStudents, 'action': () => _handleOptionSelection(localizations.optionManageStudents, () => _navigateToPage(const StudentReportPage()))},
      ],
      // Reports & Tracking
      [
        {'icon': Icons.assignment, 'title': localizations.optionSubmitDailyReport, 'action': () => _handleOptionSelection(localizations.optionSubmitDailyReport, () => _navigateToPage(const VolunteerDailyReportPage()))},
        {'icon': Icons.quiz, 'title': localizations.optionSubmitTestReport, 'action': () => _handleOptionSelection(localizations.optionSubmitTestReport, () => _navigateToPage(const VolunteerTestReportPage()))},
        {'icon': Icons.track_changes, 'title': localizations.optionTrackTopicProgress, 'action': () => _handleOptionSelection(localizations.optionTrackTopicProgress, () => _navigateToPage(const TopicTrackingPage()))},
        {'icon': Icons.history, 'title': localizations.optionViewMyReports, 'action': () => _handleOptionSelection(localizations.optionViewMyReports, () => _navigateToPage(const VolunteerReportsListPage()))},
      ],
      // Analytics & Insights
      [
        {'icon': Icons.analytics, 'title': localizations.optionAnalyticsDashboard, 'action': () => _handleOptionSelection(localizations.optionAnalyticsDashboard, () => _navigateToPage(const AnalyticsDashboardPage()))},
        {'icon': Icons.calendar_month, 'title': localizations.optionMonthlyReports, 'action': () => _handleOptionSelection(localizations.optionMonthlyReports, () => _navigateToPage(const MonthlyReportsPage()))},
      ],
      // Tools & Management
      [
        {'icon': Icons.schedule, 'title': localizations.optionScheduleClasses, 'action': () => _handleOptionSelection(localizations.optionScheduleClasses, () => _navigateToPage(const ClassSchedulerPage()))},
        {'icon': Icons.event, 'title': localizations.optionManageEvents, 'action': () => _handleOptionSelection(localizations.optionManageEvents, () => _navigateToPage(const EventsActivitiesPage()))},
        {'icon': Icons.photo_library, 'title': localizations.optionPhotoGallery, 'action': () => _handleOptionSelection(localizations.optionPhotoGallery, () => _navigateToPage(const PhotoGalleryPage()))},
        {'icon': Icons.file_download, 'title': localizations.optionExportData, 'action': () => _handleOptionSelection(localizations.optionExportData, () => _navigateToPage(const ExportedReportsPage()))},
      ],
    ];

    final categoryOptions = options[categoryIndex];
    final categoryTitles = [
      localizations.categoryAttendanceStudents, 
      localizations.categoryReportsTracking, 
      localizations.categoryAnalyticsInsights, 
      localizations.categoryToolsManagement
    ];

    _addMessage(ChatMessage(
      text: localizations.categoryOptionsFor(categoryTitles[categoryIndex]),
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
      text: AppLocalizations.of(context)!.chatbotChooseCategory,
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
  languageSelection,
}

class ChatMessage {
  final String text;
  final bool isUser;
  final MessageType type;
  final List<Map<String, dynamic>>? options;
  final String? languageInfo;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.options,
    this.languageInfo,
  });
}