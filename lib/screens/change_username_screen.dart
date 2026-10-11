import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

import '../widgets/title_setter.dart';

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  /// Max visible characters so the name isn't truncated on the Hushhh card header.
  static const int maxNameLength = 20;

  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().hushUser;
    if (user != null && user.displayName != null) {
      _controller.text = user.displayName!;
    }
  }

  bool _canChangeUsername() {
    final user = context.read<AuthProvider>().hushUser;
    if (user == null) return false;
    if (user.lastUsernameChange == null) return true;

    final daysSinceLastChange = DateTime.now().difference(user.lastUsernameChange!).inDays;
    return daysSinceLastChange >= 180;
  }

  String _getTimeRemaining(BuildContext context) {
    final user = context.read<AuthProvider>().hushUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null || user.lastUsernameChange == null) return "";
    
    final daysSinceLastChange = DateTime.now().difference(user.lastUsernameChange!).inDays;
    final daysLeft = 180 - daysSinceLastChange;
    return l10n.usernameChangeWait(daysLeft);
  }

  Future<void> _saveUsername() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.hushUser;
    final firebaseUser = authProvider.firebaseUser;
    if (user == null || firebaseUser == null) return;
    
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    // Collapse repeated whitespace so first/last split is clean
    final parts = _controller.text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final newName = parts.join(' ');
    if (newName.isEmpty) {
      setState(() => _error = l10n.usernameEmptyError);
      return;
    }
    if (newName.length < 3) {
      setState(() => _error = l10n.usernameLengthError);
      return;
    }
    if (newName.length > maxNameLength) {
      setState(() => _error = isHe
          ? 'השם יכול להכיל עד $maxNameLength תווים'
          : 'Name can be up to $maxNameLength characters');
      return;
    }

    // The backend (secrets, comments, notifications) and ensureUserProfile derive
    // the display name from firstName + lastName, so those must be updated too —
    // otherwise the change is not propagated and gets reverted on next login.
    final firstName = parts.first;
    final lastName = parts.skip(1).join(' ');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Update Firebase Auth
      await firebaseUser.updateDisplayName(newName);
      
      // Update Firestore (the onUserProfileUpdate Cloud Function then syncs
      // comments and notifies followers about the name change)
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(user.uid).update({
        'displayName': newName,
        'firstName': firstName,
        'lastName': lastName,
        'searchName': newName.toLowerCase(),
        'lastUsernameChange': FieldValue.serverTimestamp(),
      });

      // Immediately update the name on all of the user's Hushhh
      // (the Cloud Function does this too; this makes it instant on the client)
      try {
        final secretsSnap = await firestore
            .collection('secrets')
            .where('creatorId', isEqualTo: user.uid)
            .get();
        const chunkSize = 400;
        for (var i = 0; i < secretsSnap.docs.length; i += chunkSize) {
          final batch = firestore.batch();
          for (final doc in secretsSnap.docs.skip(i).take(chunkSize)) {
            batch.update(doc.reference, {'creatorName': newName});
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Failed to update creatorName on secrets: $e');
      }

      await authProvider.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.usernameUpdated)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = l10n.usernameUpdateError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canChange = _canChangeUsername();
    final l10n = AppLocalizations.of(context)!;

    return TitleSetter(
      title: l10n.changeUsernameTitle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.newUsernameTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: canChange,
              maxLength: maxNameLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                final isHe = Localizations.localeOf(context).languageCode == 'he';
                final remaining = (maxLength ?? maxNameLength) - currentLength;
                return Text(
                  isHe
                      ? 'נותרו ${remaining < 0 ? 0 : remaining} תווים ($currentLength/${maxLength ?? maxNameLength})'
                      : '${remaining < 0 ? 0 : remaining} characters left ($currentLength/${maxLength ?? maxNameLength})',
                  style: TextStyle(
                    color: HushColors.textSecondary.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                );
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: HushColors.textAccent, width: 2),
                ),
                hintText: l10n.enterYourName,
              ),
            ),
            if (canChange)
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 15,
                      color: HushColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'he'
                            ? 'לתשומת ליבך, שינוי השם הוא קבוע לחצי השנה הקרובה ליום השינוי'
                            : 'Please note: Your new username will remain fixed for the next 6 months from the date of change.',
                        style: TextStyle(
                          color: HushColors.textSecondary.withValues(alpha: 0.75),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (!canChange)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.usernameChangeLimit(_getTimeRemaining(context)),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canChange && !_isLoading ? _saveUsername : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HushColors.textAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.saveNewName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }
}
