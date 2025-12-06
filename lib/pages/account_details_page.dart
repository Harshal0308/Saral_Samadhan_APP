import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/auth_provider.dart';
import 'package:samadhan_app/providers/student_provider.dart';
import 'package:samadhan_app/providers/attendance_provider.dart';
import 'package:samadhan_app/providers/volunteer_provider.dart';
import 'package:samadhan_app/providers/offline_sync_provider.dart';
import 'package:samadhan_app/providers/export_provider.dart';
import 'package:samadhan_app/services/cloud_sync_service.dart';
import 'package:samadhan_app/pages/login_page.dart';
import 'package:samadhan_app/pages/change_password_page.dart';
import 'package:samadhan_app/pages/audit_log_page.dart'; // NEW: Audit Log
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.accountDetails,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFF8B5CF6),
                          child: Text(
                            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'R',
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Profile Photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Form Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFF8B5CF6), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        hintText: '+91 98765 43210',
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF6B7280)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'your.email@example.com',
                        prefixIcon: const Icon(Icons.email, color: Color(0xFF6B7280)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge, color: Color(0xFF6B7280)),
                          const SizedBox(width: 12),
                          Text(
                            'Volunteer',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _saveDetails,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(l10n.saveDetails, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            // Additional Options (hidden in simple view, keep logic)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Center Selection (hidden in card)
                  if (_availableCenters.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Center',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
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
                  const SizedBox(height: 12),
                  // Language Selection
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.selectLanguage,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
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
                  const SizedBox(height: 16),
                  // Change Password Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                      );
                    },
                    icon: const Icon(Icons.lock_outline),
                    label: Text(l10n.changePassword),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Hidden management buttons (keep logic)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AuditLogPage()),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View Audit Trail'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Clean Up Old Exports'),
                            content: const Text(
                              'This will delete exported files older than 30 days. Continue?'
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                              TextButton(
                                child: const Text('Clean Up', style: TextStyle(color: Colors.orange)),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed == true) {
                        final studentProvider = Provider.of<StudentProvider>(context, listen: false);
                        final exportProvider = ExportProvider(studentProvider);
                        
                        final deletedCount = await exportProvider.cleanupOldExports(retentionDays: 30);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Cleaned up $deletedCount old export files'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Clean Up Old Exports'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete All Exports'),
                            content: const Text(
                              'This will permanently delete ALL exported files. Continue?'
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                              TextButton(
                                child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed == true) {
                        final studentProvider = Provider.of<StudentProvider>(context, listen: false);
                        final exportProvider = ExportProvider(studentProvider);
                        
                        final deletedCount = await exportProvider.deleteAllExports();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🗑️ Deleted all $deletedCount export files'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete All Exports'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
