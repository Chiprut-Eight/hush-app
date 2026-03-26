import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

/// Profile screen — user info, published/saved secrets, sign out
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final user = auth.hushUser;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          // Language toggle
          TextButton(
            onPressed: () => localeProvider.toggleLocale(),
            child: Text(
              localeProvider.isHebrew ? 'EN' : 'עב',
              style: const TextStyle(
                color: HushColors.textAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User avatar and name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: HushColors.bgCard,
                  backgroundImage: auth.firebaseUser?.photoURL != null
                      ? NetworkImage(auth.firebaseUser!.photoURL!)
                      : null,
                  child: auth.firebaseUser?.photoURL == null
                      ? const Icon(Icons.person, size: 48, color: HushColors.textMuted)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  auth.firebaseUser?.displayName ?? 'Anonymous',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (user != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: HushColors.tierColor(user.tierLevel).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: HushColors.tierColor(user.tierLevel).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      l10n.tier(user.tierLevel),
                      style: TextStyle(
                        color: HushColors.tierColor(user.tierLevel),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Stats cards
          if (user != null) ...[
            _buildStatRow(l10n.publishedSecrets, '${user.totalPublished}'),
            _buildStatRow(l10n.savedSecrets, '${user.savedSecretIds.length}'),
            _buildStatRow(l10n.distinguished, '${user.distinguishedCount}'),
          ],

          const SizedBox(height: 32),

          // Sign out button
          OutlinedButton.icon(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout, color: HushColors.tierRed),
            label: Text(
              l10n.signOut,
              style: const TextStyle(color: HushColors.tierRed),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: HushColors.tierRed.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: HushColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HushColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: HushColors.textSecondary)),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: HushColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
