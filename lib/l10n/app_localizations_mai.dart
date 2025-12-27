// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Maithili (`mai`).
class AppLocalizationsMai extends AppLocalizations {
  AppLocalizationsMai([String locale = 'mai']) : super(locale);

  @override
  String get login => 'लॉगिन';

  @override
  String get username => 'प्रयोगकर्ताक नाम';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड बिसरि गेल?';

  @override
  String get saralDashboard => 'सरल डैशबोर्ड';

  @override
  String get welcome => 'स्वागत';

  @override
  String get attendance => 'उपस्थिति';

  @override
  String get students => 'छात्र';

  @override
  String get volunteers => 'स्वयंसेवक';

  @override
  String get scheduler => 'समयसूची';

  @override
  String get events => 'कार्यक्रम';

  @override
  String get exports => 'निर्यात';

  @override
  String get accountDetails => 'खाता विवरण';

  @override
  String get changePhoto => 'फोटो बदलू';

  @override
  String get name => 'नाम';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get changePassword => 'पासवर्ड बदलू';

  @override
  String get oldPassword => 'पुरान पासवर्ड';

  @override
  String get newPassword => 'नव पासवर्ड';

  @override
  String get confirmNewPassword => 'नव पासवर्डक पुष्टि करू';

  @override
  String get appLanguage => 'एप्पक भाषा';

  @override
  String get selectLanguage => 'भाषा चुनू';

  @override
  String get saveDetails => 'विवरण सहेजू';

  @override
  String get resetLocalData => 'स्थानीय डेटा रीसेट करू';

  @override
  String get studentReport => 'छात्र रिपोर्ट';

  @override
  String get searchStudents => 'छात्र खोजू';

  @override
  String get filterByClassBatch => 'कक्षा/बैच सँ फिल्टर करू';

  @override
  String get deleteStudent => 'छात्रकेँ मेटाबू';

  @override
  String get areYouSureYouWantToDelete => 'की अहाँ पक्का मेटाबय चाहैत छी';

  @override
  String get volunteerReports => 'स्वयंसेवक रिपोर्ट';

  @override
  String get reportBy => 'रिपोर्ट द्वारा';

  @override
  String get deleteSelectedReports => 'चुनल रिपोर्ट मेटाबू';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'की अहाँ पक्का $count चुनल रिपोर्ट मेटाबय चाहैत छी?';
  }

  @override
  String get quickActions => 'तुरंत कार्य';

  @override
  String get mediaGallery => 'मीडिया गैलरी';

  @override
  String get noStudentsFound => 'कोनो छात्र नहि भेटल';

  @override
  String get chatbotTitle => 'SAATHI';

  @override
  String get chatbotGreeting =>
      'नमस्कार! हम अहाँक सहायक छी। आइ अहाँ की करय चाहैत छी?';

  @override
  String get chatbotShowOptions => 'हमरा देखाबू जे हम की करि सकैत छी';

  @override
  String get chatbotMainTasks => 'एतय मुख्य काज अछि जे अहाँ करि सकैत छी:';

  @override
  String get chatbotChooseCategory => 'एकटा श्रेणी चुनू:';

  @override
  String get chatbotLoadingAssistant => 'सहायक लोड भ रहल अछि...';

  @override
  String get categoryAttendanceStudents => 'उपस्थिति आ छात्र';

  @override
  String get categoryReportsTracking => 'रिपोर्ट आ ट्रैकिंग';

  @override
  String get categoryAnalyticsInsights => 'विश्लेषण आ अंतर्दृष्टि';

  @override
  String get categoryToolsManagement => 'औजार आ प्रबंधन';

  @override
  String get optionAddStudent => 'नव छात्र जोड़ू';

  @override
  String get optionTakeAttendance => 'उपस्थिति लिअ';

  @override
  String get optionViewAttendance => 'उपस्थिति देखू';

  @override
  String get optionManageStudents => 'छात्रक प्रबंधन करू';

  @override
  String get optionSubmitDailyReport => 'दैनिक रिपोर्ट जमा करू';

  @override
  String get optionSubmitTestReport => 'परीक्षा रिपोर्ट जमा करू';

  @override
  String get optionTrackTopicProgress => 'विषयक प्रगति ट्रैक करू';

  @override
  String get optionViewMyReports => 'हमर रिपोर्ट देखू';

  @override
  String get optionAnalyticsDashboard => 'विश्लेषण डैशबोर्ड';

  @override
  String get optionLearningDistribution => 'सिखनाइक वितरण';

  @override
  String get optionMonthlyReports => 'मासिक रिपोर्ट';

  @override
  String get optionScheduleClasses => 'कक्षाक समयसूची';

  @override
  String get optionManageEvents => 'कार्यक्रमक प्रबंधन';

  @override
  String get optionPhotoGallery => 'फोटो गैलरी';

  @override
  String get optionExportData => 'डेटा निर्यात करू';

  @override
  String categoryOptionsFor(String category) {
    return '$category विकल्प:';
  }

  @override
  String get close => 'बंद करू';
}
