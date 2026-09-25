import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../config/theme.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.hushUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationsSettingsTitle, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Master Switch
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.enableNotificationsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(AppLocalizations.of(context)!.enableNotificationsSub, style: const TextStyle(fontSize: 12)),
                  activeThumbColor: HushColors.textAccent,
                  value: user.notificationsEnabled,
                  onChanged: (value) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'notificationsEnabled': value});
                  },
                ),
                
                const Divider(height: 32),
                
                // Fine-grained Controls (disabled if master switch is off)
                Opacity(
                  opacity: user.notificationsEnabled ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !user.notificationsEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: Text(AppLocalizations.of(context)!.notifyNewFollowerSecretsTitle),
                          subtitle: Text(AppLocalizations.of(context)!.notifyNewFollowerSecretsSub, style: const TextStyle(fontSize: 12)),
                          activeThumbColor: HushColors.textAccent,
                          value: user.notifyNewFollowerSecrets,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'notifyNewFollowerSecrets': value});
                          },
                        ),
                        SwitchListTile(
                          title: Text(AppLocalizations.of(context)!.notifyGroupUnlocksTitle),
                          subtitle: Text(AppLocalizations.of(context)!.notifyGroupUnlocksSub, style: const TextStyle(fontSize: 12)),
                          activeThumbColor: HushColors.textAccent,
                          value: user.notifyGroupUnlocks,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'notifyGroupUnlocks': value});
                          },
                        ),
                        SwitchListTile(
                          title: Text(AppLocalizations.of(context)!.notifyNewFollowerTitle),
                          subtitle: Text(AppLocalizations.of(context)!.notifyNewFollowerSub, style: const TextStyle(fontSize: 12)),
                          activeThumbColor: HushColors.textAccent,
                          value: user.notifyNewFollower,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'notifyNewFollower': value});
                          },
                        ),
                        SwitchListTile(
                          title: Text(AppLocalizations.of(context)!.notifyInteractionsTitle),
                          subtitle: Text(AppLocalizations.of(context)!.notifyInteractionsSub, style: const TextStyle(fontSize: 12)),
                          activeThumbColor: HushColors.textAccent,
                          value: user.notifyInteractions,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'notifyInteractions': value});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
