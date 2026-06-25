import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hush_icon_widget.dart';
import '../widgets/tutorial_popup.dart';
import '../screens/admin_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_service_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analytics_service.dart';

class HushDrawer extends StatelessWidget {
  const HushDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.hushUser;
    final theme = Theme.of(context);
    final isDark = themeProvider.isDarkMode;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header — adaptive height for landscape
            Container(
              padding: EdgeInsets.symmetric(
                vertical: isLandscape ? 8 : 16,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? HushColors.bgCard : HushColors.bgSecondaryLight,
                border: Border(
                  bottom: BorderSide(color: isDark ? HushColors.borderSubtle : HushColors.borderLightMode, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // App Logo
                  Container(
                    width: isLandscape ? 40 : 64,
                    height: isLandscape ? 40 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: HushColors.textAccent, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo_hushhh2.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HUSH',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: isLandscape ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  // Close Button
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Menu Items — scrollable
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Language Toggle
                  ListTile(
                    leading: const HushIcon(HushIcons.feed, size: 22, color: HushColors.textAccent),
                    title: Text(l10n.language, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    trailing: Text(
                      localeProvider.isHebrew ? 'English' : 'Hebrew',
                      style: const TextStyle(color: HushColors.textAccent, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      localeProvider.toggleLocale();
                      AnalyticsService().logLanguageChanged(localeProvider.isHebrew ? 'he' : 'en');
                      AnalyticsService().logDrawerAction('language');
                    },
                  ),

                  // Invite Friends
                  ListTile(
                    leading: Icon(Icons.person_add_alt_1_outlined, size: 22, color: isDark ? Colors.white70 : Colors.black54),
                    title: Text(l10n.inviteFriends, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    onTap: () {
                      Navigator.pop(context);
                      AnalyticsService().logDrawerAction('invite');
                      AnalyticsService().logShareApp('drawer');
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Share.share(l10n.shareAppText);
                      });
                    },
                  ),

                  // Settings
                  ListTile(
                    leading: HushIcon(HushIcons.bell, size: 22, color: isDark ? Colors.white70 : Colors.black54),
                    title: Text(l10n.settings, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    onTap: () {
                      Navigator.pop(context);
                      AnalyticsService().logDrawerAction('settings');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.settings)),
                      );
                    },
                  ),

                  Divider(color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),

                  // Legal
                  ListTile(
                    leading: Icon(Icons.description_outlined, size: 22, color: isDark ? Colors.white70 : Colors.black54),
                    title: Text(l10n.termsOfService, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    onTap: () {
                      Navigator.pop(context);
                      AnalyticsService().logDrawerAction('terms');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, size: 22, color: isDark ? Colors.white70 : Colors.black54),
                    title: Text(l10n.privacyPolicy, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    onTap: () {
                      Navigator.pop(context);
                      AnalyticsService().logDrawerAction('privacy');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                    },
                  ),

                  // Admin (only for specific UID)
                  if (auth.firebaseUser?.uid == const String.fromEnvironment('ADMIN_UID', defaultValue: 'A30Br3OakdXF5BnfQFu5pryOsgy2')) ...[
                    Divider(color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const HushIcon(HushIcons.shield, size: 22, color: Colors.orangeAccent),
                      title: Text(l10n.adminTitle, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      onTap: () {
                        Navigator.pop(context);
                        AnalyticsService().logDrawerAction('admin');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                      },
                    ),
                  ],

                  Divider(color: isDark ? Colors.white10 : Colors.black12, indent: 16, endIndent: 16),

                  // What is Hushhh? (Tutorial)
                  ListTile(
                    leading: const Icon(Icons.info_outline, size: 22, color: HushColors.textAccent),
                    title: Text(l10n.drawer_what_is_hush, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      AnalyticsService().logDrawerAction('tutorial');
                      AnalyticsService().logTutorialStarted(source: 'drawer');
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
              padding: EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: isLandscape ? 8.0 : 24.0,
              ),
              child: Column(
                children: [
                  if (user != null && !isLandscape) ...[
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      AnalyticsService().logSignOut();
                      auth.signOut();
                    },
                    icon: const HushIcon(HushIcons.logout, size: 20, color: HushColors.tierRed),
                    label: Text(
                      l10n.signOut,
                      style: const TextStyle(color: HushColors.tierRed),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: HushColors.tierRed.withValues(alpha: 0.5)),
                      padding: EdgeInsets.symmetric(
                        vertical: isLandscape ? 8 : 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
