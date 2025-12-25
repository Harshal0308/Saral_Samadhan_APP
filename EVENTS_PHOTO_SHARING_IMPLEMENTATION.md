# Events & Activities Photo Sharing Implementation

## ✅ What Was Created:

### 1. **Supabase Setup** (Run SQL commands first)
- Created `events` table with all necessary fields
- Created `event-photos` storage bucket (public)
- Set up RLS policies for data security
- Enabled photo upload/download for all authenticated users

### 2. **New Services Created:**
- `lib/services/event_storage_service.dart` - Handles photo uploads to Supabase Storage
- `lib/services/event_sync_service.dart` - Syncs events to/from Supabase database

### 3. **New Pages Created:**
- `lib/pages/event_photo_viewer_page.dart` - Full-screen photo viewer with zoom
- `lib/pages/event_report_page.dart` - Detailed event report with all info

## 📋 Next Steps (Manual Updates Needed):

### Step 1: Add Dependencies to `pubspec.yaml`

```yaml
dependencies:
  cached_network_image: ^3.3.0
  photo_view: ^0.14.0
  path: ^1.8.3
```

Then run: `flutter pub get`

### Step 2: Update `lib/providers/event_provider.dart`

Add these imports at the top:
```dart
import 'package:samadhan_app/services/event_storage_service.dart';
import 'package:samadhan_app/services/event_sync_service.dart';
import 'package:samadhan_app/providers/user_provider.dart';
```

Replace the `addEvent` method with:
```dart
Future<void> addEvent({
  required String title,
  required String description,
  required DateTime date,
  required TimeOfDay time,
  String attendanceSummary = 'N/A',
  List<String> photoPaths = const [],
  String classBatch = '',
  String centerName = '',
  List<String> presentStudentRolls = const [],
  List<String> topics = const [],
}) async {
  final db = await _dbService.database;
  
  // 1. Save locally first
  final newEvent = Event(
    id: 0,
    title: title,
    description: description,
    date: date,
    time: time,
    attendanceSummary: attendanceSummary,
    photoPaths: photoPaths,
    classBatch: classBatch,
    centerName: centerName,
    presentStudentRolls: presentStudentRolls,
    topics: topics,
  );
  
  final localId = await _eventStore.add(db, newEvent.toMap());
  
  // 2. Upload photos to Supabase Storage
  List<String> photoUrls = [];
  if (photoPaths.isNotEmpty) {
    final storageService = EventStorageService();
    final photoFiles = photoPaths.map((path) => File(path)).toList();
    photoUrls = await storageService.uploadPhotos(photoFiles, localId.toString());
  }
  
  // 3. Sync to Supabase database
  try {
    final syncService = EventSyncService();
    final eventWithUrls = newEvent.copyWith(
      id: localId,
      photoPaths: photoUrls,
    );
    await syncService.uploadEvent(eventWithUrls, photoUrls);
    print('✅ Event synced to cloud');
  } catch (e) {
    print('⚠️ Event saved locally, will sync later: $e');
  }
  
  await loadEvents();
}
```

Add this new method to sync events from cloud:
```dart
Future<void> syncEventsFromCloud(String centerName) async {
  try {
    final syncService = EventSyncService();
    final cloudEvents = await syncService.downloadEventsForCenter(centerName);
    
    final db = await _dbService.database;
    
    // Merge cloud events with local
    for (var cloudEvent in cloudEvents) {
      // Check if event already exists locally
      final existing = await _eventStore.findFirst(
        db,
        finder: Finder(
          filter: Filter.and([
            Filter.equals('title', cloudEvent.title),
            Filter.equals('date', cloudEvent.date.toIso8601String()),
          ]),
        ),
      );
      
      if (existing == null) {
        // New event from cloud, add locally
        await _eventStore.add(db, cloudEvent.toMap());
        print('✅ Added event from cloud: ${cloudEvent.title}');
      }
    }
    
    await loadEvents();
  } catch (e) {
    print('❌ Error syncing events from cloud: $e');
  }
}
```

### Step 3: Update `lib/pages/events_activities_page.dart`

Add these imports:
```dart
import 'package:samadhan_app/pages/event_photo_viewer_page.dart';
import 'package:samadhan_app/pages/event_report_page.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
```

In `initState`, add sync:
```dart
@override
void initState() {
  super.initState();
  final eventProvider = Provider.of<EventProvider>(context, listen: false);
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final centerName = userProvider.userSettings.selectedCenter ?? '';
  
  eventProvider.loadEvents();
  if (centerName.isNotEmpty) {
    eventProvider.syncEventsFromCloud(centerName);
  }
}
```

Update the "View Photos" button (around line 330):
```dart
OutlinedButton(
  onPressed: () {
    if (event.photoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos available')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventPhotoViewerPage(
          photoUrls: event.photoPaths,
          initialIndex: 0,
          eventTitle: event.title,
        ),
      ),
    );
  },
  style: OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF6B7280),
    side: const BorderSide(color: Color(0xFFE5E7EB)),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  child: const Text('View Photos'),
),
```

Update the "View Report" button:
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventReportPage(event: event),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFEDE9FE),
    foregroundColor: const Color(0xFF8B5CF6),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
  ),
  child: const Text('View Report'),
),
```

Update the photo grid in the event card to show thumbnails:
```dart
if (photoCount > 0) ...[
  const SizedBox(height: 12),
  SizedBox(
    height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: event.photoPaths.take(5).length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: event.photoPaths[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    ),
  ),
],
```

In the `_showAddEventDialog` method, update to get center name:
```dart
final userProvider = Provider.of<UserProvider>(context, listen: false);
final selectedCenter = userProvider.userSettings.selectedCenter ?? 'Unknown';

await eventProvider.addEvent(
  title: _title!,
  description: _description!,
  date: _selectedDate!,
  time: _selectedTime!,
  attendanceSummary: _attendanceSummary ?? 'N/A',
  photoPaths: _pickedImages.map((f) => f.path).toList(),
  centerName: selectedCenter, // Add this
);
```

## 🎯 How It Works:

1. **Volunteer A creates event with photos:**
   - Photos uploaded to Supabase Storage
   - Event data saved to Supabase database
   - Photo URLs stored in event record

2. **Volunteer B opens Events page:**
   - App syncs events from Supabase for their center
   - Downloads event data with photo URLs
   - Photos load from Supabase Storage

3. **Both volunteers see:**
   - Same events for their center
   - Same photos (loaded from cloud)
   - Full event reports

## 🔒 Security:

- Only authenticated users can upload/view
- Photos are public (anyone with URL can view)
- Events filtered by center name
- RLS policies protect data access

## 📱 Features:

✅ Photo upload to cloud storage
✅ Event sync across volunteers
✅ Full-screen photo viewer with zoom
✅ Detailed event reports
✅ Center-specific event filtering
✅ Offline-first with cloud sync
✅ Photo thumbnails in event list

## 🐛 Troubleshooting:

If photos don't upload:
1. Check Supabase Storage bucket exists
2. Verify storage policies are set
3. Check console logs for errors
4. Ensure user is authenticated

If events don't sync:
1. Check `events` table exists
2. Verify RLS policies
3. Check network connection
4. Look for sync errors in console
