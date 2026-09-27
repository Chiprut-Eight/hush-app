import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/secret.dart';
import '../widgets/secret_card.dart';
import 'package:hush_app/l10n/app_localizations.dart';

class SavedSecretsScreen extends StatelessWidget {
  final List<Secret> savedSecrets;
  final VoidCallback onUnsave;

  const SavedSecretsScreen({
    super.key,
    required this.savedSecrets,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: HushColors.bgPrimary,
        elevation: 0,
        title: Text(l10n.savedSecrets, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: savedSecrets.isEmpty
          ? Center(child: Text(l10n.noActiveSecrets, style: const TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: savedSecrets.length,
              itemBuilder: (context, index) {
                final secret = savedSecrets[index];
                return SecretCard(
                  key: ValueKey(secret.id),
                  secret: secret,
                  userPosition: null, // No position means no distance limit
                  onDelete: onUnsave, // Just triggers a rebuild in the parent
                );
              },
            ),
    );
  }
}
