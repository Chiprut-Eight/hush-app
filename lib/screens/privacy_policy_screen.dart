import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:hush_app/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHebrew = l10n.localeName == 'he';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.privacyPolicy, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Directionality(
          textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                isDark, 
                isHebrew ? "מדיניות פרטיות" : "Privacy Policy",
                isHebrew 
                  ? "מדיניות פרטיות זו חלה על האפליקציה HUSHHH (להלן \"האפליקציה\") למכשירים ניידים, שנוצרה על ידי גל צ'יפרוט (להלן \"ספק השירות\") כשירות חינמי. שירות זה מיועד לשימוש \"כמות שהוא\" (AS IS)."
                  : "This privacy policy applies to the HUSHHH app (hereby referred to as \"Application\") for mobile devices, created by Gal Chiprut (hereby referred to as \"Service Provider\") as a Free service. This service is intended for use \"AS IS\"."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "איסוף ושימוש במידע" : "Information Collection and Use",
                isHebrew
                  ? "האפליקציה אוספת מידע בעת ההורדה והשימוש בה. מידע זה עשוי לכלול:\n• כתובת ה-IP של המכשיר שלך.\n• הדפים שביקרת בהם, תאריך ושעת הביקור, וזמן השהייה בדפים אלו.\n• מערכת ההפעלה של המכשיר הנייד שלך."
                  : "The Application collects information when you download and use it. This may include:\n• Your device's Internet Protocol (IP) address.\n• Pages visited, date/time of visit, and time spent on those pages.\n• Operating system of your mobile device."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "נתוני מיקום (קריטיים לתפקוד HUSHHH)" : "Location Data (Critical for HUSHHH Functionality)",
                isHebrew
                  ? "האפליקציה דורשת גישה למיקום המדויק שלך בזמן אמת. בניגוד לאפליקציות כלליות, תכונות הליבה של HUSHHH מבוססות על המיקום הפיזי שלך:\n• הפיד (The Feed): הצגת סודות \"מטושטשים\" ברדיוס של 500 מטר.\n• החשיפה (The Reveal): פתיחת סודות רק כאשר אתה נמצא בטווח של 15 מטרים ממיקומם הפיזי.\n• מפת ההדים (The Echo Map): הדמיית אזורים פעילים עם גלי קול פועמים ברדיוס של 1000 מטר.\n• סודות קבוצתיים (Group Secrets): וידוא כי המספר הנדרש של משתמשים נמצאים פיזית באותה נקודה בו-זמנית."
                  : "The Application requires access to your precise real-time location. Unlike general apps, HUSHHH's core features are based on your physical position:\n• The Feed: To display \"blurred\" secrets within a 500-meter radius.\n• The Reveal: To unlock secrets only when you are within 15 meters of their physical location.\n• The Echo Map: To visualize active areas with pulsing sound waves within 1000 meters.\n• Group Secrets: To verify that the required number of users are physically present at a specific spot simultaneously."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "ניהול תוכן ומצב רוח רפאים (Ghost Mode)" : "Content Moderation & Ghost Mode",
                isHebrew
                  ? "כדי לשמור על בטיחות הקהילה, האפליקציה מנטרת מעורבות:\n• בקרת איכות: סודות עם יחס גבוה של 'לא אהבתי' (Dislikes) מקבלים \"אזהרת תוכן\".\n• מצב רוח רפאים: משתמשים שזוהו כפוגעניים או כ-\"טרולים\" עשויים להיות מוגבלים משיתוף סודות חדשים לפרק זמן מוגדר."
                  : "To maintain community safety, the Application monitors engagement:\n• Quality Control: Secrets with high dislike ratios receive a \"Content Warning\".\n• Ghost Mode: Users identified as offensive or \"trolls\" may be restricted from sharing new secrets for a set period."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "מדיניות שמירת נתונים ודעיכה (Decay)" : "Data Retention & Decay Policy",
                isHebrew
                  ? "האפליקציה משתמשת במנגנון \"דעיכה\" אוטומטי כדי לשמור על תוכן רענן:\n• סודות ללא האזנות במשך שבוע יימחקו.\n• סודות עם פחות מ-5 האזנות לאחר 3 שבועות יימחקו.\n• כל הסודות נמחקים לצמיתות לאחר 60 יום, אלא אם כן \"נשמרו\".\n• סודות שמורים: משתמשים יכולים לשמור עד 50 סודות. סודות שמורים פטורים ממחיקת הדעיכה ויישארו בפרופיל המשתמש."
                  : "The Application employs an automatic \"Decay\" mechanism to keep content fresh:\n• Secrets with no listens for one week are deleted.\n• Secrets with fewer than 5 listens after 3 weeks are deleted.\n• All secrets are permanently deleted after 60 days unless \"Saved\".\n• Saved Secrets: Users can save up to 50 secrets. Saved secrets are exempt from the decay deletion and will remain on the user's profile."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "ילדים" : "Children",
                isHebrew
                  ? "ספק השירות אינו אוסף במודע נתונים מילדים מתחת לגיל 13. עליך להיות בן 16 לפחות כדי להסכים לעיבוד הנתונים שלך בתחומי שיפוט מסוימים."
                  : "The Service Provider does not knowingly collect data from children under 13. You must be at least 16 years of age to consent to the processing of your data in certain jurisdictions."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "צור קשר" : "Contact Us",
                isHebrew
                  ? "לשאלות בנושא פרטיות או בקשות למחיקת נתונים, פנה אלינו: support@Hushhh-app.com"
                  : "For privacy questions or data deletion requests, contact: support@Hushhh-app.com"
              ),
              const Divider(height: 48, color: HushColors.borderSubtle),
              _buildSection(
                isDark, 
                isHebrew ? "הצהרת נגישות" : "Accessibility Statement",
                isHebrew
                  ? "HUSHHH מחויבת לספק חוויה חברתית מכילה.\n• תכונות שמע: האפליקציה תומכת בסודות שמע עם פקדי \"הפעלה\" ברורים לשימוש קל.\n• סממנים חזותיים: רמות משתמש (Clout Tiers) משתמשות בהילות צבע בעלות ניגודיות גבוהה כדי לעזור למשתמשים להבחין בין רמות שונות של יוצרים.\n• בטיחות: ניתנות אזהרות תוכן לסודות שקיבלו הרבה דיסלייקים כדי להגן על שלומם של המשתמשים.\n• מגבלה פיזית: שים לב שמכיוון שהאפליקציה \"מבוססת-מיקום גיאוגרפי\", ייתכן שסודות מסוימים לא יהיו נגישים פיזית למשתמשים עם מוגבלות בניידות אם הם ממוקמים באזורים שאינם נגישים."
                  : "HUSHHH is committed to providing an inclusive social experience.\n• Audio Features: The app supports audio secrets with clear \"Play\" controls for ease of use.\n• Visual Indicators: Clout Tiers use high-contrast color halos to help users distinguish between different levels of creators.\n• Safety: Content warnings are provided for highly disliked secrets to protect user well-being.\n• Physical Limitation: Please note that because the app is \"Geo-Acoustic,\" some secrets may be physically inaccessible to users with mobility impairments if they are placed in non-accessible locations."
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(bool isDark, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? HushColors.textAccent : HushColors.gradientBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
