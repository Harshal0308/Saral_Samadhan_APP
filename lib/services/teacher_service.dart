import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/models/teacher.dart';

class TeacherService {
  static final TeacherService _instance = TeacherService._internal();
  factory TeacherService() => _instance;
  TeacherService._internal();

  final _supabase = Supabase.instance.client;

  /// Get teacher profile by user ID
  Future<Teacher?> getTeacherProfile(String userId) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return Teacher.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching teacher profile: $e');
      return null;
    }
  }

  /// Create or update teacher profile
  Future<Teacher?> createOrUpdateTeacher({
    required String userId,
    required String email,
    String? name,
    String? phoneNumber,
    String? centerName,
  }) async {
    try {
      // Check if teacher already exists
      final existingTeacher = await getTeacherProfile(userId);
      
      final now = DateTime.now().toIso8601String();
      
      if (existingTeacher != null) {
        // Update existing teacher
        final updateData = <String, dynamic>{
          'email': email,
          'updated_at': now,
        };
        
        // Only update fields that are provided
        if (name != null) updateData['name'] = name;
        if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
        if (centerName != null) updateData['center_name'] = centerName;

        final response = await _supabase
            .from('teachers')
            .update(updateData)
            .eq('id', userId)
            .select()
            .single();

        return Teacher.fromMap(response);
      } else {
        // Create new teacher
        final insertData = {
          'id': userId,
          'email': email,
          'name': name ?? email.split('@')[0], // Use email prefix as default name
          'phone_number': phoneNumber ?? '',
          'center_name': centerName ?? '',
          'role': 'teacher',
          'is_active': true,
          'created_at': now,
          'updated_at': now,
        };

        final response = await _supabase
            .from('teachers')
            .insert(insertData)
            .select()
            .single();

        return Teacher.fromMap(response);
      }
    } catch (e) {
      print('❌ Error creating/updating teacher: $e');
      return null;
    }
  }

  /// Update teacher profile
  Future<Teacher?> updateTeacherProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? centerName,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (centerName != null) updateData['center_name'] = centerName;

      final response = await _supabase
          .from('teachers')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return Teacher.fromMap(response);
    } catch (e) {
      print('❌ Error updating teacher profile: $e');
      return null;
    }
  }

  /// Get all teachers for a specific center
  Future<List<Teacher>> getTeachersByCenter(String centerName) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select()
          .eq('center_name', centerName)
          .eq('is_active', true)
          .order('name');

      return response.map<Teacher>((data) => Teacher.fromMap(data)).toList();
    } catch (e) {
      print('❌ Error fetching teachers by center: $e');
      return [];
    }
  }

  /// Get all active teachers
  Future<List<Teacher>> getAllActiveTeachers() async {
    try {
      final response = await _supabase
          .from('teachers')
          .select()
          .eq('is_active', true)
          .order('name');

      return response.map<Teacher>((data) => Teacher.fromMap(data)).toList();
    } catch (e) {
      print('❌ Error fetching all active teachers: $e');
      return [];
    }
  }

  /// Deactivate teacher (soft delete)
  Future<bool> deactivateTeacher(String userId) async {
    try {
      await _supabase
          .from('teachers')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ Error deactivating teacher: $e');
      return false;
    }
  }

  /// Reactivate teacher
  Future<bool> reactivateTeacher(String userId) async {
    try {
      await _supabase
          .from('teachers')
          .update({
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ Error reactivating teacher: $e');
      return false;
    }
  }

  /// Check if user is a valid teacher
  Future<bool> isValidTeacher(String userId) async {
    try {
      final teacher = await getTeacherProfile(userId);
      return teacher != null && teacher.isActive;
    } catch (e) {
      print('❌ Error checking teacher validity: $e');
      return false;
    }
  }
}