/// Language constants for the Samadhan app
/// Contains all supported languages with their codes and native names
class LanguageConstants {
  static const Map<String, String> supportedLanguages = {
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

  /// Get the native name of a language by its code
  static String getLanguageName(String code) {
    return supportedLanguages[code] ?? code.toUpperCase();
  }

  /// Get all language codes
  static List<String> getAllLanguageCodes() {
    return supportedLanguages.keys.toList();
  }

  /// Get all language entries for dropdown usage
  static List<MapEntry<String, String>> getAllLanguageEntries() {
    return supportedLanguages.entries.toList();
  }

  /// Check if a language code is supported
  static bool isLanguageSupported(String code) {
    return supportedLanguages.containsKey(code);
  }
}