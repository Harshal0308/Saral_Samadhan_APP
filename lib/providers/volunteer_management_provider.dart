import 'package:flutter/material.dart';
import 'package:samadhan_app/services/database_service.dart';
import 'package:samadhan_app/services/cloud_sync_service_v2.dart';
import 'package:samadhan_app/services/volunteer_service.dart';
import 'package:samadhan_app/models/volunteer.dart';
import 'package:sembast/sembast.dart';

class VolunteerManagementProvider with ChangeNotifier {
  final _volunteerStore = intMapStoreFactory.store('volunteers');
  final DatabaseService _dbService = DatabaseService();
  final VolunteerService _volunteerService = VolunteerService();

  List<Volunteer> _volunteers = [];
  List<VolunteerSuggestion> _suggestions = [];
  bool _isLoading = false;

  List<Volunteer> get volunteers => _volunteers;
  List<VolunteerSuggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;

  /// Get volunteers filtered by center
  List<Volunteer> getVolunteersByCenter(String centerName) {
    return _volunteers.where((v) => v.centerName == centerName).toList();
  }

  /// Get volunteer suggestions for autocomplete
  Future<List<VolunteerSuggestion>> getVolunteerSuggestions(String centerName) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to get from cloud first
      final cloudSuggestions = await _volunteerService.getVolunteerSuggestions(centerName);
      
      if (cloudSuggestions.isNotEmpty) {
        _suggestions = cloudSuggestions;
      } else {
        // Fallback to local data
        final localVolunteers = getVolunteersByCenter(centerName);
        _suggestions = localVolunteers.map((v) => VolunteerSuggestion(
          name: v.name,
          attendanceCount: v.attendanceCount,
          lastReportDate: v.lastReportDate,
        )).toList();
      }

