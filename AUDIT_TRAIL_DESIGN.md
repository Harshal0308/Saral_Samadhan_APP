# 🔍 AUDIT TRAIL & CONFLICT RESOLUTION SYSTEM

## 🎯 Problems to Solve

### Problem 1: No Audit Trail
**Current Issue:**
- Can't see who changed what
- Can't see when changes were made
- Can't track history of edits
- No accountability

**Solution:**
- Add `created_by`, `updated_by`, `created_at`, `updated_at` to all tables
- Create separate `audit_log` table for detailed change history
- Track every create, update, delete operation

### Problem 2: Sync Conflicts
**Current Issue:**
- Multiple teachers edit same data simultaneously
- No clear conflict resolution
- Data gets overwritten randomly
- No way to see what was lost

**Solution:**
- Use `updated_at` timestamp for conflict detection
- Implement "Last Write Wins" with history preservation
- Store conflicting versions in audit log
- Allow viewing conflict history

---

## 📊 Database Schema Changes

### 1. Add Audit Fields to Existing Tables

**Students Table:**
```sql
ALTER TABLE students
ADD COLUMN created_by TEXT,
ADD COLUMN updated_by TEXT,
ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
```

**Attendance Records Table:**
```sql
ALTER TABLE attendance_records
ADD COLUMN created_by TEXT,
ADD COLUMN updated_by TEXT,
ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
```

**Volunteer Reports Table:**
```sql
ALTER TABLE volunteer_reports
ADD COLUMN created_by TEXT,
ADD COLUMN updated_by TEXT,
ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
```

### 2. Create Audit Log Table

```sql
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE'
  user_email TEXT NOT NULL,
  user_name TEXT,
  center_name TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  old_data JSONB,
  new_data JSONB,
  changes JSONB, -- Specific fields that changed
  conflict_detected BOOLEAN DEFAULT FALSE,
  conflict_resolution TEXT, -- 'last_write_wins', 'manual', etc.
  device_info TEXT,
  app_version TEXT
);

-- Indexes for fast queries
CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_user ON audit_log(user_email);
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp DESC);
CREATE INDEX idx_audit_log_center ON audit_log(center_name);
```

### 3. Create Triggers for Auto-Audit

```sql
-- Function to log changes
CREATE OR REPLACE FUNCTION log_audit_trail()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO audit_log (
      table_name, record_id, operation, 
      user_email, user_name, center_name,
      new_data
    ) VALUES (
      TG_TABLE_NAME, NEW.id::TEXT, 'CREATE',
      NEW.created_by, NEW.created_by, NEW.center_name,
      row_to_json(NEW)::JSONB
    );
    RETURN NEW;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO audit_log (
      table_name, record_id, operation,
      user_email, user_name, center_name,
      old_data, new_data, changes
    ) VALUES (
      TG_TABLE_NAME, NEW.id::TEXT, 'UPDATE',
      NEW.updated_by, NEW.updated_by, NEW.center_name,
      row_to_json(OLD)::JSONB,
      row_to_json(NEW)::JSONB,
      jsonb_diff(row_to_json(OLD)::JSONB, row_to_json(NEW)::JSONB)
    );
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO audit_log (
      table_name, record_id, operation,
      user_email, center_name,
      old_data
    ) VALUES (
      TG_TABLE_NAME, OLD.id::TEXT, 'DELETE',
      current_user, OLD.center_name,
      row_to_json(OLD)::JSONB
    );
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables
CREATE TRIGGER students_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER attendance_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON attendance_records
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER volunteer_reports_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON volunteer_reports
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();
```

---

## 🔧 App Implementation

### 1. Update Models to Include Audit Fields

**Student Model:**
```dart
class Student {
  final int id;
  final String name;
  final String rollNo;
  final String classBatch;
  final String centerName;
  
  // NEW: Audit fields
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // ... rest of fields
}
```

### 2. Update Sync Service to Include User Info

```dart
class CloudSyncService {
  String? _currentUserEmail;
  String? _currentUserName;
  
  void setCurrentUser(String email, String name) {
    _currentUserEmail = email;
    _currentUserName = name;
  }
  
  Future<bool> uploadStudent(Student student) async {
    // Check for conflicts
    final existing = await _checkForConflicts('students', student.id);
    
    if (existing != null && existing['updated_at'] != null) {
      final serverTime = DateTime.parse(existing['updated_at']);
      final localTime = student.updatedAt ?? DateTime.now();
      
      if (serverTime.isAfter(localTime)) {
        // Conflict detected!
        await _logConflict('students', student.id, existing, student.toMap());
      }
    }
    
    // Upload with audit info
    await _supabase.from('students').upsert({
      ...student.toMap(),
      'updated_by': _currentUserEmail,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
```

