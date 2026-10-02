# Hushhh - Technical Architecture & Infrastructure

מסמך זה מתאר את הארכיטקטורה הטכנית, החבילות והכלים המשולבים באפליקציית Hushhh, ומשמש כרפרנס לאנשי פיתוח ואדריכלי תוכנה.

## 1. ארכיטקטורה כללית (High-Level Architecture)
האפליקציה בנויה בארכיטקטורת Serverless המבוססת על Flutter בצד הלקוח (Client) ו-Firebase בצד השרת (Backend).

*   **Frontend:** פותח באמצעות תשתית (Framework) **Flutter** (בשפת Dart). מאפשר בניית קוד יחיד (Single Codebase) המתקמפל ל-iOS ו-Android ברמת ביצועים של Native.
*   **State Management:** ניהול המצב בצד הלקוח מתבצע באמצעות חבילת ה-**Provider**. הפרויקט משתמש במספר Providers נפרדים (למשל `AuthProvider`, `UiProvider`, `LocationProvider`) כדי להפריד בין הלוגיקה העסקית לתצוגה (UI).
*   **Backend as a Service (BaaS):** שימוש נרחב ב-**Firebase** המעניק ניהול משתמשים, מסד נתונים, אחסון קבצים, והרצת קוד צד-שרת מנוהל (Cloud Functions).

## 2. שירותי Firebase והטמעתם
*   **Firebase Authentication:** מנהל את תהליך ההזדהות. תומך ב-Google Sign-In וב-Apple Sign-In בלבד.
*   **Cloud Firestore:** מסד הנתונים הראשי (NoSQL). מכיל קולקשנים (Collections) עבור:
    *   `users`: נתוני פרופיל, דרגות (Tiers), מוניטין ומצב רפאים (Ghost Mode).
    *   `secrets`: מיקומי ה-Hushhh, תוכן, נתונים גיאוגרפיים, כמות משתמשים דרושה וזמני תפוגה.
    *   `comments`: תגובות של משתמשים על Hushhh (מבנה תת-קולקשן).
    *   `reports` & `appeals`: מערכת הדיווחים והערעורים. הדיווחים נשמרים עם מזהה ייחודי (`secretId_userId`) כדי למנוע כפילויות של דיווחים מאותו משתמש על אותו תוכן.
    *   `stats`: שומר סטטיסטיקות גלובליות כגון סך כל ה-Hushhh שנוצרו ונמחקו בדעיכה לשימוש בפאנל הניהול.
*   **Firebase Storage:** אחסון מבוסס ענן המשמש לאחסון קבצי אודיו בלבד (Hushhh קוליים, נשמרים בפורמט m4a).
*   **Firebase Realtime Database (RTDB):** משמש כמנגנון Presence (נוכחות) קל משקל. מנהל רישום בזמן אמת של משתמשים המחוברים לאפליקציה על ידי האזנה ל-`.info/connected` ושימוש ב-`onDisconnect()`. פאנל הניהול שואב משם נתונים בזמן אמת בלי להעמיס קריאות על ה-Firestore.
*   **Firebase Cloud Functions:** קוד צד-שרת (Node.js & TypeScript) האחראי על אכיפת חוקים עסקיים קריטיים, ביניהם:
    *   `verifyGroupUnlock`: פונקציה טרנזקציונלית המוודאת שיש מספיק משתמשים ברדיוס של Hushhh קבוצתי לפני שהיא פותחת אותו. היא גם מנהלת את קידום הדרגות (Tier Upgrades) של יוצר ה-Hushhh.
    *   `decaySecretsJob` (Cron Job): תהליך מתוזמן למחיקת Hushhh שתוקפם פג (60 יום מקסימום) או Hushhh לא פופולריים שקיבלו מעט מאוד האזנות. הרצת האזהרות בשעה 10:00 והמחיקה בשעה 16:00.
    *   `onUserProfileUpdate`: פונקציית טריגר שרצה בעת עדכון פרופיל המשתמש, ומוודאת ששם היוצר ותמונת הפרופיל מתעדכנים אוטומטית בכל ה-Hushhh שהמשתמש יצר (Auto-sync).
    *   `onSecretCreated`: פונקציית טריגר לשמירת ספירה גלובלית של ה-Hushhh.
    *   ניהול Ghost Mode ואכיפת עונשים עקב דיווחים.
*   **Firebase Cloud Messaging (FCM):** ניהול ושליחת Push Notifications במערכת (התראות רקע וחזית) באמצעות חבילת `firebase_messaging`.

## 3. אינטגרציית מפה ומיקום (Location & Mapping)
האפליקציה נשענת על מיקום גיאוגרפי (Geo-location) כמרכיב ליבה:
*   **geolocator:** קריאת מיקום ה-GPS של המכשיר, בקשת הרשאות משתמש וחישוב מרחקים מדויקים (Distance in meters).
*   **flutter_map:** ספריית מפות Open-Source המבוססת על Leaflet. משמשת לרינדור המפה.
*   **latlong2:** חבילה מתמטית לניהול נקודות ציון גיאוגרפיות (קואורדינטות) וחישובי רדיוסים.
*   **flutter_compass:** מאפשר את חווית "המצפן" בפיד, שמראה למשתמש לאיזה כיוון פיזי עליו להסתובב כדי להגיע ל-Hushhh.

## 4. מולטימדיה ואודיו (Audio Engine)
*   **record:** חבילה להקלטת קול ישירות מהמיקרופון של המכשיר תוך ציור גלי קול בזמן אמת (Amplitudes).
*   **just_audio:** מנוע נגן אודיו מתקדם להשמעת ה-Hushhh הקוליים בצורה חלקה כולל חיבור לזרם הרשת (Streaming).
*   **audio_session:** ניהול תור האודיו של מערכת ההפעלה, כדי שהאפליקציה תדע להנמיך או להשהות מוזיקת רקע (כמו Spotify) כשהמשתמש מאזין ל-Hushhh.

## 5. ממשק וחווית משתמש (UI/UX)
*   **Theme & Design System:** שימוש נרחב ב-Dark Theme מותאם אישית (Custom Colors/Neon accents). 
*   **google_fonts:** טעינת פונטים מעוצבים דינמית.
*   **tutorial_coach_mark:** הטמעת הדרכות משתמש (Onboarding Walkthroughs) שמחשיכות את המסך ומאירות כפתורים ספציפיים.
*   **confetti:** הזרקת אנימציות "קונפטי" במסכי הצלחה (למשל כאשר Hushhh קבוצתי נפתח).
*   **shimmer:** יצירת אפקטים של טעינה (Skeleton Loaders) במהלך קריאות רשת.
*   **intl:** פירמוט תאריכים ושעות גלובלי.
*   **App Localizations (l10n):** תמיכה מלאה בהחלפת שפות (i18n) עברית-אנגלית דינמית מתוך האפליקציה.

## 6. אבטחה ופרטיות (Security)
*   **screen_protector:** מונע צילומי מסך והקלטות מסך (ב-Android משתמש בדגל `FLAG_SECURE`). מגן על פרטיות תוכן ה-Hushhh.
*   **Firestore Rules:** אכיפת הרשאות קשוחה בצד השרת: משתמשים יכולים לראות Hushhh רק אם הם ברדיוס, יוצרים אינם יכולים לזייף חותמות זמן, ואסור למחוק מידע של משתמשים אחרים.
*   **Environment Variables:** החזקת מפתחות ונתונים רגישים (כמו Admin UID) מחוץ לקוד הנגיש, והזרקתם במהלך ה-Build.
