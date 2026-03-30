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
  String get secretPlaceholder =>
      'מה עובר לך בראש? שמור את זה בסוד... (עד 140 תווים)';

  @override
  String get recordVoice => 'הקלט סוד קולי';

  @override
  String get stopRecording => 'עצור הקלטה';

  @override
  String get publishSecret => 'הטמן סוד';

  @override
  String get hideSecretAction => '🤫 הטמן סוד';

  @override
  String get regularSecret => 'סוד רגיל';

  @override
  String get regularSecretDesc => 'גלוי לכולם בקרבת מקום באופן מיידי.';

  @override
  String get groupSecret => 'סוד קבוצתי';

  @override
  String get groupSecretDesc => 'דורש מספר אנשים בקרבת מקום כדי להיפתח.';

  @override
  String get selectTier => 'בחר דרגה מינימלית';

  @override
  String get secretType => 'סוג הסוד';

  @override
  String get peopleRequired => 'כמות אנשים נדרשת';

  @override
  String timeWindow(int minutes) {
    return 'חלון זמן: $minutes דקות';
  }

  @override
  String get textTab => '✍️ טקסט';

  @override
  String get voiceTab => '🎙️ קול';

  @override
  String get secretReady => 'הסוד מוכן';

  @override
  String get tapToRecord => 'הקש כדי להקליט';

  @override
  String get recordingLabel => 'מקליט...';

  @override
  String get audioPreview => 'תצוגה מקדימה קולית';

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
  String get outOfRange => 'מחוץ לטווח';

  @override
  String get contentWarning => 'אזהרת תוכן';

  @override
  String get downvotedWarning => 'סוד זה קיבל הרבה דיסלייקים.';

  @override
  String get viewAnyway => 'הצג בכל זאת';

  @override
  String get saveLimitWarning =>
      'ניתן לשמור עד 50 סודות שלך או של משתמשים אחרים';

  @override
  String get publishedSecrets => 'סודות שפורסמו';

  @override
  String get savedSecrets => 'סודות שנשמרו';

  @override
  String get mySecretsTab => 'הסודות שלי';

  @override
  String get noPlantedSecrets => 'טרם הטמנת סודות.';

  @override
  String get noSavedSecrets => 'לא נמצאו סודות שמורים.';

  @override
  String get enableNotifications => 'אפשר התראות';

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
  String get appeal => 'ערעור';

  @override
  String get appeals => 'ערעורים';

  @override
  String get reports => 'דיווחים';

  @override
  String get ghostMode => 'מצב רוח רפאים';

  @override
  String get ghostModeActive => '👻 מצב רוח רפאים פעיל';

  @override
  String get ghostModeRestricted => 'פעולות החשבון שלך מוגבלות.';

  @override
  String get cannotPlantGhost => 'אינך יכול להטמין סודות כרגע.';

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
  String get tapToReveal => 'הקש כדי לחשוף';

  @override
  String get onboardingTitle => 'השלם את הפרופיל שלך';

  @override
  String get onboardingWelcome => 'ברוכים הבאים ל-HUSH!';

  @override
  String get onboardingSub => 'אנא ספק כמה פרטים בסיסיים לפני שנתחיל במסע.';

  @override
  String get firstName => 'שם פרטי';

  @override
  String get lastName => 'שם משפחה';

  @override
  String get dateOfBirth => 'תאריך לידה';

  @override
  String get selectDate => 'בחר תאריך';

  @override
  String get gender => 'מגדר';

  @override
  String get genderMale => 'זכר';

  @override
  String get genderFemale => 'נקבה';

  @override
  String get genderOther => 'אחר';

  @override
  String get hidePhoto => 'הסתר תמונת פרופיל';

  @override
  String get hidePhotoSub => 'השתמש בלוגו הגנרי של HUSH במקום בתמונה שלי';

  @override
  String get completeReg => 'סיים הרשמה';

  @override
  String get firstNameReq => 'שם פרטי הוא חובה';

  @override
  String get lastNameReq => 'שם משפחה הוא חובה';

  @override
  String get dobReq => 'אנא בחר את תאריך הלידה שלך';

  @override
  String get followingTabTitle => 'נעקבים';

  @override
  String get searchUsersHint => 'חיפוש משתמשים...';

  @override
  String get noUsersFound => 'לא נמצאו משתמשים';

  @override
  String get notFollowingAnyone => 'אינך עוקב אחרי אף אחד כרגע.';

  @override
  String get followBtn => 'עקוב';

  @override
  String get unfollowBtn => 'הסר עוקב';

  @override
  String publishedSecretAgo(int hours) {
    return 'פורסם סוד לפני $hours שעות';
  }

  @override
  String get tapToViewMap => 'לחץ לצפייה במפה';

  @override
  String get noActiveSecrets => 'אין סודות פעילים';

  @override
  String get anonymousUser => 'אנונימי';
}
