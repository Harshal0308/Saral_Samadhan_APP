import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String username, String password) async {
    // For now, use a simple dummy login logic
    if (username == 'testuser' && password == 'testpassword') {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } else {
      _isAuthenticated = false;
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
