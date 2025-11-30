// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get login => 'लॉग इन करें';

  @override
  String get username => 'उपयोगकर्ता नाम';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get saralDashboard => 'सरल डैशबोर्ड';

  @override
  String get welcome => 'स्वागत है';

  @override
  String get attendance => 'उपस्थिति';

  @override
  String get students => 'छात्र';

  @override
  String get volunteers => 'स्वयंसेवक';

  @override
  String get scheduler => 'अनुसूचक';

  @override
  String get events => 'आयोजन';

  @override
  String get exports => 'निर्यात';

  @override
  String get accountDetails => 'अकाउंट विवरण';

  @override
  String get changePhoto => 'फोटो बदलें';

  @override
  String get name => 'नाम';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get oldPassword => 'पुराना पासवर्ड';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get confirmNewPassword => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get appLanguage => 'ऐप की भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get saveDetails => 'विवरण सहेजें';

  @override
  String get resetLocalData => 'स्थानीय डेटा रीसेट करें';

  @override
  String get studentReport => 'छात्र रिपोर्ट';

  @override
  String get searchStudents => 'छात्र खोजें';

  @override
  String get filterByClassBatch => 'कक्षा/बैच द्वारा फ़िल्टर करें';

  @override
  String get deleteStudent => 'छात्र को हटाएं';

  @override
  String get areYouSureYouWantToDelete => 'क्या आप वाकई हटाना चाहते हैं';

  @override
  String get volunteerReports => 'स्वयंसेवक रिपोर्ट';

  @override
  String get reportBy => 'रिपोर्ट द्वारा';

  @override
  String get deleteSelectedReports => 'चयनित रिपोर्ट हटाएं';

  @override
  String areYouSureYouWantToDeleteNReports(int count) {
    return 'क्या आप वाकई $count चयनित रिपोर्ट हटाना चाहते हैं?';
  }
}
