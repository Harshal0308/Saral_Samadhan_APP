import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_details.dart';

class StudentDetailsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upsert student enrollment details
  /// If details exist for the student_id, update them; otherwise insert new row
  /// student_id is automatically passed from context and not entered by user
  Future<StudentDetails> upsertStudentDetails({
    required int studentId,
    required StudentDetails details,
  }) async {
    try {
      // Ensure the studentId matches
      final detailsToUpsert = details.copyWith(studentId: studentId);
      
      // Use upsert to insert or update based on student_id (primary key)
      final response = await _supabase
          .from('student_details')
          .upsert(
            detailsToUpsert.toJson(),
            onConflict: 'student_id',
          )
          .select()
          .single();

      return StudentDetails.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save student details: $e');
    }
  }

  /// Get student enrollment details by student_id
  Future<StudentDetails?> getStudentDetails(int studentId) async {
    try {
      final response = await _supabase
          .from('student_details')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) return null;
      return StudentDetails.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch student details: $e');
    }
  }

  /// Check if student has enrollment details
  Future<bool> hasEnrollmentDetails(int studentId) async {
    try {
      final response = await _supabase
          .from('student_details')
          .select('student_id')
          .eq('student_id', studentId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check enrollment details: $e');
    }
  }

  /// Delete student enrollment details
  /// Note: This is handled automatically by CASCADE DELETE when student is deleted
  /// This method is provided for manual deletion if needed
  Future<void> deleteStudentDetails(int studentId) async {
    try {
      await _supabase
          .from('student_details')
          .delete()
          .eq('student_id', studentId);
    } catch (e) {
      throw Exception('Failed to delete student details: $e');
    }
  }

  /// Get all students with their enrollment details (JOIN query)
  Future<List<Map<String, dynamic>>> getStudentsWithDetails() async {
    try {
      final response = await _supabase
          .from('students')
          .select('''
            *,
            student_details (*)
          ''');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch students with details: $e');
    }
  }

  /// Get students without enrollment details
  Future<List<Map<String, dynamic>>> getStudentsWithoutDetails() async {
    try {
      final response = await _supabase
          .from('students')
          .select('''
            *,
            student_details!left (student_id)
          ''')
          .isFilter('student_details.student_id', null);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch students without details: $e');
    }
  }

  /// Update specific fields of student details
  Future<StudentDetails> updateStudentDetailsFields({
    required int studentId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _supabase
          .from('student_details')
          .update(updates)
          .eq('student_id', studentId)
          .select()
          .single();

      return StudentDetails.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update student details: $e');
    }
  }
}
