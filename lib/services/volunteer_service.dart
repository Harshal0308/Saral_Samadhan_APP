import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/models/volunteer.dart';

class VolunteerService {
  static final VolunteerService _instance = VolunteerService._internal();
  factory VolunteerService() => _instance;
  VolunteerService._internal();

  final _supabase = Supabase.instance.client;

  /// Get volunteer suggestions for autocomplete
  /// Returns volunteers sorted by attendance count (most active first)
  Future<List<VolunteerSuggestion>> getVolunteerSuggestions(String centerName) async {
    try {
      print('🔍 Getting volunteer suggestions for center: $centerName');
      
      final response = await _supabase.rpc('get_volunteer_suggestions', params: {
        'center_name_param': centerName,
      });

      print('📊 Found ${response.length} volunteer suggestions');

      final suggestions = <VolunteerSuggestion>[];
      for (var data in response) {
        try {
          suggestions.add(VolunteerSuggestion.fromMap(data));
        } catch (e) {
          print('❌ Error parsing volunteer suggestion: $e');
        }
      }

      return suggestions;
    } catch (e) {
      print('❌ Error getting volunteer suggestions: $e');
      return [];
    }
  }

  /// Get all volunteers for a center
  Future<List<Volunteer>> getVolunteersForCenter(String centerName) async {
    try {
      print('👥 Getting volunteers for center: $centerName');
      
      final response = await _supabase
          .from('volunteers')
          .select()
          .eq('center_name', centerName)
          .order('attendance_count', ascending: false);

      print('📊 Found ${response.length} volunteers');

      final volunteers = <Volunteer>[];
      for (var data in response) {
        try {
          volunteers.add(Volunteer.fromMap(data));
        } catch (e) {
          print('❌ Error parsing volunteer: $e');
        }
      }

      return volunteers;
    } catch (e) {
      print('❌ Error getting volunteers: $e');
      return [];
    }
  }

  /// Get monthly volunteer attendance report
  Future<List<MonthlyVolunteerReport>> getMonthlyVolunteerReport(
    String centerName, {
    DateTime? reportMonth,
  }) async {
    try {
      final month = reportMonth ?? DateTime.now();
      print('📊 Getting monthly volunteer report for center: $centerName, month: ${month.year}-${month.month}');
      
      final response = await _supabase.rpc('get_monthly_volunteer_report', params: {
        'center_name_param': centerName,
        'report_month_param': month.toIso8601String().split('T')[0],
      });

      print('📈 Found ${response.length} volunteers in monthly report');

      final reports = <MonthlyVolunteerReport>[];
      for (var data in response) {
        try {
          reports.add(MonthlyVolunteerReport.fromMap(data));
        } catch (e) {
          print('❌ Error parsing monthly volunteer report: $e');
        }
      }

      return reports;
    } catch (e) {
      print('❌ Error getting monthly volunteer report: $e');
      return [];
    }
  }

  /// Manually create or update a volunteer
  /// This is usually handled automatically by the database trigger
  Future<Volunteer?> createOrUpdateVolunteer({
    required String name,
    required String centerName,
  }) async {
    try {
      print('👤 Creating/updating volunteer: $name for center: $centerName');
      
      // Check if volunteer exists
      final existing = await _supabase
          .from('volunteers')
          .select()
          .eq('name', name)
          .eq('center_name', centerName)
          .maybeSingle();

      if (existing != null) {
        // Update existing volunteer
        final updated = await _supabase
            .from('volunteers')
            .update({
              'attendance_count': existing['attendance_count'] + 1,
              'last_report_date': DateTime.now().toIso8601String().split('T')[0],
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id'])
            .select()
            .single();

        print('✅ Updated volunteer: $name');
        return Volunteer.fromMap(updated);
      } else {
        // Create new volunteer
        final created = await _supabase
            .from('volunteers')
            .insert({
              'name': name,
              'center_name': centerName,
              'attendance_count': 1,
              'first_report_date': DateTime.now().toIso8601String().split('T')[0],
              'last_report_date': DateTime.now().toIso8601String().split('T')[0],
            })
            .select()
            .single();

        print('✅ Created new volunteer: $name');
        return Volunteer.fromMap(created);
      }
    } catch (e) {
      print('❌ Error creating/updating volunteer: $e');
      return null;
    }
  }

  /// Sync existing volunteer report data
  /// This populates the volunteers table with data from existing volunteer_reports
  Future<bool> syncExistingVolunteerData() async {
    try {
      print('🔄 Syncing existing volunteer data...');
      
      await _supabase.rpc('sync_existing_volunteer_data');
      
      print('✅ Successfully synced existing volunteer data');
      return true;
    } catch (e) {
      print('❌ Error syncing existing volunteer data: $e');
      return false;
    }
  }

  /// Get volunteer statistics for a center
  Future<Map<String, dynamic>> getVolunteerStats(String centerName) async {
    try {
      final volunteers = await getVolunteersForCenter(centerName);
      
      if (volunteers.isEmpty) {
        return {
          'totalVolunteers': 0,
          'totalReports': 0,
          'averageAttendance': 0.0,
          'mostActiveVolunteer': null,
        };
      }

      final totalVolunteers = volunteers.length;
      final totalReports = volunteers.fold<int>(0, (sum, v) => sum + v.attendanceCount);
      final averageAttendance = totalReports / totalVolunteers;
      final mostActiveVolunteer = volunteers.first; // Already sorted by attendance

      return {
        'totalVolunteers': totalVolunteers,
        'totalReports': totalReports,
        'averageAttendance': averageAttendance,
        'mostActiveVolunteer': mostActiveVolunteer,
      };
    } catch (e) {
      print('❌ Error getting volunteer stats: $e');
      return {
        'totalVolunteers': 0,
        'totalReports': 0,
        'averageAttendance': 0.0,
        'mostActiveVolunteer': null,
      };
    }
  }
}