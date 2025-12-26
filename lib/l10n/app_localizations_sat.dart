// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Santali (`sat`).
class AppLocalizationsSat extends AppLocalizations {
  AppLocalizationsSat([String locale = 'sat']) : super(locale);

  @override
  String get login => 'लगिन';

  @override
  String get username => 'बेबहारिच नुतुम';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड हिलाङ केदा?';

  @override
  String get saralDashboard => 'सरल डैशबोर्ड';

  @override
  String get welcome => 'जोहार';

  @override
  String get attendance => 'हाजिर';

  @override
  String get students => 'छात्र को';

  @override
  String get volunteers => 'स्वयंसेवक को';

  @override
  String get scheduler => 'समाय सुची';

  @override
  String get events => 'कामी को';

  @override
  String get exports => 'बाहरे कुलाक';

  @override
  String get accountDetails => 'खाता बिबरन';

  @override
  String get changePhoto => 'फोटो बदलाव';

  @override
  String get name => 'नुतुम';

  @override
  String get phoneNumber => 'फोन नम्बर';

  @override
  String get changePassword => 'पासवर्ड बदलाव';

  @override
  String get oldPassword => 'पुरान पासवर्ड';

  @override
  String get newPassword => 'नावा पासवर्ड';

  @override
  String get confirmNewPassword => 'नावा पासवर्ड पक्का';

  @override
  String get appLanguage => 'एप पारसी';

  @override
  String get selectLanguage => 'पारसी बाछाव';

  @override
  String get saveDetails => 'बिबरन राखाव';

  @override
  String get resetLocalData => 'थानीय डाटा रिसेट';

  @override
  String get studentReport => 'छात्र रिपोर्ट';

  @override
  String get searchStudents => 'छात्र को सोधाव';

  @override
  String get filterByClassBatch => 'कक्षा/बैच लेका फिल्टर';

  @override
  String get deleteStudent => 'छात्र मेटाव';

  @override
  String get areYouSureYouWantToDelete => 'चिका आम मेटाव सानाम काना';

  @override
  String get volunteerReports => 'स्वयंसेवक रिपोर्ट को';

  @override
  String get reportBy => 'रिपोर्ट लेका';

  @override
  String get deleteSelectedReports => 'बाछाव रिपोर्ट को मेटाव';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'चिका आम $count बाछाव रिपोर्ट को मेटाव सानाम काना?';
  }

  @override
  String get quickActions => 'झटपट कामी';

  @override
  String get mediaGallery => 'मीडिया गैलरी';

  @override
  String get noStudentsFound => 'जाहान छात्र बान नामकेदा';

  @override
  String get chatbotTitle => 'गिदरा';

  @override
  String get chatbotGreeting =>
      'जोहार! आइङ आम रेन गिदरा कान। तेहेन आम चेत कामी सानाम काना?';

  @override
  String get chatbotShowOptions => 'आइङ चेत कामी दाड़ेयाक आ से उदुक मे';

  @override
  String get chatbotMainTasks =>
      'नोआ मुख्य कामी को मेनाक आ जाहान को आम दाड़ेयाक आ:';

  @override
  String get chatbotChooseCategory => 'मित टाक बिभाग बाछाव:';

  @override
  String get chatbotLoadingAssistant => 'गिदरा लोड होवाक आ...';

  @override
  String get categoryAttendanceStudents => 'हाजिर आर छात्र को';

  @override
  String get categoryReportsTracking => 'रिपोर्ट आर ट्रैकिङ';

  @override
  String get categoryAnalyticsInsights => 'बिस्लेसन आर भितरी नेल';

  @override
  String get categoryToolsManagement => 'हातियार आर बेबस्था';

  @override
  String get optionAddStudent => 'नावा छात्र जोड़ाव';

  @override
  String get optionTakeAttendance => 'हाजिर नाम';

  @override
  String get optionViewAttendance => 'हाजिर नेल';

  @override
  String get optionManageStudents => 'छात्र को बेबस्था';

  @override
  String get optionSubmitDailyReport => 'दिना रिपोर्ट जमा';

  @override
  String get optionSubmitTestReport => 'परिक्खा रिपोर्ट जमा';

  @override
  String get optionTrackTopicProgress => 'बिसाय आगे बाढ़ाव ट्रैक';

  @override
  String get optionViewMyReports => 'आइङ रेन रिपोर्ट को नेल';

  @override
  String get optionAnalyticsDashboard => 'बिस्लेसन डैशबोर्ड';

  @override
  String get optionLearningDistribution => 'सिकाव बाटवार';

  @override
  String get optionMonthlyReports => 'मासिक रिपोर्ट को';

  @override
  String get optionScheduleClasses => 'कक्षा को समाय सुची';

  @override
  String get optionManageEvents => 'कामी को बेबस्था';

  @override
  String get optionPhotoGallery => 'फोटो गैलरी';

  @override
  String get optionExportData => 'डाटा बाहरे कुल';

  @override
  String categoryOptionsFor(String category) {
    return '$category बाछनाव को:';
  }

  @override
  String get close => 'बंद';
}
