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
}
