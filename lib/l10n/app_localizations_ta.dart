// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get login => 'உள்நுழைவு';

  @override
  String get username => 'பயனர் பெயர்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get forgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get saralDashboard => 'சரல் டாஷ்போர்டு';

  @override
  String get welcome => 'வரவேற்கிறோம்';

  @override
  String get attendance => 'வருகை';

  @override
  String get students => 'மாணவர்கள்';

  @override
  String get volunteers => 'தன்னார்வலர்கள்';

  @override
  String get scheduler => 'அட்டவணை';

  @override
  String get events => 'நிகழ்வுகள்';

  @override
  String get exports => 'ஏற்றுமதி';

  @override
  String get accountDetails => 'கணக்கு விவரங்கள்';

  @override
  String get changePhoto => 'புகைப்படம் மாற்றவும்';

  @override
  String get name => 'பெயர்';

  @override
  String get phoneNumber => 'தொலைபேசி எண்';

  @override
  String get changePassword => 'கடவுச்சொல் மாற்றவும்';

  @override
  String get oldPassword => 'பழைய கடவுச்சொல்';

  @override
  String get newPassword => 'புதிய கடவுச்சொல்';

  @override
  String get confirmNewPassword => 'புதிய கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get appLanguage => 'பயன்பாட்டு மொழி';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get saveDetails => 'விவரங்களைச் சேமிக்கவும்';

  @override
  String get resetLocalData => 'உள்ளூர் தரவை மீட்டமைக்கவும்';

  @override
  String get studentReport => 'மாணவர் அறிக்கை';

  @override
  String get searchStudents => 'மாணவர்களைத் தேடவும்';

  @override
  String get filterByClassBatch => 'வகுப்பு/தொகுதி மூலம் வடிகட்டவும்';

  @override
  String get deleteStudent => 'மாணவரை நீக்கவும்';

  @override
  String get areYouSureYouWantToDelete =>
      'நீங்கள் நிச்சயமாக நீக்க விரும்புகிறீர்களா';

  @override
  String get volunteerReports => 'தன்னார்வலர் அறிக்கைகள்';

  @override
  String get reportBy => 'அறிக்கை மூலம்';

  @override
  String get deleteSelectedReports =>
      'தேர்ந்தெடுக்கப்பட்ட அறிக்கைகளை நீக்கவும்';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'நீங்கள் நிச்சயமாக $count தேர்ந்தெடுக்கப்பட்ட அறிக்கைகளை நீக்க விரும்புகிறீர்களா?';
  }

  @override
  String get quickActions => 'விரைவு செயல்கள்';

  @override
  String get mediaGallery => 'ஊடக காட்சியகம்';

  @override
  String get noStudentsFound => 'மாணவர்கள் யாரும் கிடைக்கவில்லை';

  @override
  String get chatbotTitle => 'SAATHI';

  @override
  String get chatbotGreeting =>
      'வணக்கம்! நான் உங்கள் உதவியாளர். இன்று நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?';

  @override
  String get chatbotShowOptions =>
      'நான் என்ன செய்ய முடியும் என்பதைக் காட்டுங்கள்';

  @override
  String get chatbotMainTasks =>
      'நீங்கள் செய்யக்கூடிய முக்கிய பணிகள் இங்கே உள்ளன:';

  @override
  String get chatbotChooseCategory => 'ஒரு வகையைத் தேர்ந்தெடுக்கவும்:';

  @override
  String get chatbotLoadingAssistant => 'உதவியாளர் ஏற்றப்படுகிறது...';

  @override
  String get categoryAttendanceStudents => 'வருகை மற்றும் மாணவர்கள்';

  @override
  String get categoryReportsTracking => 'அறிக்கைகள் மற்றும் கண்காணிப்பு';

  @override
  String get categoryAnalyticsInsights => 'பகுப்பாய்வு மற்றும் நுண்ணறிவு';

  @override
  String get categoryToolsManagement => 'கருவிகள் மற்றும் நிர்வாகம்';

  @override
  String get optionAddStudent => 'புதிய மாணவரைச் சேர்க்கவும்';

  @override
  String get optionTakeAttendance => 'வருகையை எடுக்கவும்';

  @override
  String get optionViewAttendance => 'வருகையைப் பார்க்கவும்';

  @override
  String get optionManageStudents => 'மாணவர்களை நிர்வகிக்கவும்';

  @override
  String get optionSubmitDailyReport => 'தினசரி அறிக்கையைச் சமர்பிக்கவும்';

  @override
  String get optionSubmitTestReport => 'சோதனை அறிக்கையைச் சமர்பிக்கவும்';

  @override
  String get optionTrackTopicProgress =>
      'தலைப்பு முன்னேற்றத்தைக் கண்காணிக்கவும்';

  @override
  String get optionViewMyReports => 'எனது அறிக்கைகளைப் பார்க்கவும்';

  @override
  String get optionAnalyticsDashboard => 'பகுப்பாய்வு டாஷ்போர்டு';

  @override
  String get optionLearningDistribution => 'கற்றல் விநியோகம்';

  @override
  String get optionMonthlyReports => 'மாதாந்திர அறிக்கைகள்';

  @override
  String get optionScheduleClasses => 'வகுப்புகளின் அட்டவணை';

  @override
  String get optionManageEvents => 'நிகழ்வுகளின் நிர்வாகம்';

  @override
  String get optionPhotoGallery => 'புகைப்பட காட்சியகம்';

  @override
  String get optionExportData => 'தரவை ஏற்றுமதி செய்யவும்';

  @override
  String categoryOptionsFor(String category) {
    return '$category விருப்பங்கள்:';
  }

  @override
  String get close => 'மூடு';
}
