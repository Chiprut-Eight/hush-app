import 'package:flutter/material.dart';

/// Manages the app locale (Hebrew/English) with persistence
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isHebrew => _locale.languageCode == 'he';

  void toggleLocale() {
    _locale = _locale.languageCode == 'en' ? const Locale('he') : const Locale('en');
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
