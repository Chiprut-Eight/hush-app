import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages the app locale (Hebrew/English) with persistence
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isHebrew => _locale.languageCode == 'he';

  void toggleLocale() {
    _locale = _locale.languageCode == 'en' ? const Locale('he') : const Locale('en');
    _saveLanguageToFirestore();
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _saveLanguageToFirestore();
    notifyListeners();
  }

  /// Persist language preference to Firestore for server-side notifications
  void _saveLanguageToFirestore() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'language': _locale.languageCode,
      }).catchError((e) => debugPrint('[Locale] Failed to save language: $e'));
    }
  }
}
