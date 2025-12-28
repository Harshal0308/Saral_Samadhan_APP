import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/services/auth_service.dart';
import 'package:samadhan_app/services/teacher_service.dart';
import 'package:samadhan_app/models/teacher.dart';

class AdminAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final TeacherService _teacherService = TeacherService();
  
  User? _currentUser;
  Teacher? _currentTeacher;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  Teacher? get currentTeacher => _currentTeacher;
  bool get isAuthenticated => _currentUser != null;  // Allow access with just user auth
  bool get isAdmin => _currentTeacher?.role == 'admin';
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  AdminAuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _currentUser = Supabase.instance.client.auth.currentUser;
    
    if (_currentUser != null) {
      await _loadTeacherProfile();
    }
    
    _isInitialized = true;
    
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

  Future<void> _loadTeacherProfile() async {
    if (_currentUser == null) return;
    
    try {
      _currentTeacher = await _teacherService.getTeacherProfile(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      print('Error loading teacher profile: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🔐 Admin login attempt: $email');
      
      final response = await _authService.login(email, password);
      _currentUser = response.user;
      
      print('✅ Auth response received: ${_currentUser?.id}');
      
      if (_currentUser != null) {
        await _loadTeacherProfile();
        
        if (_currentTeacher == null) {
          print('⚠️ No teacher profile found, but allowing access for admin portal');
          // For admin portal, we allow access even without teacher profile
          // Just use the authenticated user
        }
        
        if (_currentTeacher != null && !_currentTeacher!.isActive) {
          await logout();
          _errorMessage = 'Account is not active.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        print('✅ Login successful');
      }
      
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      print('❌ Login error: $e');
      String errorMsg = e.toString();
      
      // Parse Supabase error messages
      if (errorMsg.contains('Invalid login credentials')) {
        _errorMessage = 'Invalid email or password';
      } else if (errorMsg.contains('Email not confirmed')) {
        _errorMessage = 'Please confirm your email first';
      } else if (errorMsg.contains('401')) {
        _errorMessage = 'Authentication failed. Check your credentials.';
      } else {
        _errorMessage = errorMsg.replaceAll('Exception: ', '');
      }
      
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
}
