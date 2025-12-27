import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/models/monthly_activity.dart';

class MonthlyActivityProvider with ChangeNotifier {
  final _activityStore = intMapStoreFactory.store('monthly_activities');
  final DatabaseService _dbService = DatabaseService();
  final _supabase = Supabase.instance.client;

  List<MonthlyActivity> _activities = [];
  List<MonthlyActivity> get activities => _activities;

  // Default activities
  static const List<String> defaultActivities = [
    'Bal Sabha',
    'Monthly test',
    'Parents meet',
    'Volunteer meet',
    'Sports',
    'Art',
    'Centre cleaning',
    'Seva Day',
  ];

  // Get unique activity names for dropdown
  List<String> getActivityNames(String centerName) {
    final centerActivities = _activities
        .where((a) => a.centerName == centerName)
        .map((a) => a.name)
        .toSet();
    
    // Combine default activities with custom ones
    final allNames = {...defaultActivities, ...centerActivities};
    return allNames.toList()..sort();
  }

  // Get activities for a specific center
  List<MonthlyActivity> getActivitiesForCenter(String centerName) {
    return _activities.where((a) => a.centerName == centerName).toList();
  }

  Future<void> loadActivities() async {
    final db = await _dbService.database;
    final snapshots = await _activityStore.find(db);
    _activities = snapshots
        .map((s) => MonthlyActivity.fromMap(s.value, s.key))
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    notifyListeners();
  }

  Future<MonthlyActivity> addActivity({
    required String name,
    String? date,
    String? purpose,
    required String centerName,
  }) async {
    final db = await _dbService.database;
    
    final activity = MonthlyActivity(
      id: 0,
      name: name,
      date: date,
      purpose: purpose,
      centerName: centerName,
      createdAt: DateTime.now(),
    );

    final localId = await _activityStore.add(db, activity.toMap());
    
    // Sync to Supabase
    try {
      await _supabase.from('monthly_activities').insert(activity.toSupabase());
      print('✅ Activity synced to Supabase: $name');
    } catch (e) {
      print('⚠️ Error syncing activity to Supabase: $e');
    }

    await loadActivities();
    return activity.copyWith(id: localId);
  }

  Future<void> updateActivity(MonthlyActivity activity) async {
    final db = await _dbService.database;
    await _activityStore.update(
      db,
      activity.toMap(),
      finder: Finder(filter: Filter.byKey(activity.id)),
    );
    
    // Sync to Supabase
    try {
      await _supabase
          .from('monthly_activities')
          .update(activity.toSupabase())
          .eq('id', activity.id);
    } catch (e) {
      print('⚠️ Error updating activity in Supabase: $e');
    }

    await loadActivities();
  }

  Future<void> syncFromCloud(String centerName) async {
    try {
      final response = await _supabase
          .from('monthly_activities')
          .select()
          .eq('center_name', centerName)
          .order('created_at', ascending: false);

      final db = await _dbService.database;
      
      for (var data in response) {
        final cloudActivity = MonthlyActivity.fromSupabase(data);
        
        // Check if exists locally
        final existing = await _activityStore.findFirst(
          db,
          finder: Finder(
            filter: Filter.and([
              Filter.equals('name', cloudActivity.name),
              Filter.equals('centerName', cloudActivity.centerName),
              Filter.equals('date', cloudActivity.date),
            ]),
          ),
        );
        
        if (existing == null) {
          await _activityStore.add(db, cloudActivity.toMap());
        }
      }
      
      await loadActivities();
      print('✅ Activities synced from cloud for: $centerName');
    } catch (e) {
      print('❌ Error syncing activities from cloud: $e');
    }
  }
}
