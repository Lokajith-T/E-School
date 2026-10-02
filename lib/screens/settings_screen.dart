import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text('Enable Notifications'.tr()),
            subtitle: Text('Receive app alerts and messages'.tr()),
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            secondary: const Icon(Icons.notifications_active),
          ),
          const Divider(),
          SwitchListTile(
            title: Text('Dark Mode'.tr()),
            subtitle: Text('Switch to a darker theme'.tr()),
            value: _darkModeEnabled,
            onChanged: (val) {
              setState(() => _darkModeEnabled = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Theme settings coming soon'.tr())),
              );
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('Language'.tr()),
            subtitle: Text(context.locale.languageCode == 'en' ? 'English' : 'தமிழ்'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (context.locale.languageCode == 'en') {
                context.setLocale(const Locale('ta'));
              } else {
                context.setLocale(const Locale('en'));
              }
            },
          ),
        ],
      ),
    );
  }
}
