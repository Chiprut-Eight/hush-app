import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/hush_icon_widget.dart';
import '../widgets/tutorial_popup.dart';
import '../screens/admin_screen.dart';

class HushDrawer extends StatelessWidget {
  const HushDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = auth.hushUser;

    return Drawer(
      backgroundColor: HushColors.bgPrimary,
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: HushColors.bgCard,
              border: Border(
                bottom: BorderSide(color: HushColors.borderSubtle, width: 1),
              ),
            ),
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                // Close Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: HushColors.textAccent, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo_hushhh.jpeg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'HUSH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Language Toggle
                ListTile(
                  leading: const HushIcon(HushIcons.feed, size: 22, color: HushColors.textAccent),
                  title: Text(l10n.language, style: const TextStyle(color: Colors.white)),
                  trailing: Text(
                    localeProvider.isHebrew ? 'עברית' : 'English',
                    style: const TextStyle(color: HushColors.textAccent, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => localeProvider.toggleLocale(),
                ),

                // Settings
                ListTile(
                  leading: const HushIcon(HushIcons.bell, size: 22, color: Colors.white70),
                  title: Text(l10n.settings, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settings)),
                    );
                  },
                ),

                const Divider(color: Colors.white10, indent: 16, endIndent: 16),

                // Legal
                ListTile(
                  leading: const Icon(Icons.description_outlined, size: 22, color: Colors.white70),
                  title: Text(l10n.termsOfService, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Open inner legal page or External URL
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, size: 22, color: Colors.white70),
                  title: Text(l10n.privacyPolicy, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Open inner legal page or External URL
                  },
                ),

                // Admin (only for specific UID)
                if (auth.firebaseUser?.uid == const String.fromEnvironment('ADMIN_UID', defaultValue: 'A30Br3OakdXF5BnfQFu5pryOsgy2')) ...[
                  const Divider(color: Colors.white10, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const HushIcon(HushIcons.shield, size: 22, color: Colors.orangeAccent),
                    title: Text(l10n.adminTitle, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                    },
                  ),
                ],

                const Divider(color: Colors.white10, indent: 16, endIndent: 16),

                // What is Hushhh? (Tutorial)
                ListTile(
                  leading: const Icon(Icons.info_outline, size: 22, color: HushColors.textAccent),
                  title: Text(l10n.drawer_what_is_hush, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => const TutorialPopup(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Footer / Logout
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (user != null) ...[
                  Text(
                    '${user.firstName} ${user.lastName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    auth.signOut();
                  },
                  icon: const HushIcon(HushIcons.logout, size: 20, color: HushColors.tierRed),
                  label: Text(
                    l10n.signOut,
                    style: const TextStyle(color: HushColors.tierRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: HushColors.tierRed.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