### 3. Create Audit Log Viewer

```dart
class AuditLogPage extends StatelessWidget {
  Future<List<AuditEntry>> _fetchAuditLog(String? filterTable, String? filterUser) async {
    var query = Supabase.instance.client
        .from('audit_log')
        .select()
        .order('timestamp', ascending: false)
        .limit(100);
    
    if (filterTable != null) {
      query = query.eq('table_name', filterTable);
    }
    if (filterUser != null) {
      query = query.eq('user_email', filterUser);
    }
    
    final response = await query;
    return response.map((e) => AuditEntry.fromMap(e)).toList();
  }
}
```

---

## 🎯 Conflict Resolution Strategy

### Strategy: Last Write Wins + History

**How it works:**
1. Before uploading, check server's `updated_at` timestamp
2. If server timestamp > local timestamp → **Conflict detected**
3. Log the conflict in audit_log with both versions
4. Apply "Last Write Wins" (upload anyway)
5. User can view conflict history later

**Example:**
```
Teacher A: Updates student at 10:00 AM
Teacher B: Updates same student at 10:05 AM (offline)
Teacher B: Syncs at 10:10 AM

Result:
- Teacher B's changes win (last write)
- Teacher A's changes saved in audit_log
- Both teachers can see conflict in history
```

---

## 📱 UI Features

### 1. Audit Trail Viewer
**Location:** Settings → Audit Trail

**Features:**
- View all changes
- Filter by:
  - Table (Students, Attendance, Reports)
  - User
  - Date range
  - Center
- See what changed (old → new)
- See who made the change
- See when it happened

### 2. Conflict History
**Location:** Settings → Conflicts

**Features:**
- List of all detected conflicts
- Show both versions (yours vs theirs)
- Timestamp of conflict
- Who made each change
- Option to restore old version

### 3. Change History per Record
**Location:** Student Details → History

**Features:**
- Timeline of all changes to this student
- Who changed what field
- When it was changed
- Old value → New value

---

## 🔍 Query Examples

### View Recent Changes
```sql
SELECT 
  timestamp,
  user_email,
  table_name,
  operation,
  changes
FROM audit_log
WHERE center_name = 'Nashik Hub'
ORDER BY timestamp DESC
LIMIT 50;
```

### View Conflicts
```sql
SELECT 
  timestamp,
  user_email,
  table_name,
  record_id,
  old_data,
  new_data
FROM audit_log
WHERE conflict_detected = TRUE
ORDER BY timestamp DESC;
```

### View Student History
```sql
SELECT 
  timestamp,
  user_email,
  operation,
  changes
FROM audit_log
WHERE table_name = 'students'
  AND record_id = '123'
ORDER BY timestamp DESC;
```

---

## ✅ Benefits

1. **Accountability** - Know who made every change
2. **Transparency** - See complete history
3. **Conflict Detection** - Automatically detect conflicts
4. **Conflict Resolution** - Clear strategy (last write wins)
5. **Audit Compliance** - Meet audit requirements
6. **Debugging** - Trace issues to specific changes
7. **Rollback** - Can restore old versions if needed

---

## 🚀 Implementation Steps

1. **Run SQL scripts** to add audit fields and create audit_log table
2. **Update models** to include audit fields
3. **Update sync service** to track user and detect conflicts
4. **Create audit log viewer** UI
5. **Test conflict scenarios**

---

## 📊 Example Audit Log Entry

```json
{
  "id": 1,
  "table_name": "students",
  "record_id": "123",
  "operation": "UPDATE",
  "user_email": "teacher@school.com",
  "user_name": "John Teacher",
  "center_name": "Nashik Hub",
  "timestamp": "2024-12-05T10:30:00Z",
  "old_data": {
    "name": "John Doe",
    "roll_no": "R001",
    "lessons_learned": ["Math: Addition"]
  },
  "new_data": {
    "name": "John Doe",
    "roll_no": "R001",
    "lessons_learned": ["Math: Addition", "Math: Fractions"]
  },
  "changes": {
    "lessons_learned": {
      "old": ["Math: Addition"],
      "new": ["Math: Addition", "Math: Fractions"]
    }
  },
  "conflict_detected": false
}
```

---

**This system provides complete visibility and control over all data changes!** 🔍✨
