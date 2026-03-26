// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'HUSH';

  @override
  String get loginTitle => 'ברוכים הבאים ל-HUSH';

  @override
  String get loginSubtitle => 'הרשת החברתית הגיאו-אקוסטית';

  @override
  String get signInWithGoogle => 'התחברות עם Google';

  @override
  String get signInWithApple => 'התחברות עם Apple';

  @override
  String get feedTitle => 'סודות בקרבת מקום';

  @override
  String get feedEmpty => 'אין סודות בסביבה... הסתובב כדי לגלות לחישות נסתרות';

  @override
  String get feedLoading => 'מאזין לסודות...';

  @override
  String get mapTitle => 'מפת הד';

  @override
  String get createTitle => 'הטמן סוד';

  @override
  String get profileTitle => 'פרופיל';

  @override
  String get adminTitle => 'פאנל ניהול';

  @override
  String get secretPlaceholder => 'כתוב את הסוד שלך... (עד 140 תווים)';

  @override
  String get recordVoice => 'הקלט סוד קולי';

  @override
  String get stopRecording => 'עצור הקלטה';

  @override
  String get publishSecret => 'הטמן סוד';

  @override
  String get regularSecret => 'סוד רגיל';

  @override
  String get groupSecret => 'סוד קבוצתי';

  @override
  String get selectTier => 'בחר דרגה מינימלית';

  @override
  String get likes => 'לייקים';

  @override
  String get dislikes => 'דיסלייקים';

  @override
  String get listens => 'האזנות';

  @override
  String get save => 'שמור';

  @override
  String get saved => 'נשמר';

  @override
  String get report => 'דווח';

  @override
  String get reveal => 'התקרב כדי לחשוף...';

  @override
  String get revealed => 'הסוד נחשף!';

  @override
  String metersAway(int distance) {
    return '$distance מטר';
  }

  @override
  String get publishedSecrets => 'סודות שפורסמו';

  @override
  String get savedSecrets => 'סודות שנשמרו';

  @override
  String get distinguished => 'מצטיינים';

  @override
  String tier(int level) {
    return 'דרגה $level';
  }

  @override
  String get cloutLevel => 'רמת השפעה';

  @override
  String get signOut => 'התנתקות';

  @override
  String get language => 'שפה';

  @override
  String get locationPermissionDenied =>
      'הרשאת מיקום נדחתה. HUSH צריך את המיקום שלך כדי לגלות סודות בסביבה.';

  @override
  String get locationUnavailable => 'מיקום לא זמין';

  @override
  String get enableLocation => 'אפשר מיקום';

  @override
  String get retry => 'נסה שוב';

  @override
  String get cancel => 'ביטול';

  @override
  String get delete => 'מחיקה';

  @override
  String get confirm => 'אישור';

  @override
  String get appeals => 'ערעורים';

  @override
  String get reports => 'דיווחים';

  @override
  String get ghostMode => 'מצב רוח רפאים';

  @override
  String get noReports => 'אין דיווחים ממתינים';

  @override
  String get noAppeals => 'אין ערעורים ממתינים';

  @override
  String maxChars(int count) {
    return '$count/140';
  }

  @override
  String recordingTime(int seconds) {
    return '$seconds שניות / 60 שניות';
  }

  @override
  String get mapboxNotConfigured => 'המפה לא מוגדרת';

  @override
  String get tapToReveal => 'הקש כדי לחשוף כשתהיה קרוב מספיק';
}
