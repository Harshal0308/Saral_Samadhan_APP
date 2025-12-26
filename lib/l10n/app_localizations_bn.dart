// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get login => 'লগ ইন';

  @override
  String get username => 'ব্যবহারকারীর নাম';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get saralDashboard => 'সরল ড্যাশবোর্ড';

  @override
  String get welcome => 'স্বাগতম';

  @override
  String get attendance => 'উপস্থিতি';

  @override
  String get students => 'শিক্ষার্থী';

  @override
  String get volunteers => 'স্বেচ্ছাসেবক';

  @override
  String get scheduler => 'সময়সূচী';

  @override
  String get events => 'অনুষ্ঠান';

  @override
  String get exports => 'রপ্তানি';

  @override
  String get accountDetails => 'অ্যাকাউন্টের বিবরণ';

  @override
  String get changePhoto => 'ছবি পরিবর্তন করুন';

  @override
  String get name => 'নাম';

  @override
  String get phoneNumber => 'ফোন নম্বর';

  @override
  String get changePassword => 'পাসওয়ার্ড পরিবর্তন করুন';

  @override
  String get oldPassword => 'পুরানো পাসওয়ার্ড';

  @override
  String get newPassword => 'নতুন পাসওয়ার্ড';

  @override
  String get confirmNewPassword => 'নতুন পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get appLanguage => 'অ্যাপের ভাষা';

  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get saveDetails => 'বিবরণ সংরক্ষণ করুন';

  @override
  String get resetLocalData => 'স্থানীয় ডেটা রিসেট করুন';

  @override
  String get studentReport => 'শিক্ষার্থীর প্রতিবেদন';

  @override
  String get searchStudents => 'শিক্ষার্থী খুঁজুন';

  @override
  String get filterByClassBatch => 'শ্রেণী/ব্যাচ অনুযায়ী ফিল্টার করুন';

  @override
  String get deleteStudent => 'শিক্ষার্থী মুছুন';

  @override
  String get areYouSureYouWantToDelete => 'আপনি কি নিশ্চিত যে আপনি মুছতে চান';

  @override
  String get volunteerReports => 'স্বেচ্ছাসেবকের প্রতিবেদন';

  @override
  String get reportBy => 'প্রতিবেদনকারী';

  @override
  String get deleteSelectedReports => 'নির্বাচিত প্রতিবেদন মুছুন';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'আপনি কি নিশ্চিত যে আপনি $countটি নির্বাচিত প্রতিবেদন মুছতে চান?';
  }

  @override
  String get quickActions => 'দ্রুত কার্য';

  @override
  String get mediaGallery => 'মিডিয়া গ্যালারি';

  @override
  String get noStudentsFound => 'কোনো শিক্ষার্থী পাওয়া যায়নি';

  @override
  String get chatbotTitle => 'সহায়ক';

  @override
  String get chatbotGreeting =>
      'হ্যালো! আমি আপনার সহায়ক। আজ আপনি কী করতে চান?';

  @override
  String get chatbotShowOptions => 'আমাকে দেখান আমি কী করতে পারি';

  @override
  String get chatbotMainTasks =>
      'এখানে প্রধান কাজগুলি রয়েছে যা আপনি করতে পারেন:';

  @override
  String get chatbotChooseCategory => 'একটি বিভাগ বেছে নিন:';

  @override
  String get chatbotLoadingAssistant => 'সহায়ক লোড হচ্ছে...';

  @override
  String get categoryAttendanceStudents => 'উপস্থিতি ও শিক্ষার্থী';

  @override
  String get categoryReportsTracking => 'প্রতিবেদন ও ট্র্যাকিং';

  @override
  String get categoryAnalyticsInsights => 'বিশ্লেষণ ও অন্তর্দৃষ্টি';

  @override
  String get categoryToolsManagement => 'সরঞ্জাম ও ব্যবস্থাপনা';

  @override
  String get optionAddStudent => 'নতুন শিক্ষার্থী যোগ করুন';

  @override
  String get optionTakeAttendance => 'উপস্থিতি নিন';

  @override
  String get optionViewAttendance => 'উপস্থিতি দেখুন';

  @override
  String get optionManageStudents => 'শিক্ষার্থী ব্যবস্থাপনা করুন';

  @override
  String get optionSubmitDailyReport => 'দৈনিক প্রতিবেদন জমা দিন';

  @override
  String get optionSubmitTestReport => 'পরীক্ষার প্রতিবেদন জমা দিন';

  @override
  String get optionTrackTopicProgress => 'বিষয়ের অগ্রগতি ট্র্যাক করুন';

  @override
  String get optionViewMyReports => 'আমার প্রতিবেদন দেখুন';

  @override
  String get optionAnalyticsDashboard => 'বিশ্লেষণ ড্যাশবোর্ড';

  @override
  String get optionLearningDistribution => 'শিক্ষণ বিতরণ';

  @override
  String get optionMonthlyReports => 'মাসিক প্রতিবেদন';

  @override
  String get optionScheduleClasses => 'ক্লাসের সময়সূচী';

  @override
  String get optionManageEvents => 'অনুষ্ঠান ব্যবস্থাপনা';

  @override
  String get optionPhotoGallery => 'ছবির গ্যালারি';

  @override
  String get optionExportData => 'ডেটা রপ্তানি করুন';

  @override
  String categoryOptionsFor(String category) {
    return '$category বিকল্পসমূহ:';
  }

  @override
  String get close => 'বন্ধ';
}
