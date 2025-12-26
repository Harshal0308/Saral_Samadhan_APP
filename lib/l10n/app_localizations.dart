import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_brx.dart';
import 'app_localizations_doi.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_kok.dart';
import 'app_localizations_ks.dart';
import 'app_localizations_mai.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_sa.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_sd.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('as'),
    Locale('bn'),
    Locale('brx'),
    Locale('doi'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('kok'),
    Locale('ks'),
    Locale('mai'),
    Locale('ml'),
    Locale('mni'),
    Locale('mr'),
    Locale('ne'),
    Locale('or'),
    Locale('pa'),
    Locale('sa'),
    Locale('sat'),
    Locale('sd'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @saralDashboard.
  ///
  /// In en, this message translates to:
  /// **'SARAL Dashboard'**
  String get saralDashboard;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @volunteers.
  ///
  /// In en, this message translates to:
  /// **'Volunteers'**
  String get volunteers;

  /// No description provided for @scheduler.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get scheduler;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @exports.
  ///
  /// In en, this message translates to:
  /// **'Exports'**
  String get exports;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @saveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get saveDetails;

  /// No description provided for @resetLocalData.
  ///
  /// In en, this message translates to:
  /// **'Reset Local Data'**
  String get resetLocalData;

  /// No description provided for @studentReport.
  ///
  /// In en, this message translates to:
  /// **'Student Report'**
  String get studentReport;

  /// No description provided for @searchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search Students'**
  String get searchStudents;

  /// No description provided for @filterByClassBatch.
  ///
  /// In en, this message translates to:
  /// **'Filter by Class/Batch'**
  String get filterByClassBatch;

  /// No description provided for @deleteStudent.
  ///
  /// In en, this message translates to:
  /// **'Delete Student'**
  String get deleteStudent;

  /// No description provided for @areYouSureYouWantToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureYouWantToDelete;

  /// No description provided for @volunteerReports.
  ///
  /// In en, this message translates to:
  /// **'Volunteer Reports'**
  String get volunteerReports;

  /// No description provided for @reportBy.
  ///
  /// In en, this message translates to:
  /// **'Report by'**
  String get reportBy;

  /// No description provided for @deleteSelectedReports.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Reports'**
  String get deleteSelectedReports;

  /// No description provided for @areYouSureYouWantToDeleteNReports.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected report(s)?'**
  String areYouSureYouWantToDeleteNReports(int count);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @mediaGallery.
  ///
  /// In en, this message translates to:
  /// **'Media Gallery'**
  String get mediaGallery;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No Students Found'**
  String get noStudentsFound;

  /// No description provided for @chatbotTitle.
  ///
  /// In en, this message translates to:
  /// **'SAATHI'**
  String get chatbotTitle;

  /// No description provided for @chatbotGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m your assistant. What would you like to do today?'**
  String get chatbotGreeting;

  /// No description provided for @chatbotShowOptions.
  ///
  /// In en, this message translates to:
  /// **'Show me what I can do'**
  String get chatbotShowOptions;

  /// No description provided for @chatbotMainTasks.
  ///
  /// In en, this message translates to:
  /// **'Here are the main tasks you can perform:'**
  String get chatbotMainTasks;

  /// No description provided for @chatbotChooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category:'**
  String get chatbotChooseCategory;

  /// No description provided for @chatbotLoadingAssistant.
  ///
  /// In en, this message translates to:
  /// **'Loading assistant...'**
  String get chatbotLoadingAssistant;

  /// No description provided for @categoryAttendanceStudents.
  ///
  /// In en, this message translates to:
  /// **'Attendance & Students'**
  String get categoryAttendanceStudents;

  /// No description provided for @categoryReportsTracking.
  ///
  /// In en, this message translates to:
  /// **'Reports & Tracking'**
  String get categoryReportsTracking;

  /// No description provided for @categoryAnalyticsInsights.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Insights'**
  String get categoryAnalyticsInsights;

  /// No description provided for @categoryToolsManagement.
  ///
  /// In en, this message translates to:
  /// **'Tools & Management'**
  String get categoryToolsManagement;

  /// No description provided for @optionAddStudent.
  ///
  /// In en, this message translates to:
  /// **'Add New Student'**
  String get optionAddStudent;

  /// No description provided for @optionTakeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Take Attendance'**
  String get optionTakeAttendance;

  /// No description provided for @optionViewAttendance.
  ///
  /// In en, this message translates to:
  /// **'View Attendance'**
  String get optionViewAttendance;

  /// No description provided for @optionManageStudents.
  ///
  /// In en, this message translates to:
  /// **'Manage Students'**
  String get optionManageStudents;

  /// No description provided for @optionSubmitDailyReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Daily Report'**
  String get optionSubmitDailyReport;

  /// No description provided for @optionSubmitTestReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Test Report'**
  String get optionSubmitTestReport;

  /// No description provided for @optionTrackTopicProgress.
  ///
  /// In en, this message translates to:
  /// **'Track Topic Progress'**
  String get optionTrackTopicProgress;

  /// No description provided for @optionViewMyReports.
  ///
  /// In en, this message translates to:
  /// **'View My Reports'**
  String get optionViewMyReports;

  /// No description provided for @optionAnalyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get optionAnalyticsDashboard;

  /// No description provided for @optionLearningDistribution.
  ///
  /// In en, this message translates to:
  /// **'Learning Distribution'**
  String get optionLearningDistribution;

  /// No description provided for @optionMonthlyReports.
  ///
  /// In en, this message translates to:
  /// **'Monthly Reports'**
  String get optionMonthlyReports;

  /// No description provided for @optionScheduleClasses.
  ///
  /// In en, this message translates to:
  /// **'Schedule Classes'**
  String get optionScheduleClasses;

  /// No description provided for @optionManageEvents.
  ///
  /// In en, this message translates to:
  /// **'Manage Events'**
  String get optionManageEvents;

  /// No description provided for @optionPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get optionPhotoGallery;

  /// No description provided for @optionExportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get optionExportData;

  /// No description provided for @categoryOptionsFor.
  ///
  /// In en, this message translates to:
  /// **'{category} options:'**
  String categoryOptionsFor(String category);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'as',
    'bn',
    'brx',
    'doi',
    'en',
    'gu',
    'hi',
    'kn',
    'kok',
    'ks',
    'mai',
    'ml',
    'mni',
    'mr',
    'ne',
    'or',
    'pa',
    'sa',
    'sat',
    'sd',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'brx':
      return AppLocalizationsBrx();
    case 'doi':
      return AppLocalizationsDoi();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'kok':
      return AppLocalizationsKok();
    case 'ks':
      return AppLocalizationsKs();
    case 'mai':
      return AppLocalizationsMai();
    case 'ml':
      return AppLocalizationsMl();
    case 'mni':
      return AppLocalizationsMni();
    case 'mr':
      return AppLocalizationsMr();
    case 'ne':
      return AppLocalizationsNe();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'sa':
      return AppLocalizationsSa();
    case 'sat':
      return AppLocalizationsSat();
    case 'sd':
      return AppLocalizationsSd();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
