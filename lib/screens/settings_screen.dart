import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_reporting/providers/app_provider.dart';
import 'package:safe_reporting/services/localization_service.dart';
import 'package:safe_reporting/services/auth_service.dart';
import 'package:safe_reporting/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emergencyNotifications = true;
  bool _messageNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _emergencyNotifications = prefs.getBool('emergencyNotifications') ?? true;
      _messageNotifications = prefs.getBool('messageNotifications') ?? true;
    });
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance'),
          _buildThemeSelector(appProvider),
          _buildLanguageSelector(appProvider),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          _buildNotificationSettings(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Privacy & Security'),
          _buildPrivacySettings(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildAboutSection(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Account'),
          _buildAccountSection(authService),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(AppProvider appProvider) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.palette),
        title: const Text('Theme'),
        subtitle: Text(_getThemeName(appProvider.themeMode)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _showThemeDialog(appProvider);
        },
      ),
    );
  }

  Widget _buildLanguageSelector(AppProvider appProvider) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.language),
        title: const Text('Language'),
        subtitle: Text(LocalizationService.getLanguageName(appProvider.locale.languageCode)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _showLanguageDialog(appProvider);
        },
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      children: [
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive push notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveNotificationSetting('notificationsEnabled', value);
            },
          ),
        ),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.priority_high),
            title: const Text('Emergency Notifications'),
            subtitle: const Text('High priority notifications for emergencies'),
            value: _emergencyNotifications,
            onChanged: _notificationsEnabled ? (value) {
              setState(() {
                _emergencyNotifications = value;
              });
              _saveNotificationSetting('emergencyNotifications', value);
            } : null,
          ),
        ),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.message),
            title: const Text('Message Notifications'),
            subtitle: const Text('Notifications for new messages'),
            value: _messageNotifications,
            onChanged: _notificationsEnabled ? (value) {
              setState(() {
                _messageNotifications = value;
              });
              _saveNotificationSetting('messageNotifications', value);
            } : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy Policy'),
            subtitle: const Text('View our privacy policy'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showPrivacyPolicy();
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Data Encryption'),
            subtitle: const Text('All your data is encrypted'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.visibility_off),
            title: const Text('Anonymous Reporting'),
            subtitle: const Text('Your identity is protected'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help using the app'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showHelpDialog();
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            subtitle: const Text('Help us improve the app'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showFeedbackDialog();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(AuthService authService) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Anonymous ID'),
            subtitle: Text(authService.anonymousId?.substring(0, 8) ?? 'Loading...'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Sign Out', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Clear all local data'),
            onTap: () {
              _showSignOutDialog(authService);
            },
          ),
        ),
      ],
    );
  }

  String _getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeName(mode)),
              value: mode,
              groupValue: appProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  appProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocalizationService.supportedLocales.map((locale) {
            return RadioListTile<Locale>(
              title: Text(LocalizationService.getLanguageName(locale.languageCode)),
              value: locale,
              groupValue: appProvider.locale,
              onChanged: (value) {
                if (value != null) {
                  appProvider.setLocale(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'SafeReporting is committed to protecting your privacy and anonymity.\n\n'
            '• All reports are encrypted end-to-end\n'
            '• Your identity is never stored or transmitted\n'
            '• Anonymous IDs are used for communication\n'
            '• Data is stored securely and deleted after resolution\n'
            '• No personal information is collected\n\n'
            'For more information, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use SafeReporting:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Tap "New Report" to create a report'),
              Text('2. Select the appropriate category'),
              Text('3. Fill in the details anonymously'),
              Text('4. Set urgency level if needed'),
              Text('5. Submit your report securely'),
              SizedBox(height: 16),
              Text(
                'Your reports are completely anonymous and encrypted.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Help us improve SafeReporting by sharing your feedback:'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                hintText: 'Your feedback...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would typically send the feedback to your backend
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'This will clear all local data and sign you out. '
          'Your submitted reports will remain secure and anonymous.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await authService.signOut();
                if (mounted) {
                  Navigator.of(context).pop();
                  // Navigate back to splash/login screen
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to sign out. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
