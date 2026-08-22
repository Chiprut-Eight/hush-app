import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app locale (Hebrew/English) with persistence
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const _prefKey = 'app_language';

  Locale get locale => _locale;
  bool get isHebrew => _locale.languageCode == 'he';

  LocaleProvider() {
    _loadSavedLocale();
  }

  /// Load previously saved language from SharedPreferences
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved != _locale.languageCode) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  void toggleLocale() {
    _locale = _locale.languageCode == 'en' ? const Locale('he') : const Locale('en');
    _persistLocale();
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _persistLocale();
    notifyListeners();
  }

  /// Persist language choice to both local storage and Firestore
  Future<void> _persistLocale() async {
    // Save locally for instant restore on next app launch
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _locale.languageCode);

    // Save to Firestore for server-side notifications
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'language': _locale.languageCode,
      }).catchError((e) => debugPrint('[Locale] Failed to save language: $e'));
    }
  }
}