      return _suggestions;
    } catch (e) {
      print('❌ Error getting volunteer suggestions: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add or update volunteer (usually called automatically when reports are submitted)
  Future<void> addOrUpdateVolunteer({
    required String name,
    required String centerName,
    bool syncToCloud = true,
  }) async {
    try {
      print('🔍 VolunteerManagementProvider: addOrUpdateVolunteer called');
      print('   Name: $name');
      print('   Center: $centerName');
      print('   Sync to cloud: $syncToCloud');

      // Check if volunteer exists locally
      final existingIndex = _volunteers.indexWhere(
        (v) => v.name == name && v.centerName == centerName,
      );

      if (existingIndex != -1) {
        // Update existing volunteer
        print('   📝 Updating existing volunteer');
        final existing = _volunteers[existingIndex];
        final updated = Volunteer(
          id: existing.id,
          name: existing.name,
          centerName: existing.centerName,
          attendanceCount: existing.attendanceCount + 1,
          firstReportDate: existing.firstReportDate,
          lastReportDate: DateTime.now(),
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );

        await _updateVolunteerLocally(updated);
        
        if (syncToCloud) {
          await _syncVolunteerToCloud(updated, isUpdate: true);
        }
        print('   ✅ Existing volunteer updated successfully');
      } else {
        // Create new volunteer
        print('   ➕ Creating new volunteer');
        final now = DateTime.now();
        final newVolunteer = Volunteer(
          id: now.millisecondsSinceEpoch, // Use timestamp as local ID
          name: name,
          centerName: centerName,
          attendanceCount: 1,
          firstReportDate: now,
          lastReportDate: now,
          createdAt: now,
          updatedAt: now,
        );

        await _addVolunteerLocally(newVolunteer);
        
        if (syncToCloud) {
          await _syncVolunteerToCloud(newVolunteer, isUpdate: false);
        }
        print('   ✅ New volunteer created successfully');
      }
    } catch (e, stackTrace) {
      print('❌ Error in addOrUpdateVolunteer: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Add volunteer locally
  Future<void> _addVolunteerLocally(Volunteer volunteer) async {
    try {
      final db = await _dbService.database;
      await _volunteerStore.record(volunteer.id).put(db, volunteer.toMap());
      await fetchVolunteers();
    } catch (e) {
      print('❌ Error adding volunteer locally: $e');
    }
  }

  /// Update volunteer locally
  Future<void> _updateVolunteerLocally(Volunteer volunteer) async {
    try {
      final db = await _dbService.database;
      await _volunteerStore.record(volunteer.id).put(db, volunteer.toMap());
      await fetchVolunteers();
    } catch (e) {
      print('❌ Error updating volunteer locally: $e');
    }
  }

  /// Sync volunteer to cloud
  Future<void> _syncVolunteerToCloud(Volunteer volunteer, {required bool isUpdate}) async {
    try {
      print('☁️ Syncing volunteer to cloud...');
      print('   Volunteer: ${volunteer.name}');
      print('   Center: ${volunteer.centerName}');
      print('   Is update: $isUpdate');
      
      final cloudSyncV2 = CloudSyncServiceV2();
      final isOnline = await cloudSyncV2.isOnline();
      
      print('   Online status: $isOnline');
      
      if (isOnline) {
        print('🌐 Online - attempting immediate sync of volunteer to cloud');
        
        if (isUpdate) {
          await cloudSyncV2.queueVolunteerUpdate(volunteer);
        } else {
          await cloudSyncV2.queueVolunteerUpload(volunteer);
        }
        
        final syncResult = await cloudSyncV2.processSyncQueue();
        
        if (syncResult['success'] == true) {
          print('✅ Volunteer immediately synced to cloud');
        } else {
          print('⚠️ Immediate sync failed, will retry later: ${syncResult['message']}');
        }
      } else {
        print('📱 Offline - volunteer queued for sync when online');
        
        if (isUpdate) {
          await cloudSyncV2.queueVolunteerUpdate(volunteer);
        } else {
          await cloudSyncV2.queueVolunteerUpload(volunteer);
        }
      }
    } catch (e, stackTrace) {
      print('⚠️ Failed to sync volunteer: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Fetch volunteers from local database
  Future<void> fetchVolunteers() async {
    try {
      final db = await _dbService.database;
      final snapshots = await _volunteerStore.find(db);
      
      _volunteers = snapshots.map((snapshot) {
        return Volunteer.fromMap(snapshot.value);
      }).toList();

      // Sort by attendance count (descending) then by name
      _volunteers.sort((a, b) {
        final countComparison = b.attendanceCount.compareTo(a.attendanceCount);
        if (countComparison != 0) return countComparison;
        return a.name.compareTo(b.name);
      });

      notifyListeners();
    } catch (e) {
      print('❌ Error fetching volunteers: $e');
    }
  }

  /// Get monthly volunteer report
  Future<List<MonthlyVolunteerReport>> getMonthlyReport(
    String centerName, {
    DateTime? reportMonth,
  }) async {
    try {
      return await _volunteerService.getMonthlyVolunteerReport(
        centerName,
        reportMonth: reportMonth,
      );
    } catch (e) {
      print('❌ Error getting monthly volunteer report: $e');
      return [];
    }
  }

  /// Get volunteer statistics
  Future<Map<String, dynamic>> getVolunteerStats(String centerName) async {
    try {
      return await _volunteerService.getVolunteerStats(centerName);
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

  /// Sync existing volunteer data from cloud
  Future<bool> syncExistingData() async {
    try {
      return await _volunteerService.syncExistingVolunteerData();
    } catch (e) {
      print('❌ Error syncing existing volunteer data: $e');
      return false;
    }
  }

  /// Download and merge volunteers from cloud
  Future<void> downloadAndMergeVolunteers(String centerName) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cloudSyncV2 = CloudSyncServiceV2();
      final cloudVolunteers = await cloudSyncV2.downloadVolunteersForCenter(centerName);
      
      for (var cloudVolunteer in cloudVolunteers) {
        final localIndex = _volunteers.indexWhere(
          (v) => v.name == cloudVolunteer.name && v.centerName == cloudVolunteer.centerName,
        );

        if (localIndex == -1) {
          // Add new volunteer from cloud
          await _addVolunteerLocally(cloudVolunteer);
        } else {
          // Update local volunteer if cloud has higher attendance
          final localVolunteer = _volunteers[localIndex];
          if (cloudVolunteer.attendanceCount > localVolunteer.attendanceCount) {
            await _updateVolunteerLocally(cloudVolunteer);
          }
        }
      }
    } catch (e) {
      print('❌ Error downloading and merging volunteers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}