import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/main.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/pages/center_selection_page.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String? _selectedLanguage;

  static const Map<String, String> _languageToCode = {
    'English': 'en',
    'Hindi': 'hi',
    'Marathi': 'mr',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Curved top with dark background
            Container(
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Choose Language',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Language options
                        _buildLanguageButton(context, 'English', 'en'),
                        const SizedBox(height: 12),
                        _buildLanguageButton(context, 'हिंदी (Hindi)', 'hi'),
                        const SizedBox(height: 12),
                        _buildLanguageButton(context, 'मराठी (Marathi)', 'mr'),
                        const SizedBox(height: 32),
                        // Helper text
                        Center(
                          child: Text(
                            'You can change language anytime in settings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, String language, String languageCode) {
    bool isSelected = _selectedLanguage == languageCode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = languageCode;
        });
        Provider.of<UserProvider>(context, listen: false).updateLanguage(languageCode);
        // Navigate to center selection page after language selection
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CenterSelectionPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B5FFF) : Colors.white,
          border: !isSelected ? Border.all(color: Color(0xFFE5E5EA), width: 1) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF5B5FFF).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
