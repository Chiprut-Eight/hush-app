import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        title: Text("התראות (Push)", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
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
                  title: const Text("אפשר התראות", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("כיבוי יבטל את כל ההתראות מהאפליקציה"),
                  activeColor: HushColors.textAccent,
                  value: user.notificationsEnabled,
                  onChanged: (value) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'notificationsEnabled': value});
                  },
                ),
                const Divider(),
                
                // Specific Notifications (only active if master is true)
                Opacity(
                  opacity: user.notificationsEnabled ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !user.notificationsEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, "סוגי התראות"),
                        
                        SwitchListTile(
                          title: const Text("האשש חדש מנעקבים"),
                          subtitle: const Text("כאשר משתמש שאתה עוקב אחריו מפרסם"),
                          activeColor: HushColors.textAccent,
                          value: user.notifyNewFollowerSecrets,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'notifyNewFollowerSecrets': value});
                          },
                        ),
                        
                        SwitchListTile(
                          title: const Text("עליית דרגה / האשש קבוצתי"),
                          subtitle: const Text("כאשר נפתחת אפשרות להאשש קבוצתי"),
                          activeColor: HushColors.textAccent,
                          value: user.notifyGroupUnlocks,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'notifyGroupUnlocks': value});
                          },
                        ),
                        
                        SwitchListTile(
                          title: const Text("עוקבים חדשים"),
                          subtitle: const Text("כאשר מישהו מתחיל לעקוב אחריך"),
                          activeColor: HushColors.textAccent,
                          value: user.notifyNewFollower,
                          onChanged: (value) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({'notifyNewFollower': value});
                          },
                        ),
                        
                        SwitchListTile(
                          title: const Text("תגובות ולייקים"),
                          subtitle: const Text("כאשר יש אינטראקציה עם האשש שלך"),
                          activeColor: HushColors.textAccent,
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
