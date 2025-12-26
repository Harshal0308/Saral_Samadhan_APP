// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kashmiri (`ks`).
class AppLocalizationsKs extends AppLocalizations {
  AppLocalizationsKs([String locale = 'ks']) : super(locale);

  @override
  String get login => 'لاگ ان';

  @override
  String get username => 'صارف کا نام';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get forgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get saralDashboard => 'سرل ڈیش بورڈ';

  @override
  String get welcome => 'خوش آمدید';

  @override
  String get attendance => 'حاضری';

  @override
  String get students => 'طلباء';

  @override
  String get volunteers => 'رضاکار';

  @override
  String get scheduler => 'وقت کی فہرست';

  @override
  String get events => 'تقریبات';

  @override
  String get exports => 'برآمد';

  @override
  String get accountDetails => 'اکاؤنٹ کی تفصیلات';

  @override
  String get changePhoto => 'تصویر تبدیل کریں';

  @override
  String get name => 'نام';

  @override
  String get phoneNumber => 'فون نمبر';

  @override
  String get changePassword => 'پاس ورڈ تبدیل کریں';

  @override
  String get oldPassword => 'پرانا پاس ورڈ';

  @override
  String get newPassword => 'نیا پاس ورڈ';

  @override
  String get confirmNewPassword => 'نئے پاس ورڈ کی تصدیق کریں';

  @override
  String get appLanguage => 'ایپ کی زبان';

  @override
  String get selectLanguage => 'زبان منتخب کریں';

  @override
  String get saveDetails => 'تفصیلات محفوظ کریں';

  @override
  String get resetLocalData => 'مقامی ڈیٹا ری سیٹ کریں';

  @override
  String get studentReport => 'طالب علم کی رپورٹ';

  @override
  String get searchStudents => 'طلباء تلاش کریں';

  @override
  String get filterByClassBatch => 'کلاس/بیچ کے ذریعے فلٹر کریں';

  @override
  String get deleteStudent => 'طالب علم کو حذف کریں';

  @override
  String get areYouSureYouWantToDelete => 'کیا آپ واقعی حذف کرنا چاہتے ہیں';

  @override
  String get volunteerReports => 'رضاکار کی رپورٹس';

  @override
  String get reportBy => 'رپورٹ بذریعہ';

  @override
  String get deleteSelectedReports => 'منتخب شدہ رپورٹس حذف کریں';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'کیا آپ واقعی $count منتخب شدہ رپورٹس حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get quickActions => 'فوری اقدامات';

  @override
  String get mediaGallery => 'میڈیا گیلری';

  @override
  String get noStudentsFound => 'کوئی طلباء نہیں ملے';

  @override
  String get chatbotTitle => 'معاون';

  @override
  String get chatbotGreeting =>
      'سلام علیکم! میں آپ کا معاون ہوں۔ آج آپ کیا کرنا چاہتے ہیں؟';

  @override
  String get chatbotShowOptions => 'مجھے دکھائیں کہ میں کیا کر سکتا ہوں';

  @override
  String get chatbotMainTasks => 'یہاں اہم کام ہیں جو آپ کر سکتے ہیں:';

  @override
  String get chatbotChooseCategory => 'ایک کیٹگری منتخب کریں:';

  @override
  String get chatbotLoadingAssistant => 'معاون لوڈ ہو رہا ہے...';

  @override
  String get categoryAttendanceStudents => 'حاضری اور طلباء';

  @override
  String get categoryReportsTracking => 'رپورٹس اور ٹریکنگ';

  @override
  String get categoryAnalyticsInsights => 'تجزیات اور بصیرت';

  @override
  String get categoryToolsManagement => 'ٹولز اور انتظام';

  @override
  String get optionAddStudent => 'نیا طالب علم شامل کریں';

  @override
  String get optionTakeAttendance => 'حاضری لیں';

  @override
  String get optionViewAttendance => 'حاضری دیکھیں';

  @override
  String get optionManageStudents => 'طلباء کا انتظام کریں';

  @override
  String get optionSubmitDailyReport => 'روزانہ کی رپورٹ جمع کریں';

  @override
  String get optionSubmitTestReport => 'ٹیسٹ کی رپورٹ جمع کریں';

  @override
  String get optionTrackTopicProgress => 'موضوع کی پیش قدمی ٹریک کریں';

  @override
  String get optionViewMyReports => 'میری رپورٹس دیکھیں';

  @override
  String get optionAnalyticsDashboard => 'تجزیاتی ڈیش بورڈ';

  @override
  String get optionLearningDistribution => 'تعلیمی تقسیم';

  @override
  String get optionMonthlyReports => 'ماہانہ رپورٹس';

  @override
  String get optionScheduleClasses => 'کلاسوں کا شیڈول';

  @override
  String get optionManageEvents => 'تقریبات کا انتظام';

  @override
  String get optionPhotoGallery => 'فوٹو گیلری';

  @override
  String get optionExportData => 'ڈیٹا ایکسپورٹ کریں';

  @override
  String categoryOptionsFor(String category) {
    return '$category کے اختیارات:';
  }

  @override
  String get close => 'بند کریں';
}
