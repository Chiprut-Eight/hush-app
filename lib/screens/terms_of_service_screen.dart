import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:hush_app/l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHebrew = l10n.localeName == 'he';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.termsOfService, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                isHebrew ? "תנאי שימוש - Hushhh" : "Terms of Service - Hushhh",
                isHebrew 
                  ? "תאריך כניסה לתוקף: 6 במאי, 2026\nברוכים הבאים ל-Hushhh, רשת חברתית אקוסטית-גיאוגרפית. בעצם השימוש באפליקציה שלנו, אתם מסכימים לתנאים הבאים. אנא קראו אותם בקפידה."
                  : "Effective Date: May 6, 2026\nWelcome to Hushhh, an acoustic-geographic social network. By using our application, you agree to the following terms. Please read them carefully."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "1. הקונספט" : "1. The Concept",
                isHebrew
                  ? "Hushhh מאפשרת למשתמשים \"לשתול סודות\" (הודעות קוליות או טקסט) במיקומים פיזיים ספציפיים. סודות אלו נעולים וניתנים לחשיפה רק על ידי משתמשים שנמצאים פיזית ברדיוס של 15 מטר מנקודת הציון של הסוד."
                  : "Hushhh allows users to \"plant secrets\" (voice or text messages) at specific physical locations. These secrets are locked and can only be revealed by users physically present within a 15-meter radius of the secret's coordinates."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "2. מגבלות תוכן וכללים" : "2. Content Limitations & Rules",
                isHebrew
                  ? "סודות קוליים: מוגבלים למקסימום של 60 שניות.\nסודות טקסט: מוגבלים למקסימום של 140 תווים.\nהתנהגות משתמשים: הנכם מסכימים שלא לפרסם תוכן שהוא לא חוקי, פוגעני, מטריד, או מפר את זכויותיהם של אחרים."
                  : "Voice Secrets: Limited to a maximum of 60 seconds.\nText Secrets: Limited to a maximum of 140 characters.\nUser Conduct: You agree not to post content that is illegal, offensive, harassing, or violates the rights of others."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "3. סוגי סודות ורמות (Tiers)" : "3. Types of Secrets & Tiers",
                isHebrew
                  ? "סודות רגילים: ניתנים לפתיחה על ידי משתמש יחיד.\nסודות קבוצתיים: דורשים מספר ספציפי של משתמשים להיות נוכחים פיזית במיקום בו-זמנית במסגרת חלון זמן מוגדר.\nרמות משתמש (Clout Tiers): הסטטוס שלכם כיוצרים גדל בהתבסס על הפעלות מוצלחות של סודות קבוצתיים, מה שמשנה את \"צבע ההילה\" שלכם בפיד (מאפור ברמה 1 לזהב פועם ברמה 10)."
                  : "Standard Secrets: Can be opened by a single user.\nGroup Secrets: Require a specific number of users to be physically present at the location simultaneously within a set time window.\nClout Tiers: Your status as a creator grows based on successful Group Secret activations, changing your \"aura color\" in the feed (from Gray at Tier 1 to Pulsating Gold at Tier 10)."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "4. דעיכת תוכן ואחסון" : "4. Content Decay & Storage",
                isHebrew
                  ? "כדי לשמור על סביבה נקייה ודחופה, Hushhh מיישמת מחיקה אוטומטית (\"דעיכה\"):\n• סודות ללא האזנות לאחר שבוע נמחקים.\n• סודות עם פחות מ-5 האזנות לאחר 3 שבועות נמחקים.\n• כל הסודות נמחקים לצמיתות לאחר 60 יום.\n• חריג: אתם יכולים \"לשמור\" עד 50 סודות (שלכם או של אחרים). סודות שמורים פטורים ממנגנון הדעיכה האוטומטי."
                  : "To maintain a clean and urgent environment, Hushhh implements automatic deletion (\"Decay\"):\n• Secrets with zero listens after 1 week are deleted.\n• Secrets with fewer than 5 listens after 3 weeks are deleted.\n• All secrets are permanently deleted after 60 days.\n• Exception: You may \"Save\" up to 50 secrets (your own or others'). Saved secrets are exempt from the automatic decay mechanism."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "5. בטיחות משתמשים ואחריות" : "5. User Safety & Responsibility",
                isHebrew
                  ? "בטיחות פיזית: מאחר ו-Hushhh דורשת תנועה פיזית למיקומים ספציפיים, האחריות על בטיחותכם ועל כך שיש לכם את הזכות החוקית להיות במיקום, חלה עליכם בלבד. Hushhh אינה אחראית לכל פציעות, נזק לרכוש, או בעיות משפטיות הנובעות מהנסיעה הפיזית שלכם כדי \"לחשוף\" סודות."
                  : "Physical Safety: Since Hushhh requires physical movement to specific locations, you are solely responsible for your safety and for ensuring you have the legal right to be at a location. Hushhh is not liable for any injuries, property damage, or legal issues arising from your physical travel to \"reveal\" secrets."
              ),
              _buildSection(
                isDark, 
                isHebrew ? "6. אכיפה ומצב רוח רפאים (Ghost Mode)" : "6. Enforcement & Ghost Mode",
                isHebrew
                  ? "לא אהבתי (Dislikes): תוכן עם יחסי 'לא אהבתי' גבוהים יקבל \"אזהרת תוכן\" לפני פתיחתו.\nמצב רוח רפאים (Ghost Mode): משתמשים המפרסמים תוכן פוגעני או \"טרולי\" עשויים להיות מוגבלים מפרסום סודות חדשים לתקופה מסוימת (שבוע עד חודש). במהלך זמן זה, הם עדיין יכולים לצרוך סודות ולהצביע.\nערעורים: משתמשים רשאים לערער על חסימות דרך מערכת סקירת המערכת הידנית שלנו."
                  : "Dislikes: Content with high dislike ratios will receive a \"Content Warning\" before being opened.\nGhost Mode: Users who post offensive or \"trolling\" content may be restricted from posting new secrets for a period (1 week to 1 month). During this time, they can still consume secrets and vote.\nAppeals: Users may appeal bans through our manual system review."
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
