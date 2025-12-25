import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/services/auth_service.dart';
import 'package:samadhan_app/services/teacher_service.dart';
import 'package:samadhan_app/models/teacher.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final TeacherService _teacherService = TeacherService();
  User? _currentUser;
  Teacher? _currentTeacher;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  Teacher? get currentTeacher => _currentTeacher;
  bool get isAuthenticated => _currentUser != null && _currentTeacher != null;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Check for existing session immediately
    _currentUser = Supabase.instance.client.auth.currentUser;
    _isInitialized = true;
    
    // Load teacher profile if user exists
    if (_currentUser != null) {
      _loadTeacherProfile();
    }
    
    // Listen for auth state changes
    _authService.authStateStream.listen((state) {
      _currentUser = state.session?.user;
      if (_currentUser != null) {
        _loadTeacherProfile();
      } else {
        _currentTeacher = null;
      }
      notifyListeners();
    });
    
    notifyListeners();
  }

  /// Load teacher profile for current user
  Future<void> _loadTeacherProfile() async {
    if (_currentUser == null) return;
    
    try {
      _currentTeacher = await _teacherService.getTeacherProfile(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      print('❌ Error loading teacher profile: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.login(email, password);
      _currentUser = response.user;
      
      // Load teacher profile after successful login
      if (_currentUser != null) {
        await _loadTeacherProfile();
        
        // Verify that user is a valid teacher
        if (_currentTeacher == null || !_currentTeacher!.isActive) {
          await logout();
          _errorMessage = 'Access denied. Only active teachers can login.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.changePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.logout();
      _currentUser = null;
      _currentTeacher = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendConfirmationEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resendConfirmationEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String centerName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Sign up user in Supabase Auth with metadata
      final response = await _authService.signUp(
        email, 
        password,
        name: name,
        phoneNumber: phone,
        centerName: centerName,
      );
      _currentUser = response.user;

      // Teacher profile is automatically created in AuthService
      if (_currentUser != null) {
        await _loadTeacherProfile();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update teacher profile
  Future<bool> updateTeacherProfile({
    String? name,
    String? phoneNumber,
    String? centerName,
  }) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedTeacher = await _teacherService.updateTeacherProfile(
        userId: _currentUser!.id,
        name: name,
        phoneNumber: phoneNumber,
        centerName: centerName,
      );

      if (updatedTeacher != null) {
        _currentTeacher = updatedTeacher;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update teacher profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh teacher profile
  Future<void> refreshTeacherProfile() async {
    await _loadTeacherProfile();
  }
}
