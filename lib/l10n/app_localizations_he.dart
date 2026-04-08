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
  String get feedTitle => 'Hushhh בקרבת מקום';

  @override
  String get feedEmpty => 'אין Hushhh בסביבה... הסתובב כדי לגלות לחישות נסתרות';

  @override
  String get feedLoading => 'מאזין ל-Hushhh...';

  @override
  String get mapTitle => 'מפת הד';

  @override
  String get createTitle => 'הטמן Hushhh';

  @override
  String get profileTitle => 'פרופיל';

  @override
  String get adminTitle => 'פאנל ניהול';

  @override
  String get secretPlaceholder =>
      'מה עובר לך בראש? שמור את זה ב-Hushhh... (עד 140 תווים)';

  @override
  String get recordVoice => 'הקלט Hushhh קולי';

  @override
  String get stopRecording => 'עצור הקלטה';

  @override
  String get publishSecret => 'הטמן Hushhh';

  @override
  String get hideSecretAction => 'הטמן Hushhh';

  @override
  String get regularSecret => 'Hushhh רגיל';

  @override
  String get regularSecretDesc => 'גלוי לכולם בקרבת מקום באופן מיידי.';

  @override
  String get groupSecret => 'Hushhh קבוצתי';

  @override
  String get groupSecretDesc => 'דורש מספר אנשים בקרבת מקום כדי להיפתח.';

  @override
  String get selectTier => 'בחר דרגה מינימלית';

  @override
  String get secretType => 'סוג ה-Hushhh';

  @override
  String get peopleRequired => 'כמות אנשים נדרשת';

  @override
  String timeWindow(int minutes) {
    return 'חלון זמן: $minutes דקות';
  }

  @override
  String get textTab => 'טקסט';

  @override
  String get voiceTab => 'קול';

  @override
  String get secretReady => 'ה-Hushhh מוכן';

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
  String get revealed => 'ה-Hushhh נחשף!';

  @override
  String metersAway(int distance) {
    return '$distance מטר';
  }

  @override
  String get outOfRange => 'מחוץ לטווח';

  @override
  String get contentWarning => 'אזהרת תוכן';

  @override
  String get downvotedWarning => 'Hushhh זה קיבל הרבה דיסלייקים.';

  @override
  String get viewAnyway => 'הצג בכל זאת';

  @override
  String get saveLimitWarning =>
      'ניתן לשמור עד 50 Hushhh שלך או של משתמשים אחרים';

  @override
  String get publishedSecrets => 'Hushhh שפורסמו';

  @override
  String get savedSecrets => 'Hushhh שנשמרו';

  @override
  String get mySecretsTab => 'ה-Hushhh שלי';

  @override
  String get noPlantedSecrets => 'טרם הטמנת Hushhh.';

  @override
  String get noSavedSecrets => 'לא נמצאו Hushhh שמורים.';

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
      'הרשאת מיקום נדחתה. HUSH צריך את המיקום שלך כדי לגלות Hushhh בסביבה.';

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
  String get ghostModeActive => 'מצב רוח רפאים פעיל';

  @override
  String get ghostModeRestricted => 'פעולות החשבון שלך מוגבלות.';

  @override
  String get cannotPlantGhost => 'אינך יכול להטמין Hushhh כרגע.';

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
  String get followingTabTitle => 'במעקב';

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
    return 'פורסם Hushhh לפני $hours שעות';
  }

  @override
  String get tapToViewMap => 'לחץ לצפייה במפה';

  @override
  String get noActiveSecrets => 'אין Hushhh פעילים';

  @override
  String get anonymousUser => 'אנונימי';

  @override
  String get followers => 'עוקבים';

  @override
  String timeAgoSeconds(int count) {
    return 'לפני $count שנ׳';
  }

  @override
  String timeAgoMinutes(int count) {
    return 'לפני $count דק׳';
  }

  @override
  String timeAgoHours(int count) {
    return 'לפני $count שע׳';
  }

  @override
  String timeAgoDays(int count) {
    return 'לפני $count ימ׳';
  }

  @override
  String timeAgoWeeks(int count) {
    return 'לפני $count שב׳';
  }

  @override
  String timeAgoMonths(int count) {
    return 'לפני $count חד׳';
  }

  @override
  String timeAgoYears(int count) {
    return 'לפני $count שנ׳';
  }

  @override
  String get reportTitle => 'דיווח על Hushhh';

  @override
  String get reportReason => 'מדוע את/ה מדווח/ת?';

  @override
  String get reportReasonHate => 'שיח שנאה';

  @override
  String get reportReasonSpam => 'ספאם';

  @override
  String get reportReasonHarassment => 'הטרדה';

  @override
  String get reportReasonViolence => 'אלימות';

  @override
  String get reportReasonOther => 'אחר';

  @override
  String get reportSuccess => 'הדיווח נשלח. תודה.';

  @override
  String get reportConfirm => 'דווח';

  @override
  String get appealTitle => 'הגש ערעור';

  @override
  String get appealReason => 'הסבר מדוע את/ה מערער/ת:';

  @override
  String get appealSuccess => 'הערעור נשלח. נבדוק את המקרה שלך.';

  @override
  String get appealSubmit => 'שלח ערעור';

  @override
  String get deleteSecretTitle => 'מחיקת Hushhh';

  @override
  String get deleteSecretConfirm =>
      'האם אתה בטוח שברצונך למחוק את ה-Hushhh? לא ניתן לבטל פעולה זו.';

  @override
  String get comments => 'תגובות';

  @override
  String get addComment => 'הוסף תגובה...';

  @override
  String get noComments => 'אין תגובות עדיין. היה הראשון!';

  @override
  String get deleteComment => 'מחק תגובה';

  @override
  String get commentPlaceholder => 'כתוב תגובה...';

  @override
  String get directionToSecret => 'כיוון אל ה-Hushhh';

  @override
  String groupUnlockProgress(int count) {
    return 'רגע! דרושים עוד $count אנשים כדי לחשוף את ה-Hushhh הזה.';
  }

  @override
  String get groupUnlockSuccess => 'הקבוצה התאחדה. ה-Hushhh נחשף!';

  @override
  String get maintenanceTitle => 'תחזוקה';

  @override
  String get testConfetti => 'בדיקת אנימציית קונפטי';

  @override
  String get migrateUsers => 'עדכון משתמשים (קבוצתי)';

  @override
  String get settings => 'הגדרות';

  @override
  String get termsOfService => 'תנאי שימוש';

  @override
  String get privacyPolicy => 'מדיניות פרטיות';

  @override
  String get migrationSearchTitle => 'עדכון אינדקס חיפוש';

  @override
  String get migrationSearchDesc =>
      'כלי זה מעדכן את שדה ה-\"searchName\" עבור משתמשים ישנים כדי לאפשר את חיפושם במערכת החדשה.';

  @override
  String get migrationReady => 'מוכן לעדכון משתמשים.';

  @override
  String get migrationFetching => 'מחפש משתמשים ללא searchName...';

  @override
  String get migrationAllDone => 'כל המשתמשים עודכנו!';

  @override
  String get migrationBatchDone =>
      'קבוצת משתמשים עודכנה! הפעל שוב במידת הצורך.';

  @override
  String migrationError(String error) {
    return 'שגיאה במהלך העדכון: $error';
  }

  @override
  String get tutorial_p1_title => 'ברוכים הבאים ל-Hushhh';

  @override
  String get tutorial_p1_content =>
      'אנחנו רשת חברתית גאוגרפית שבה המרחב הפיזי הופך ללוח ה-Hushhh שלכם.\n• איך זה עובד? Hushhh הוא כמו סוד - אתם \'מטמינים Hushhh\' (הודעות קוליות או טקסט) בנקודה המדויקת שבה אתם נמצאים.\n• העולם הוא הפיד שלכם: הפיד דינמי ומשתנה לפי המיקום שלכם - הוא תמיד יציג את מה שקורה סביבכם ברגע זה.';

  @override
  String get tutorial_p2_title => 'החשיפה של ה-Hushhh';

  @override
  String get tutorial_p2_content =>
      'ה-Hushhh בפיד מופיעים במצב \'מטושטש\' כל עוד אתם רחוקים.\n• Hushhh הופך לזמין לפתיחה רק כשאתם נמצאים פיזית במרחק של עד 15 מטרים ממנו.\n• ברגע שתגיעו לטווח, הטשטוש ייעלם ותוכלו לקרוא את הטקסט או ללחוץ Play ולהאזין.\n• על המפה תוכלו לחפש תדר פועם כדי לדעת איפה יש פעילות מעניינת ברדיוס של 200 מטר סביבכם.';

  @override
  String get tutorial_p3_title => 'Hushhh רגיל או קבוצתי?';

  @override
  String get tutorial_p3_content =>
      'לא כל Hushhh נועד לאדם אחד. אתם קובעים את החוקים:\n• Hushhh רגיל פתוח לכל מי שמגיע לנקודה.\n• Hushhh קבוצתי = אתגר קבוצתי! ניתן לפתוח אותו רק אם כמות משתמשים מסוימת (החל מ-3) נמצאת בנקודה בו-זמנית בחלון זמן מוגדר.\n• תעלו רמה: הצלחה בהפעלת Hushhh קבוצתיים מעלה את הסטטוס שלכם - צבע ההילה סביב ה-Hushhh משתנה ומשתמשים אחרים יזהו אתכם כיוצרים מעניינים.';

  @override
  String get tutorial_p4_title => 'איפה התוכן שלי?';

  @override
  String get tutorial_p4_content =>
      'התוכן ב-Hushhh הוא זמני וחי, מה שיוצר דחיפות ואותנטיות:\n• מנגנון המחיקה: Hushhh שלא נפתחו לצפייה או כאלו שעברו 60 יום נמחקים מהעולם כדי לשמור על המפה נקייה.\n• כפתור השמירה: מצאתם Hushhh שאתם חייבים לשמור? תוכלו לשמור עד 50 Hushhh (שלכם או של אחרים) בפרופיל שלכם, והם לא יימחקו לעולם.\n• איכות מעל הכל: הפרופיל שלכם מציג את ה-Hushhh המובחרים שפרסמתם - אלו ששרדו את מבחן הזמן והעניין של הקהילה.\nפספסתם משהו? אל דאגה. תמיד תוכלו לחזור להסבר המלא דרך תפריט ההגדרות באפליקציה.\nמוכנים להטמין את ה-Hushhh הראשון שלכם?';

  @override
  String get action_understand => 'הבנתי';

  @override
  String get drawer_what_is_hush => 'מה זה Hushhh?';
}
