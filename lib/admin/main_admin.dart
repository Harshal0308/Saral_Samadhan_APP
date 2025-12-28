import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/services/auth_service.dart';
import 'package:samadhan_app/theme/saral_theme.dart';
import 'package:samadhan_app/admin/providers/admin_auth_provider.dart';
import 'package:samadhan_app/admin/providers/admin_data_provider.dart';
import 'package:samadhan_app/admin/pages/admin_login_page.dart';
import 'package:samadhan_app/admin/pages/admin_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    // For web, the file path needs to be relative to assets
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Loaded .env file');
  } catch (e) {
    debugPrint('⚠️ Could not load .env file: $e');
    // Try loading from assets path for web
    try {
      await dotenv.load(fileName: "assets/.env");
      debugPrint('✅ Loaded .env from assets');
    } catch (e2) {
      debugPrint('⚠️ Could not load .env from assets: $e2');
    }
  }
  
  // Get Supabase credentials
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  debugPrint('🔗 Supabase URL: $supabaseUrl');
  debugPrint('🔑 Anon Key length: ${supabaseAnonKey.length}');
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('❌ ERROR: Supabase credentials not found!');
    debugPrint('Available env vars: ${dotenv.env.keys.toList()}');
  }
  
  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kIsWeb, // Enable debug mode on web
    );
    debugPrint('✅ Supabase initialized');
  } catch (e) {
    debugPrint('❌ Supabase init error: $e');
  }
  
  // Initialize auth service
  try {
    await AuthService().initialize();
    debugPrint('✅ Auth service initialized');
  } catch (e) {
    debugPrint('⚠️ Auth service init error: $e');
  }
  
  runApp(const AdminPortalApp());
}

class AdminPortalApp extends StatelessWidget {
  const AdminPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminDataProvider()),
      ],
      child: Consumer<AdminAuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'SARAL Admin Portal',
          debugShowCheckedModeBanner: false,
          theme: SaralTheme.light().copyWith(useMaterial3: true),
          home: auth.isAuthenticated 
              ? const AdminDashboardPage() 
              : const AdminLoginPage(),
        ),
      ),
    );
  }
}
