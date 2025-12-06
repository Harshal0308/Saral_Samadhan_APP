import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/pages/splash_screen.dart';
import 'package:samadhan_app/pages/login_page.dart';
import 'package:samadhan_app/pages/signup_page.dart';
import 'package:samadhan_app/pages/main_dashboard_page.dart';
import 'package:samadhan_app/pages/center_selection_page.dart';
import 'package:samadhan_app/providers/auth_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/export_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/notification_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/providers/event_provider.dart';
import 'package:samadhan_app/providers/schedule_provider.dart';
import 'package:samadhan_app/providers/reminder_provider.dart';
import 'package:samadhan_app/l10n/app_localizations.dart';

import 'package:samadhan_app/services/face_recognition_service.dart';
import 'package:samadhan_app/services/auth_service.dart';
import 'package:samadhan_app/theme/saral_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  // Initialize auth service
  await AuthService().initialize();
  
  // Initialize reminder service
  await ReminderProvider().initialize();
  
  await FaceRecognitionService().loadModel();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()..fetchStudents()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()..fetchAttendanceRecords()),
        ChangeNotifierProvider(create: (_) => VolunteerProvider()..fetchReports()),
        ChangeNotifierProvider(create: (context) => UserProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..loadNotifications()),
        ChangeNotifierProvider(create: (_) => OfflineSyncProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()..loadEvents()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..initialize()),
        ChangeNotifierProxyProvider<ReminderProvider, ScheduleProvider>(
          create: (_) => ScheduleProvider()..loadSchedules(),
          update: (_, reminderProvider, scheduleProvider) {
            scheduleProvider!.setReminderProvider(reminderProvider);
            return scheduleProvider;
          },
        ),
        Provider(create: (context) => ExportProvider(Provider.of<StudentProvider>(context, listen: false))),
      ],
      child: Consumer2<AuthProvider, UserProvider>(
        builder: (ctx, auth, userProvider, _) => MaterialApp(
          title: 'SARAL',
          theme: SaralTheme.light().copyWith(
            useMaterial3: true,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(userProvider.userSettings.language.toLowerCase().substring(0, 2)),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignupPage(),
          },
        ),
      ),
    );
  }
}

// Widget to handle authentication state and redirect accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, _) {
        // If user is authenticated
        if (authProvider.isAuthenticated) {
          // Check if center is selected
          if (userProvider.userSettings.selectedCenter != null &&
              userProvider.userSettings.selectedCenter!.isNotEmpty) {
            // Go directly to dashboard
            return const MainDashboardPage();
          } else {
            // Need to select center first
            return const CenterSelectionPage();
          }
        }
        // Not authenticated, show login
        return const LoginPage();
      },
    );
  }
}
