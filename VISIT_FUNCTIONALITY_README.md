# Visit Functionality Implementation

## Overview
The Volunteer page has been renamed to "Volunteer & Visitor" and now includes visit tracking functionality alongside existing volunteer management features. Visit data is also integrated into monthly reports.

## Changes Made

### 1. Navigation Updates
- **Main Dashboard**: Updated tile from "Volunteers" to "Volunteer & Visitor"
- **Volunteer Options Page**: Renamed from "Volunteer Reports" to "Volunteer & Visitor"

### 2. New Visit Features
- **Record Visit**: Simple form to log visitor information
- **View Visits**: List of all recorded visits for the center
- **Monthly Reports Integration**: Visit data now appears in monthly reports

### 3. Visit Form Fields
- **Name**: Text input for visitor name (required)
- **Contact Number**: 10-digit phone number input (required, validated)
- **Purpose of Visit**: Text area for visit purpose (required)
- **Auto-captured**: Visit date and timestamp

### 4. Monthly Reports Integration
- **UI Display**: Visits section shows actual recorded visits with 3 columns:
  - Visitor/Donor Name
  - Contact No.
  - Purpose
- **PDF Export**: Same 3-column structure in PDF reports
- **Empty State**: Shows "No visits recorded for this month" when no data
- **Data Filtering**: Only shows visits from the selected month

### 5. Database Schema
New `visits` table with the following structure:
```sql
CREATE TABLE public.visits (
    id bigserial PRIMARY KEY,
    name text NOT NULL,
    contact text NOT NULL,
    purpose text NOT NULL,
    visit_date timestamp with time zone NOT NULL,
    timestamp timestamp with time zone DEFAULT now(),
    center_name text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
```

### 6. Files Added/Modified

#### New Files:
- `lib/models/visit.dart` - Visit data model
- `lib/services/visit_service.dart` - Visit database operations
- `lib/pages/visit_page.dart` - Visit recording form
- `lib/pages/visits_list_page.dart` - Visit records display
- `visits_database_setup.sql` - Database setup script

#### Modified Files:
- `lib/pages/volunteer_options_page.dart` - Added visit options
- `lib/pages/main_dashboard_page.dart` - Updated tile name
- `lib/services/monthly_report_service.dart` - Added visit data fetching
- `lib/pages/monthly_reports_page.dart` - Updated visits display and PDF generation
- `volunteer_database_setup.sql` - Added visits table

## Functional Rules Implemented

1. **No Name Uniqueness**: Each visit is saved as a new record regardless of name
2. **Simple Form**: Only 3 required fields (name, contact, purpose)
3. **Contact Validation**: Exactly 10 digits required
4. **Auto-timestamps**: Visit date and timestamp automatically captured
5. **Center-based**: Visits are tied to the user's selected center
6. **No Attendance Logic**: Visits are independent records, no linking with volunteer data
7. **Monthly Filtering**: Only visits from the selected month appear in reports

## Usage

### To Record a Visit:
1. Navigate to "Volunteer & Visitor" from main dashboard
2. Tap "Record Visit" under Visitor Management section
3. Fill in visitor name, 10-digit contact number, and purpose
4. Tap "Record Visit" to save

### To View Visits:
1. Navigate to "Volunteer & Visitor" from main dashboard
2. Tap "View Visits" under Visitor Management section
3. See all recorded visits with date, time, and details
4. Pull to refresh for latest data

### In Monthly Reports:
1. Generate monthly report as usual
2. Visit data automatically appears in the "Visits" section
3. Shows 3 columns: Visitor/Donor Name, Contact No., Purpose
4. Empty state message if no visits recorded for the month
5. Same structure in both UI and PDF export

## Database Setup

Run the `visits_database_setup.sql` script in your Supabase SQL editor to create the necessary table and permissions.

## Security

- Row Level Security (RLS) enabled
- Teachers can only access visits from their assigned center
- Proper authentication required for all operations