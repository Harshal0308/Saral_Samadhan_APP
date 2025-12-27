// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get login => 'लॉग इन करें';

  @override
  String get username => 'उपयोगकर्ता नाम';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get saralDashboard => 'सरल डैशबोर्ड';

  @override
  String get welcome => 'स्वागत है';

  @override
  String get attendance => 'उपस्थिति';

  @override
  String get students => 'छात्र';

  @override
  String get volunteers => 'स्वयंसेवक';

  @override
  String get scheduler => 'अनुसूचक';

  @override
  String get events => 'आयोजन';

  @override
  String get exports => 'निर्यात';

  @override
  String get accountDetails => 'अकाउंट विवरण';

  @override
  String get changePhoto => 'फोटो बदलें';

  @override
  String get name => 'नाम';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get oldPassword => 'पुराना पासवर्ड';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get confirmNewPassword => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get appLanguage => 'ऐप की भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get saveDetails => 'विवरण सहेजें';

  @override
  String get resetLocalData => 'स्थानीय डेटा रीसेट करें';

  @override
  String get studentReport => 'छात्र रिपोर्ट';

  @override
  String get searchStudents => 'छात्र खोजें';

  @override
  String get filterByClassBatch => 'कक्षा/बैच द्वारा फ़िल्टर करें';

  @override
  String get deleteStudent => 'छात्र को हटाएं';

  @override
  String get areYouSureYouWantToDelete => 'क्या आप वाकई हटाना चाहते हैं';

  @override
  String get volunteerReports => 'स्वयंसेवक रिपोर्ट';

  @override
  String get reportBy => 'रिपोर्ट द्वारा';

  @override
  String get deleteSelectedReports => 'चयनित रिपोर्ट हटाएं';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'क्या आप वाकई $count चयनित रिपोर्ट हटाना चाहते हैं?';
  }

  @override
  String get quickActions => 'त्वरित कार्रवाई';

  @override
  String get mediaGallery => 'मीडिया गैलरी';

  @override
  String get noStudentsFound => 'कोई छात्र नहीं मिला';

  @override
  String get chatbotTitle => 'SAATHI';

  @override
  String get chatbotGreeting =>
      'नमस्ते! मैं आपका सहायक हूं। आज आप क्या करना चाहेंगे?';

  @override
  String get chatbotShowOptions => 'मुझे दिखाएं कि मैं क्या कर सकता हूं';

  @override
  String get chatbotMainTasks => 'यहां मुख्य कार्य हैं जो आप कर सकते हैं:';

  @override
  String get chatbotChooseCategory => 'एक श्रेणी चुनें:';

  @override
  String get chatbotLoadingAssistant => 'सहायक लोड हो रहा है...';

  @override
  String get categoryAttendanceStudents => 'उपस्थिति और छात्र';

  @override
  String get categoryReportsTracking => 'रिपोर्ट और ट्रैकिंग';

  @override
  String get categoryAnalyticsInsights => 'विश्लेषण और अंतर्दृष्टि';

  @override
  String get categoryToolsManagement => 'उपकरण और प्रबंधन';

  @override
  String get optionAddStudent => 'नया छात्र जोड़ें';

  @override
  String get optionTakeAttendance => 'उपस्थिति लें';

  @override
  String get optionViewAttendance => 'उपस्थिति देखें';

  @override
  String get optionManageStudents => 'छात्रों का प्रबंधन करें';

  @override
  String get optionSubmitDailyReport => 'दैनिक रिपोर्ट जमा करें';

  @override
  String get optionSubmitTestReport => 'परीक्षा रिपोर्ट जमा करें';

  @override
  String get optionTrackTopicProgress => 'विषय प्रगति ट्रैक करें';

  @override
  String get optionViewMyReports => 'मेरी रिपोर्ट देखें';

  @override
  String get optionAnalyticsDashboard => 'विश्लेषण डैशबोर्ड';

  @override
  String get optionLearningDistribution => 'शिक्षण वितरण';

  @override
  String get optionMonthlyReports => 'मासिक रिपोर्ट';

  @override
  String get optionScheduleClasses => 'कक्षाओं का समय निर्धारण';

  @override
  String get optionManageEvents => 'कार्यक्रमों का प्रबंधन';

  @override
  String get optionPhotoGallery => 'फोटो गैलरी';

  @override
  String get optionExportData => 'डेटा निर्यात करें';

  @override
  String categoryOptionsFor(String category) {
    return '$category विकल्प:';
  }

  @override
  String get close => 'बंद करें';
}
