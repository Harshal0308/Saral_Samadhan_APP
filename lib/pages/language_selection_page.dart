import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/pages/center_selection_page.dart';
import 'package:samadhan_app/utils/language_constants.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String? _selectedLanguage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Language display names in English for better understanding
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'Hindi',
    'as': 'Assamese',
    'bn': 'Bengali',
    'brx': 'Bodo',
    'doi': 'Dogri',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ks': 'Kashmiri',
    'kok': 'Konkani',
    'mai': 'Maithili',
    'ml': 'Malayalam',
    'mni': 'Manipuri',
    'mr': 'Marathi',
    'ne': 'Nepali',
    'or': 'Odia',
    'pa': 'Punjabi',
    'sa': 'Sanskrit',
    'sat': 'Santali',
    'sd': 'Sindhi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'ur': 'Urdu',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select your preferred language',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B5FFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${LanguageConstants.supportedLanguages.length} languages',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF5B5FFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search languages...',
                              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              hintStyle: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Language grid
                        _buildLanguageGrid(),
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

  Widget _buildLanguageGrid() {
    final allLanguages = LanguageConstants.getAllLanguageEntries();
    
    // Filter languages based on search query
    final filteredLanguages = allLanguages.where((language) {
      final languageCode = language.key;
      final nativeName = language.value.toLowerCase();
      final englishName = _languageNames[languageCode]?.toLowerCase() ?? languageCode.toLowerCase();
      
      return _searchQuery.isEmpty ||
             nativeName.contains(_searchQuery) ||
             englishName.contains(_searchQuery) ||
             languageCode.contains(_searchQuery);
    }).toList();
    
    if (filteredLanguages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No languages found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    // Show all languages in a grid layout
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2, // Increased aspect ratio to give more height
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: filteredLanguages.length,
      itemBuilder: (context, index) {
        final language = filteredLanguages[index];
        final languageCode = language.key;
        final nativeName = language.value;
        final englishName = _languageNames[languageCode] ?? languageCode.toUpperCase();
        
        return _buildLanguageCard(
          context, 
          nativeName,
          englishName,
          languageCode,
        );
      },
    );
  }

  // Language icons for visual variety
  static const Map<String, IconData> _languageIcons = {
    'en': Icons.language,
    'hi': Icons.translate,
    'mr': Icons.record_voice_over,
    'gu': Icons.chat,
    'ta': Icons.speaker_notes,
    'te': Icons.voice_chat,
    'bn': Icons.forum,
    'kn': Icons.campaign,
    'ml': Icons.hearing,
    'pa': Icons.mic,
    'as': Icons.volume_up,
    'or': Icons.surround_sound,
    'ur': Icons.keyboard_voice,
    'sa': Icons.library_books,
    'ne': Icons.spatial_audio,
    'ks': Icons.radio,
    'sd': Icons.podcasts,
    'kok': Icons.multitrack_audio,
    'mai': Icons.audiotrack,
    'mni': Icons.music_note,
    'brx': Icons.queue_music,
    'doi': Icons.graphic_eq,
    'sat': Icons.equalizer,
  };

  Widget _buildLanguageCard(BuildContext context, String nativeName, String englishName, String languageCode) {
    bool isSelected = _selectedLanguage == languageCode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = languageCode;
        });
        Provider.of<UserProvider>(context, listen: false).updateLanguage(languageCode);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CenterSelectionPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? const LinearGradient(
                colors: [Color(0xFF5B5FFF), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF5B5FFF).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? const Color(0xFF5B5FFF).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Language icon or check icon
            isSelected
              ? const Icon(Icons.check_circle, color: Colors.white, size: 18)
              : Icon(
                  _languageIcons[languageCode] ?? Icons.language,
                  color: const Color(0xFF5B5FFF),
                  size: 16,
                ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                nativeName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 1),
            Flexible(
              child: Text(
                englishName,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
