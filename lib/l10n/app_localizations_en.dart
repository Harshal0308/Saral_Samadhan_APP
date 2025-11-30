// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get saralDashboard => 'SARAL Dashboard';

  @override
  String get welcome => 'Welcome';

  @override
  String get attendance => 'Attendance';

  @override
  String get students => 'Students';

  @override
  String get volunteers => 'Volunteers';

  @override
  String get scheduler => 'Scheduler';

  @override
  String get events => 'Events';

  @override
  String get exports => 'Exports';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get name => 'Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get changePassword => 'Change Password';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get appLanguage => 'App Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get saveDetails => 'Save Details';

  @override
  String get resetLocalData => 'Reset Local Data';

  @override
  String get studentReport => 'Student Report';

  @override
  String get searchStudents => 'Search Students';

  @override
  String get filterByClassBatch => 'Filter by Class/Batch';

  @override
  String get deleteStudent => 'Delete Student';

  @override
  String get areYouSureYouWantToDelete => 'Are you sure you want to delete';

  @override
  String get volunteerReports => 'Volunteer Reports';

  @override
  String get reportBy => 'Report by';

  @override
  String get deleteSelectedReports => 'Delete Selected Reports';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'Are you sure you want to delete $count selected report(s)?';
  }
}
