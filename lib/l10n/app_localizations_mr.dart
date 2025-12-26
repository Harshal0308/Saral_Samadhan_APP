// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get login => 'लॉग इन करा';

  @override
  String get username => 'वापरकर्ता नाव';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड विसरलात?';

  @override
  String get saralDashboard => 'सरल डॅशबोर्ड';

  @override
  String get welcome => 'स्वागत आहे';

  @override
  String get attendance => 'उपस्थिती';

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
  String get name => 'नाव';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get changePassword => 'पासवर्ड बदला';

  @override
  String get oldPassword => 'जुना पासवर्ड';

  @override
  String get newPassword => 'नवीन पासवर्ड';

  @override
  String get confirmNewPassword => 'नवीन पासवर्डची पुष्टी करा';

  @override
  String get appLanguage => 'अॅप भाषा';

  @override
  String get selectLanguage => 'भाषा निवडा';

  @override
  String get saveDetails => 'तपशील जतन करा';

  @override
  String get resetLocalData => 'स्थानिक डेटा रीसेट करा';

  @override
  String get studentReport => 'विद्यार्थी अहवाल';

  @override
  String get searchStudents => 'विद्यार्थी शोधा';

  @override
  String get filterByClassBatch => 'वर्ग/बॅचनुसार फिल्टर करा';

  @override
  String get deleteStudent => 'विद्यार्थी हटवा';

  @override
  String get areYouSureYouWantToDelete =>
      'तुम्हाला खात्री आहे की तुम्ही हटवू इच्छिता';

  @override
  String get volunteerReports => 'स्वयंसेवक अहवाल';

  @override
  String get reportBy => 'रिपोर्टโดย';

  @override
  String get deleteSelectedReports => ' निवडलेले अहवाल हटवा';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'तुम्हाला खात्री आहे की तुम्ही $count निवडलेले अहवाल हटवू इच्छिता?';
  }

  @override
  String get quickActions => 'जलद क्रिया';

  @override
  String get mediaGallery => 'मीडिया गॅलरी';

  @override
  String get noStudentsFound => 'एकही विद्यार्थी आढळला नाही';

  @override
  String get chatbotTitle => 'सहाय्यक';

  @override
  String get chatbotGreeting =>
      'नमस्कार! मी तुमचा सहाय्यक आहे। आज तुम्हाला काय करायचे आहे?';

  @override
  String get chatbotShowOptions => 'मला दाखवा की मी काय करू शकतो';

  @override
  String get chatbotMainTasks => 'येथे मुख्य कार्ये आहेत जी तुम्ही करू शकता:';

  @override
  String get chatbotChooseCategory => 'एक श्रेणी निवडा:';

  @override
  String get chatbotLoadingAssistant => 'सहाय्यक लोड होत आहे...';

  @override
  String get categoryAttendanceStudents => 'उपस्थिती आणि विद्यार्थी';

  @override
  String get categoryReportsTracking => 'अहवाल आणि ट्रॅकिंग';

  @override
  String get categoryAnalyticsInsights => 'विश्लेषण आणि अंतर्दृष्टी';

  @override
  String get categoryToolsManagement => 'साधने आणि व्यवस्थापन';

  @override
  String get optionAddStudent => 'नवीन विद्यार्थी जोडा';

  @override
  String get optionTakeAttendance => 'उपस्थिती घ्या';

  @override
  String get optionViewAttendance => 'उपस्थिती पहा';

  @override
  String get optionManageStudents => 'विद्यार्थ्यांचे व्यवस्थापन करा';

  @override
  String get optionSubmitDailyReport => 'दैनिक अहवाल सबमिट करा';

  @override
  String get optionSubmitTestReport => 'चाचणी अहवाल सबमिट करा';

  @override
  String get optionTrackTopicProgress => 'विषय प्रगती ट्रॅक करा';

  @override
  String get optionViewMyReports => 'माझे अहवाल पहा';

  @override
  String get optionAnalyticsDashboard => 'विश्लेषण डॅशबोर्ड';

  @override
  String get optionLearningDistribution => 'शिक्षण वितरण';

  @override
  String get optionMonthlyReports => 'मासिक अहवाल';

  @override
  String get optionScheduleClasses => 'वर्गांचे वेळापत्रक';

  @override
  String get optionManageEvents => 'कार्यक्रमांचे व्यवस्थापन';

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
