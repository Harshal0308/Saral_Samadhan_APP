import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/visit.dart';

class VisitService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Visit>> getVisits(String centerName) async {
    try {
      final response = await _supabase
          .from('visits')
          .select()
          .eq('center_name', centerName)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => Visit.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching visits: $e');
      return [];
    }
  }

  Future<bool> addVisit(Visit visit) async {
    try {
      await _supabase.from('visits').insert(visit.toJson());
      return true;
    } catch (e) {
      print('Error adding visit: $e');
      return false;
    }
  }

  Future<bool> updateVisit(Visit visit) async {
    try {
      await _supabase
          .from('visits')
          .update(visit.toJson())
          .eq('id', visit.id!);
      return true;
    } catch (e) {
      print('Error updating visit: $e');
      return false;
    }
  }

  Future<bool> deleteVisit(int visitId) async {
    try {
      await _supabase.from('visits').delete().eq('id', visitId);
      return true;
    } catch (e) {
      print('Error deleting visit: $e');
      return false;
    }
  }
}