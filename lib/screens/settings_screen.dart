import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import 'notifications_settings_screen.dart';
import 'change_username_screen.dart';
import '../widgets/title_setter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.hushUser;

    return TitleSetter(
      title: AppLocalizations.of(context)!.settingsMainTitle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.muteAppSoundsTitle),
                  subtitle: Text(AppLocalizations.of(context)!.muteAppSoundsSub, style: const TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.volume_off_outlined, color: HushColors.textAccent),
                  activeThumbColor: HushColors.textAccent,
                  value: user.appSoundsMuted,
                  onChanged: (value) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'appSoundsMuted': value});
                  },
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.notificationsSettingsTitle),
                  subtitle: Text(AppLocalizations.of(context)!.notificationsSettingsSub, style: const TextStyle(fontSize: 12)),
                  leading: const Icon(Icons.notifications_active_outlined, color: HushColors.textAccent),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()));
                  },
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.changeUsernameTitle),
                  leading: const Icon(Icons.edit_outlined, color: HushColors.textAccent),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeUsernameScreen()));
                  },
                ),
              ],
            ),
      ),
    );
  }
}
