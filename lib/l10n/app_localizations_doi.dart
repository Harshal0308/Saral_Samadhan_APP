// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dogri (`doi`).
class AppLocalizationsDoi extends AppLocalizations {
  AppLocalizationsDoi([String locale = 'doi']) : super(locale);

  @override
  String get login => 'लॉगिन';

  @override
  String get username => 'बरतोंकार दा नां';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड भुल्ल गेआ?';

  @override
  String get saralDashboard => 'सरल डैशबोर्ड';

  @override
  String get welcome => 'स्वागत';

  @override
  String get attendance => 'हाजरी';

  @override
  String get students => 'विद्यार्थी';

  @override
  String get volunteers => 'स्वयंसेवक';

  @override
  String get scheduler => 'समें सूची';

  @override
  String get events => 'कार्यक्रम';

  @override
  String get exports => 'निर्यात';

  @override
  String get accountDetails => 'खाता विवरण';

  @override
  String get changePhoto => 'फोटो बदलो';

  @override
  String get name => 'नां';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get changePassword => 'पासवर्ड बदलो';

  @override
  String get oldPassword => 'पुराना पासवर्ड';

  @override
  String get newPassword => 'नवां पासवर्ड';

  @override
  String get confirmNewPassword => 'नवें पासवर्ड दी पुष्टि करो';

  @override
  String get appLanguage => 'ऐप दी भाषा';

  @override
  String get selectLanguage => 'भाषा चुनो';

  @override
  String get saveDetails => 'विवरण सेव करो';

  @override
  String get resetLocalData => 'स्थानीय डेटा रीसेट करो';

  @override
  String get studentReport => 'विद्यार्थी रिपोर्ट';

  @override
  String get searchStudents => 'विद्यार्थी तोपो';

  @override
  String get filterByClassBatch => 'कक्षा/बैच कन्नै फिल्टर करो';

  @override
  String get deleteStudent => 'विद्यार्थी मिटाओ';

  @override
  String get areYouSureYouWantToDelete => 'क्या तुसें पक्का मिटाना चांदे';

  @override
  String get volunteerReports => 'स्वयंसेवक रिपोर्ट';

  @override
  String get reportBy => 'रिपोर्ट कन्नै';

  @override
  String get deleteSelectedReports => 'चुनी दी रिपोर्ट मिटाओ';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'क्या तुसें पक्का $count चुनी दी रिपोर्ट मिटाना चांदे?';
  }

  @override
  String get quickActions => 'झट्ट कार्रवाई';

  @override
  String get mediaGallery => 'मीडिया गैलरी';

  @override
  String get noStudentsFound => 'कोई विद्यार्थी नेईं मिल्ला';

  @override
  String get chatbotTitle => 'SAATHI';

  @override
  String get chatbotGreeting =>
      'नमस्कार! मैं तुंदा सहायक आं। अज्ज तुसें क्या करना चांदे?';

  @override
  String get chatbotShowOptions => 'मिगी दस्सो कि मैं क्या करी सकदा';

  @override
  String get chatbotMainTasks => 'एह मुख्य कम्म न जेह्ड़े तुसें करी सकदे:';

  @override
  String get chatbotChooseCategory => 'इक श्रेणी चुनो:';

  @override
  String get chatbotLoadingAssistant => 'सहायक लोड होआ दा...';

  @override
  String get categoryAttendanceStudents => 'हाजरी ते विद्यार्थी';

  @override
  String get categoryReportsTracking => 'रिपोर्ट ते ट्रैकिंग';

  @override
  String get categoryAnalyticsInsights => 'विश्लेषण ते अंतर्दृष्टि';

  @override
  String get categoryToolsManagement => 'औजार ते प्रबंधन';

  @override
  String get optionAddStudent => 'नवां विद्यार्थी जोड़ो';

  @override
  String get optionTakeAttendance => 'हाजरी लैओ';

  @override
  String get optionViewAttendance => 'हाजरी दिक्खो';

  @override
  String get optionManageStudents => 'विद्यार्थी प्रबंधन';

  @override
  String get optionSubmitDailyReport => 'रोजाना रिपोर्ट जमा करो';

  @override
  String get optionSubmitTestReport => 'टेस्ट रिपोर्ट जमा करो';

  @override
  String get optionTrackTopicProgress => 'विषय प्रगति ट्रैक करो';

  @override
  String get optionViewMyReports => 'मेरी रिपोर्ट दिक्खो';

  @override
  String get optionAnalyticsDashboard => 'विश्लेषण डैशबोर्ड';

  @override
  String get optionLearningDistribution => 'सिखने दा वितरण';

  @override
  String get optionMonthlyReports => 'मासिक रिपोर्ट';

  @override
  String get optionScheduleClasses => 'कक्षा समें सूची';

  @override
  String get optionManageEvents => 'कार्यक्रम प्रबंधन';

  @override
  String get optionPhotoGallery => 'फोटो गैलरी';

  @override
  String get optionExportData => 'डेटा निर्यात करो';

  @override
  String categoryOptionsFor(String category) {
    return '$category विकल्प:';
  }

  @override
  String get close => 'बंद करो';
}
