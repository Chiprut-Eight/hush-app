import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../config/theme.dart';
import 'notifications_settings_screen.dart';
import 'change_username_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.hushUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader(context, "כללי"),
                
                // Mute Sounds Toggle
                SwitchListTile(
                  title: const Text("השתק צלילי אפליקציה"),
                  subtitle: const Text("ההשתקה חלה על צלילי ממשק, לא על האששים"),
                  secondary: const Icon(Icons.volume_off_outlined, color: HushColors.textAccent),
                  activeColor: HushColors.textAccent,
                  value: user.appSoundsMuted,
                  onChanged: (value) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'appSoundsMuted': value});
                  },
                ),
                
                const Divider(),
                _buildSectionHeader(context, "חשבון והתראות"),
                
                // Notifications
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: HushColors.textAccent),
                  title: const Text("התראות (Push)"),
                  trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black54),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()),
                    );
                  },
                ),
                
                // Change Username
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: HushColors.textAccent),
                  title: const Text("שינוי שם משתמש"),
                  trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black54),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangeUsernameScreen()),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }
}
