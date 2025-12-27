// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Konkani (`kok`).
class AppLocalizationsKok extends AppLocalizations {
  AppLocalizationsKok([String locale = 'kok']) : super(locale);

  @override
  String get login => 'लॉगिन';

  @override
  String get username => 'वापरप्याचें नांव';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड विसरलात?';

  @override
  String get saralDashboard => 'सरळ डॅशबोर्ड';

  @override
  String get welcome => 'स्वागत';

  @override
  String get attendance => 'हजेरी';

  @override
  String get students => 'विद्यार्थी';

  @override
  String get volunteers => 'स्वयंसेवक';

  @override
  String get scheduler => 'वेळापत्रक';

  @override
  String get events => 'कार्यक्रम';

  @override
  String get exports => 'निर्यात';

  @override
  String get accountDetails => 'खाते तपशील';

  @override
  String get changePhoto => 'फोटो बदला';

  @override
  String get name => 'नांव';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get changePassword => 'पासवर्ड बदला';

  @override
  String get oldPassword => 'जुनो पासवर्ड';

  @override
  String get newPassword => 'नवो पासवर्ड';

  @override
  String get confirmNewPassword => 'नव्या पासवर्डाची खात्री करा';

  @override
  String get appLanguage => 'अॅप भास';

  @override
  String get selectLanguage => 'भास निवडा';

  @override
  String get saveDetails => 'तपशील जतन करा';

  @override
  String get resetLocalData => 'स्थानिक डेटा रीसेट करा';

  @override
  String get studentReport => 'विद्यार्थी अहवाल';

  @override
  String get searchStudents => 'विद्यार्थी सोदा';

  @override
  String get filterByClassBatch => 'वर्ग/बॅच प्रमाण फिल्टर करा';

  @override
  String get deleteStudent => 'विद्यार्थी काडा';

  @override
  String get areYouSureYouWantToDelete => 'तुमी खरेंच काडूंक सोदता';

  @override
  String get volunteerReports => 'स्वयंसेवक अहवाल';

  @override
  String get reportBy => 'अहवाल';

  @override
  String get deleteSelectedReports => 'निवडिल्ले अहवाल काडा';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'तुमी खरेंच $count निवडिल्ले अहवाल काडूंक सोदता?';
  }

  @override
  String get quickActions => 'बेगीन कार्य';

  @override
  String get mediaGallery => 'मीडिया गॅलरी';

  @override
  String get noStudentsFound => 'कसलेच विद्यार्थी मेळ्ळे ना';

  @override
  String get chatbotTitle => 'SAATHI';

  @override
  String get chatbotGreeting =>
      'नमस्कार! हांव तुमचो आदारकार. आयज तुमी कितें करूंक सोदता?';

  @override
  String get chatbotShowOptions => 'म्हाका दाखया कि हांव कितें करूं येतां';

  @override
  String get chatbotMainTasks => 'हांगा मुख्य कामां आसात जीं तुमी करूं येतात:';

  @override
  String get chatbotChooseCategory => 'एक वर्ग निवडा:';

  @override
  String get chatbotLoadingAssistant => 'आदारकार लोड जाता...';

  @override
  String get categoryAttendanceStudents => 'हजेरी आनी विद्यार्थी';

  @override
  String get categoryReportsTracking => 'अहवाल आनी ट्रॅकिंग';

  @override
  String get categoryAnalyticsInsights => 'विश्लेषण आनी अंतर्दृष्टी';

  @override
  String get categoryToolsManagement => 'साधनां आनी व्यवस्थापन';

  @override
  String get optionAddStudent => 'नवो विद्यार्थी घाला';

  @override
  String get optionTakeAttendance => 'हजेरी घे';

  @override
  String get optionViewAttendance => 'हजेरी पळे';

  @override
  String get optionManageStudents => 'विद्यार्थ्यांचें व्यवस्थापन';

  @override
  String get optionSubmitDailyReport => 'दिसाळो अहवाल दिया';

  @override
  String get optionSubmitTestReport => 'चाचणी अहवाल दिया';

  @override
  String get optionTrackTopicProgress => 'विषयाची प्रगती ट्रॅक करा';

  @override
  String get optionViewMyReports => 'म्हजे अहवाल पळे';

  @override
  String get optionAnalyticsDashboard => 'विश्लेषण डॅशबोर्ड';

  @override
  String get optionLearningDistribution => 'शिकपाचें वांटप';

  @override
  String get optionMonthlyReports => 'म्हयन्याळे अहवाल';

  @override
  String get optionScheduleClasses => 'वर्गांचें वेळापत्रक';

  @override
  String get optionManageEvents => 'कार्यक्रमांचें व्यवस्थापन';

  @override
  String get optionPhotoGallery => 'फोटो गॅलरी';

  @override
  String get optionExportData => 'डेटा निर्यात करा';

  @override
  String categoryOptionsFor(String category) {
    return '$category पर्याय:';
  }

  @override
  String get close => 'बंद करा';
}
