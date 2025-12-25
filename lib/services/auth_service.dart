import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/services/teacher_service.dart';
import 'package:samadhan_app/models/teacher.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final SupabaseClient _supabase;
  final TeacherService _teacherService = TeacherService();

  Future<void> initialize() async {
    _supabase = Supabase.instance.client;
  }

  SupabaseClient get client => _supabase;

  // Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // If login successful, ensure teacher profile exists
      if (response.user != null) {
        await _ensureTeacherProfile(response.user!);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up (for admin only)
  Future<AuthResponse> signUp(String email, String password, {
    String? name,
    String? phoneNumber,
    String? centerName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // Set to null to disable email confirmation for now
      );

      // If signup successful, create teacher profile
      if (response.user != null) {
        await _teacherService.createOrUpdateTeacher(
          userId: response.user!.id,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          centerName: centerName,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Ensure teacher profile exists for authenticated user
  Future<Teacher?> _ensureTeacherProfile(User user) async {
    try {
      // Check if teacher profile exists
      Teacher? teacher = await _teacherService.getTeacherProfile(user.id);
      
      if (teacher == null) {
        // Create teacher profile if it doesn't exist
        print('🔄 Creating teacher profile for user: ${user.email}');
        teacher = await _teacherService.createOrUpdateTeacher(
          userId: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['name'] as String?,
          phoneNumber: user.userMetadata?['phone_number'] as String?,
          centerName: user.userMetadata?['center_name'] as String?,
        );
        
        if (teacher != null) {
          print('✅ Teacher profile created successfully');
        } else {
          print('❌ Failed to create teacher profile');
        }
      } else {
        // Update email if it has changed
        if (teacher.email != user.email && user.email != null) {
          print('🔄 Updating teacher email from ${teacher.email} to ${user.email}');
          teacher = await _teacherService.createOrUpdateTeacher(
            userId: user.id,
            email: user.email!,
          );
        }
      }
      
      return teacher;
    } catch (e) {
      print('❌ Error ensuring teacher profile: $e');
      return null;
    }
  }

  /// Get current teacher profile
  Future<Teacher?> getCurrentTeacherProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;
    
    return await _teacherService.getTeacherProfile(user.id);
  }

  // Resend confirmation email
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // Get auth state stream
  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;

  // Reset password (send email)
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}
