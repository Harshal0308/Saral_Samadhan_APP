import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/auth_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/services/cloud_sync_service.dart';
import 'package:samadhan_app/pages/login_page.dart';
import 'package:samadhan_app/pages/change_password_page.dart';
import 'package:samadhan_app/l10n/app_localizations.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  String? _selectedLanguageCode;
  String? _selectedCenter;
  String? _teacherCenter;
  bool _isLoading = true;

  final Map<String, String> _availableLanguages = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
  };

  // Centers will be dynamically loaded from StudentProvider
  List<String> _availableCenters = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      
      // Use auth data directly - don't query teachers table
      String teacherName = userProvider.userSettings.name.isNotEmpty 
          ? userProvider.userSettings.name 
          : (currentUser?.email?.split('@')[0] ?? 'Teacher');
      String teacherPhone = userProvider.userSettings.phoneNumber;
      String teacherEmail = currentUser?.email ?? '';
      _teacherCenter = userProvider.userSettings.selectedCenter;

      _nameController = TextEditingController(text: teacherName);
      _phoneNumberController = TextEditingController(text: teacherPhone);
      _emailController = TextEditingController(text: teacherEmail);
      _selectedLanguageCode = userProvider.userSettings.language;
      _selectedCenter = _teacherCenter;

      // Fetch centers from Supabase centers table
      try {
        final response = await Supabase.instance.client
            .from('centers')
            .select('name')
            .order('name');
        
        _availableCenters = (response as List)
            .map((center) => center['name'] as String)
            .toList();
      } catch (e) {
        print('Error fetching centers: $e');
        // Fallback to empty list if fetch fails
        _availableCenters = [];
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading profile: $e');
      // Initialize with empty controllers to prevent crash
      _nameController = TextEditingController();
      _phoneNumberController = TextEditingController();
      _emailController = TextEditingController();
      _selectedLanguageCode = 'en';
      _availableCenters = [];
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Check if center has changed
      final bool centerChanged = _teacherCenter != _selectedCenter;
      
      final updatedSettings = UserSettings(
        name: _nameController.text,
        phoneNumber: _phoneNumberController.text,
        language: _selectedLanguageCode!,
        selectedCenter: _selectedCenter,
      );

      await userProvider.saveSettings(updatedSettings);

      // If center changed, trigger sync to load new center's data
      if (centerChanged && _selectedCenter != null && _selectedCenter!.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Center changed. Syncing data...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Trigger sync for the new center
        await _syncNewCenterData(_selectedCenter!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(centerChanged 
              ? 'Account details saved and data synced!' 
              : 'Account details saved successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _syncNewCenterData(String newCenterName) async {
    try {
      final offlineProvider = Provider.of<OfflineSyncProvider>(context, listen: false);
      
      // Only sync if online
      if (!offlineProvider.isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Offline - Data will sync when you go online'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
      final cloudSyncService = CloudSyncService();

      // Sync data for the new center
      await cloudSyncService.fullSyncForCenter(
        newCenterName,
        studentProvider,
        attendanceProvider,
        volunteerProvider,
      );

      // Refresh providers after sync
      await studentProvider.fetchStudents();
      await attendanceProvider.fetchAttendanceRecords();
      await volunteerProvider.fetchReports();
    } catch (e) {
      print('❌ Error syncing new center data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Sync failed: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _resetLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.resetLocalData),
          content: const Text('Are you sure you want to reset all local data? This action cannot be undone and will log you out.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await userProvider.resetAllLocalData();
      authProvider.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.accountDetails),
          backgroundColor: const Color(0xFF5B5FFF),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountDetails),
        backgroundColor: const Color(0xFF5B5FFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF5B5FFF), width: 3),
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFFE6F0FF),
                        child: Icon(Icons.person, size: 60, color: Color(0xFF5B5FFF)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Personal Information section
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),
              // Security section
              Text(
                'Security',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                },
                icon: const Icon(Icons.lock),
                label: Text(l10n.changePassword),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 28),
              // Center & Language section
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select Your Center',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Center',
                  prefixIcon: const Icon(Icons.location_city),
                ),
                value: (_availableCenters.contains(_selectedCenter)) ? _selectedCenter : null,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCenter = newValue;
                    });
                  }
                },
                items: _availableCenters.toSet().toList().map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appLanguage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.selectLanguage,
                  prefixIcon: const Icon(Icons.language),
                ),
                value: _selectedLanguageCode,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguageCode = newValue;
                      Provider.of<UserProvider>(context, listen: false).updateLanguage(newValue);
                    });
                  }
                },
                items: _availableLanguages.entries.map<DropdownMenuItem<String>>((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              // Action buttons
              ElevatedButton(
                onPressed: _saveDetails,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFF5B5FFF),
                ),
                child: Text(l10n.saveDetails, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout? You will need to login again.'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.logout();

                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resetLocalData,
                child: Text(
                  l10n.resetLocalData,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
