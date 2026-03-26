import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Create screen — create text or voice secrets
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createTitle)),
      body: const Center(
        child: Text('🤫', style: TextStyle(fontSize: 64)),
      ),
    );
  }
}
