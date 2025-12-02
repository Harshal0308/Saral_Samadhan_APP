import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:samadhan_app/services/database_service.dart';

class UserSettings {
  final String name;
  final String phoneNumber;
  final String language;
  final String? selectedCenter;

  UserSettings({
    this.name = '',
    this.phoneNumber = '',
    this.language = 'en', // Default language
    this.selectedCenter,
  });

  UserSettings copyWith({
    String? name,
    String? phoneNumber,
    String? language,
    String? selectedCenter,
  }) {
    return UserSettings(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      language: language ?? this.language,
      selectedCenter: selectedCenter ?? this.selectedCenter,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'language': language,
      'selectedCenter': selectedCenter,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      language: map['language'] as String,
      selectedCenter: map['selectedCenter'] as String?,
    );
  }
}

class UserProvider with ChangeNotifier {
  final _settingsStore = stringMapStoreFactory.store('user_settings');
  final DatabaseService _dbService = DatabaseService();

  UserSettings _userSettings = UserSettings();
  UserSettings get userSettings => _userSettings;

  Future<void> loadSettings() async {
    final db = await _dbService.database;
    final snapshot = await _settingsStore.record('user_settings').getSnapshot(db);

    if (snapshot != null) {
      _userSettings = UserSettings.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    } else {
      _userSettings = UserSettings(); // Default settings
    }
    notifyListeners();
  }

  Future<void> saveSettings(UserSettings newSettings) async {
    final db = await _dbService.database;
    await _settingsStore.record('user_settings').put(db, newSettings.toMap());
    _userSettings = newSettings;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    await saveSettings(_userSettings.copyWith(name: name));
  }

  Future<void> updatePhoneNumber(String phoneNumber) async {
    await saveSettings(_userSettings.copyWith(phoneNumber: phoneNumber));
  }

  Future<void> updateLanguage(String language) async {
    await saveSettings(_userSettings.copyWith(language: language));
  }

  Future<void> updateSelectedCenter(String? center) async {
    await saveSettings(_userSettings.copyWith(selectedCenter: center));
  }

  Future<void> resetAllLocalData() async {
    await _dbService.clearAllStores();
    // Re-initialize providers after clearing data
    // This needs to be done carefully, usually by restarting the app or re-loading data
    _userSettings = UserSettings(); // Reset to default
    notifyListeners();
  }
}
