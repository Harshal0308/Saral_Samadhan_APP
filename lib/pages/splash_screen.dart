import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/auth_provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/pages/login_page.dart';
import 'package:samadhan_app/pages/main_dashboard_page.dart';
import 'package:samadhan_app/pages/center_selection_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for a minimum display time for splash screen
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Wait for auth provider to initialize
    int attempts = 0;
    while (!authProvider.isInitialized && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    print('\n🔐 AUTHENTICATION CHECK');
    print('═══════════════════════════════════════════════════════');
    print('   Auth initialized: ${authProvider.isInitialized}');
    print('   Current user: ${authProvider.currentUser?.email ?? "None"}');
    print('   Current teacher: ${authProvider.currentTeacher?.name ?? "None"}');
    print('   Is authenticated: ${authProvider.isAuthenticated}');
    print('   Selected center: ${userProvider.userSettings.selectedCenter ?? "None"}');
    print('═══════════════════════════════════════════════════════\n');

    if (!mounted) return;

    Widget nextScreen;

    // Check if user is authenticated and has valid teacher profile
    if (authProvider.isAuthenticated) {
      print('✅ User is authenticated - checking center selection...');
      
      // Check if center is selected
      if (userProvider.userSettings.selectedCenter != null &&
          userProvider.userSettings.selectedCenter!.isNotEmpty) {
        print('✅ Center selected: ${userProvider.userSettings.selectedCenter}');
        print('🏠 Navigating to Main Dashboard');
        nextScreen = const MainDashboardPage();
      } else {
        print('⚠️ No center selected');
        print('🏢 Navigating to Center Selection');
        nextScreen = const CenterSelectionPage();
      }
    } else {
      print('❌ User not authenticated');
      print('🔑 Navigating to Login Page');
      nextScreen = const LoginPage();
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => nextScreen),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B5FFF), Color(0xFF3B5FBF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App name
              const Text(
                'SARAL',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              const Text(
                'NGO Coordination Platform',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 60),
              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
