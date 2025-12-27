# Volunteer Management System Setup Guide

This guide will help you set up the new volunteer management system that automatically tracks volunteer attendance and provides autocomplete functionality.

## Features

✅ **Automatic Volunteer Creation**: Volunteers are created automatically when they submit daily reports  
✅ **Attendance Tracking**: Attendance count increments automatically for each report submission  
✅ **Autocomplete**: Volunteer names are suggested with attendance history  
✅ **Monthly Reports**: Shows volunteer names and attendance counts  
✅ **Cloud Sync**: All volunteer data syncs to Supabase automatically  

## Database Setup

### Step 1: Run the SQL Setup

Execute the SQL commands in `volunteer_database_setup.sql` in your Supabase SQL editor:

1. Open your Supabase project dashboard
2. Go to SQL Editor
3. Copy and paste the contents of `volunteer_database_setup.sql`
4. Click "Run" to execute all commands

This will create:
- `volunteers` table to store unique volunteer information
- Automatic triggers to manage volunteer records
- RLS policies for security
- Helper functions for autocomplete and reports

### Step 2: Sync Existing Data (Optional)

If you have existing volunteer reports, run this command to populate the volunteers table:

```sql
SELECT sync_existing_volunteer_data();
```

This will analyze your existing `volunteer_reports` table and create volunteer records with correct attendance counts.

## Code Integration

### Step 3: Add Provider to Main App

Add the `VolunteerManagementProvider` to your main app providers:

```dart
// In your main.dart or app.dart
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(create: (_) => VolunteerManagementProvider()),
  ],
  child: MyApp(),
)
```

### Step 4: Update Existing Pages

The following pages have been updated to use the new system:

1. **Volunteer Daily Report Page** - Now uses autocomplete for volunteer names
2. **Volunteer Test Report Page** - Now uses autocomplete for volunteer names  
3. **Monthly Reports Page** - Now shows volunteer attendance from the new system

### Step 5: Navigation (Optional)

Add the new volunteer monthly report page to your navigation:

```dart
// Add to your drawer or navigation
ListTile(
  leading: Icon(Icons.people),
  title: Text('Volunteer Reports'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VolunteerMonthlyReportPage()),
    );
  },
),
```

## How It Works

### Automatic Volunteer Management

1. **When a volunteer submits a daily report:**
   - System checks if volunteer exists for that center
   - If new: Creates volunteer record with attendance = 1
   - If existing: Increments attendance count by 1
   - Updates last report date

2. **Autocomplete functionality:**
   - Shows volunteers sorted by attendance (most active first)
   - Displays attendance count and last report date
   - Works offline with local data, online with cloud data

3. **Monthly reports:**
   - Pulls data from the `volunteers` table
   - Shows accurate attendance counts
   - Includes volunteer statistics

### Database Structure

```sql
-- Volunteers table
CREATE TABLE volunteers (
    id bigint PRIMARY KEY,
    name text NOT NULL,
    center_name text NOT NULL,
    attendance_count integer DEFAULT 1,
    first_report_date date NOT NULL,
    last_report_date date NOT NULL,
    created_at timestamp DEFAULT now(),
    updated_at timestamp DEFAULT now(),
    UNIQUE(name, center_name)
);
```

### API Functions

- `get_volunteer_suggestions(center_name)` - Returns volunteers for autocomplete
- `get_monthly_volunteer_report(center_name, month)` - Returns monthly attendance data
- `sync_existing_volunteer_data()` - Migrates existing data

## Testing

### Test the System

1. **Submit a volunteer report** with a new volunteer name
2. **Check the volunteers table** - should see new record with attendance = 1
3. **Submit another report** with the same volunteer name
4. **Check attendance count** - should be incremented to 2
5. **Test autocomplete** - volunteer name should appear in suggestions
6. **View monthly report** - should show correct attendance count

### Verify Data

```sql
-- Check volunteers table
SELECT * FROM volunteers ORDER BY attendance_count DESC;

-- Check monthly report function
SELECT * FROM get_monthly_volunteer_report('Your Center Name', CURRENT_DATE);

-- Check autocomplete function  
SELECT * FROM get_volunteer_suggestions('Your Center Name');
```

## Troubleshooting

### Common Issues

1. **Volunteers not appearing in autocomplete:**
   - Check if center name matches exactly
   - Verify RLS policies allow access
   - Check network connectivity

2. **Attendance not incrementing:**
   - Verify trigger is installed: `SELECT * FROM pg_trigger WHERE tgname = 'trigger_manage_volunteer_on_report';`
   - Check volunteer_reports table has volunteer_name field

3. **Monthly report empty:**
   - Ensure volunteers exist for the selected center and month
   - Check date filters in the query

### Debug Queries

```sql
-- Check if triggers are working
SELECT * FROM volunteers WHERE name = 'Test Volunteer';

-- Check recent volunteer reports
SELECT volunteer_name, center_name, created_at 
FROM volunteer_reports 
ORDER BY created_at DESC 
LIMIT 10;

-- Test functions manually
SELECT get_volunteer_suggestions('Your Center Name');
```

## Benefits

✅ **No Manual Registration**: Volunteers are created automatically  
✅ **Accurate Attendance**: Counts every report submission  
✅ **Better UX**: Autocomplete makes data entry faster  
✅ **Consistent Data**: Single source of truth for volunteer information  
✅ **Offline Support**: Works offline and syncs when online  
✅ **NGO Friendly**: Perfect for volunteer-based organizations  

The system is now ready to use! Volunteers will be managed automatically as they submit reports, and you'll have accurate attendance tracking and reporting.