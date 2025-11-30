import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samadhan_app/providers/user_provider.dart';
import 'package:samadhan_app/providers/auth_provider.dart';
import 'package:samadhan_app/pages/login_page.dart';
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
  String? _selectedLanguageCode;

  final Map<String, String> _availableLanguages = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
  };

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.userSettings.name);
    _phoneNumberController = TextEditingController(text: userProvider.userSettings.phoneNumber);
    _selectedLanguageCode = userProvider.userSettings.language;
  }

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final updatedSettings = UserSettings(
        name: _nameController.text,
        phoneNumber: _phoneNumberController.text,
        language: _selectedLanguageCode!,
      );

      await userProvider.saveSettings(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account details saved successfully!')),
        );
        Navigator.pop(context);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountDetails),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 70, color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement profile photo upload
                      },
                      child: Text(l10n.changePhoto),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              Text(
                l10n.changePassword,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.oldPassword,
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.newPassword,
                  prefixIcon: const Icon(Icons.lock_open),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.confirmNewPassword,
                  prefixIcon: const Icon(Icons.lock_open),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.appLanguage,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveDetails,
                child: Text(l10n.saveDetails, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: _resetLocalData,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text(l10n.resetLocalData),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
