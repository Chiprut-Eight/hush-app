# 📋 תוכנית יישום — 14 משימות Hushhh

---

## 1. 🔓 האשש שנפתח ישאר פתוח 24 שעות

**מצב נוכחי:**
כיום, כשמשתמש "חושף" (reveal) האשש, הוא לא נשמר כפתוח — אם יחזור לפיד, הכרטיסייה תופיע שוב כנעולה.
ב-Cloud Functions ([index.ts:846](file:///c:/Dev/hush-app/functions/src/index.ts#L846)) הפונקציה `revealSecret` בודקת מרחק ומחזירה תוכן, אבל לא שומרת מזהים מקומיים.

**שינויים נדרשים:**

| שכבה | קובץ | פעולה |
|-------|-------|-------|
| **Client** | `lib/services/secret_service.dart` | לאחר `revealSecret` מוצלח, לשמור `{secretId: timestamp}` ב-`SharedPreferences` תחת `revealed_secrets` |
| **Client** | `lib/widgets/secret_card.dart` | לפני בדיקת מרחק ≤15m, לבדוק אם ה-secret נמצא ב-cache המקומי ו-timestamp < 24h. אם כן — להציג פתוח |
| **Client** | `lib/config/constants.dart` | להוסיף `static const int revealCacheDurationHours = 24;` |
| **Client** | `lib/services/secret_service.dart` | פונקציה `cleanExpiredReveals()` שתרוץ ב-`initState` של `FeedScreen` ותמחק reveals ישנים מהאחסון |

**סיכום מאמץ:** בינוני — שינוי בלקוח בלבד, ללא Cloud Functions

---

## 2. ⏰ שעות שליחת נוטיפיקציות מערכת

**מצב קודם (לפני השינוי):**
- `decaySecretsJob` — רץ ב-**02:00** בלילה
- `onSecretExpiringSoon` — רץ ב-**00:00** בחצות

**מצב מוגדר בקוד (סופי, שעון ישראל `Asia/Jerusalem`):**

| פונקציה | תפקיד | Schedule | שעה |
|---------|-------|----------|-----|
| `onSecretExpiringSoon` ([index.ts:485](file:///c:/Dev/hush-app/functions/src/index.ts#L485)) | אזהרה לפני מחיקה | `"0 10 * * *"` | **10:00** בבוקר |
| `decaySecretsJob` ([index.ts:205](file:///c:/Dev/hush-app/functions/src/index.ts#L205)) | הסרה בפועל של Hushhh + התראה | `"0 16 * * *"` | **16:00** אחה"צ |

ככה האזהרה מגיעה 6 שעות לפני שהמערכת באמת מוחקת.

> [!WARNING]
> **שינוי schedule בקוד לא משפיע עד שמבצעים deploy.** ה-Cloud Scheduler בגוגל ממשיך להריץ את ה-schedule האחרון שנפרס.
> התקלה שנצפתה (התראת הסרה ב-02:00 למרות שהקוד מוגדר ל-16:00) נבעה מכך שהשינוי נשמר ונדחף לגיט, אך הפונקציות לא נפרסו מחדש.
> חובה להריץ: `firebase deploy --only functions:decaySecretsJob,functions:onSecretExpiringSoon`

**סטטוס:** ✅ קוד מעודכן | ✅ נפרס ל-Firebase ב-04/10/2026 (Cloud Scheduler עודכן: `0 2`→`0 16`, `0 0`→`0 10`)

---

## 3. 🔄 עדכון שם יוצר בכרטיסיות לאחר שינוי שם

**מצב נוכחי:**
ב-[secret.dart](file:///c:/Dev/hush-app/lib/models/secret.dart) כל כרטיסיית האשש שומרת `creatorName` כ-snapshot. כלומר אם המשתמש שינה שם בהגדרות, כל ההאששים הישנים עדיין מציגים את השם הישן.

**שינויים נדרשים:**

| שכבה | קובץ | פעולה |
|-------|-------|-------|
| **Functions** | `functions/src/index.ts` | הוסף Cloud Function חדשה `onUserProfileUpdate` שמאזינה ל-`users/{userId}` — כשמשתנים `firstName`/`lastName`/`displayName`, היא תשלח batch update לכל ה-secrets של אותו userId ב-collection `secrets` |
| **Functions** | (באותו קובץ) | הפונקציה גם תעדכן `creatorPhotoURL` אם השתנה |
| **Client** | `lib/screens/settings_screen.dart` | אין שינוי נדרש — הפונקציה ב-Functions תתפוס את ה-trigger אוטומטית |

**לוגיקה:**
```typescript
export const onUserProfileUpdate = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;
    
    // Check if name or photo changed
    if (before.firstName === after.firstName && 
        before.lastName === after.lastName && 
        before.displayName === after.displayName &&
        before.profileImageURL === after.profileImageURL) return;
    
    const newName = `${after.firstName || ''} ${after.lastName || ''}`.trim() || after.displayName || '';
    const newPhoto = after.profileImageURL || '';
    
    // Batch update all secrets by this user
    const secrets = await db.collection("secrets")
      .where("creatorId", "==", userId).get();
    
    const batch = db.batch();
    secrets.docs.forEach(doc => {
      batch.update(doc.ref, { creatorName: newName, creatorPhotoURL: newPhoto });
    });
    await batch.commit();
  });
```

**סיכום מאמץ:** בינוני — Cloud Function חדשה + deploy

---

## 4. 📐 רדיוס הפיד והמפה

**מצב נוכחי (מתוך [constants.dart](file:///c:/Dev/hush-app/lib/config/constants.dart)):**

| פרמטר | ערך | שימוש |
|--------|-----|-------|
| `feedRadiusMeters` | **500 מטר** | הפיד הראשי (Nearby Hushhh) |
| `echoMapRadiusMeters` | **1,000 מטר** (1 ק"מ) | המפה |
| `revealRadiusMeters` | **15 מטר** | חשיפת תוכן (כפתור Reveal) |

> [!NOTE]
> **לא נדרש שינוי קוד** — רק תיעוד. הערכים כבר מוגדרים ב-constants.

---

## 5. 📑 הוספת טאבים בראש הפיד (Nearby / Following / Saved)

**מצב נוכחי:**
הפיד הראשי (`FeedScreen`) מציג רק "Nearby Hushhh". הטאב "Following" הוא מסך נפרד (`FollowingScreen`) ב-bottom navigation.

**שינויים נדרשים:**

| שכבה | קובץ | פעולה |
|-------|-------|-------|
| **Client** | `lib/screens/feed_screen.dart` | הוסף `_selectedFeedTab` enum: `nearby`, `following`, `saved` |
| **Client** | (באותו קובץ) | ב-`build()`, הוסף `Row` עם 3 כותרות בראש המסך, בסגנון TikTok: `Nearby Hushhh` | `Following` | `Saved` |
| **Client** | (באותו קובץ) | הכותרת שנבחרה — בצבע לבן מלא. האחרות — `Colors.white38` (דהויות) |
| **Client** | (באותו קובץ) | כשלוחצים על "Following" → להציג את אותו ה-feed logic מ-`FollowingScreen._followedFeed` |
| **Client** | (באותו קובץ) | כשלוחצים על "Saved" → לטעון `SecretService().getSavedSecrets(savedSecretIds)` |
| **Client** | `lib/screens/app_shell.dart` | הטולבר (AppBar) יציג את הכותרת של הטאב הנבחר (`Nearby Hushhh` / `Following` / `Saved Hushhh`) |
| **Client** | `lib/screens/app_shell.dart` | להחליף את הטאב "Following" ב-bottom nav לטאב אחר (או להסתיר אותו ולהשאיר 4 טאבים) |

**עיצוב:**
```
┌─────────────────────────────────┐
│  Nearby Hushhh  Following  Saved │  ← דהוי/לבן כמו TikTok
│  ═══════════                     │  ← קו תחתון לנבחר
├─────────────────────────────────┤
│         [כרטיסיות הפיד]          │
└─────────────────────────────────┘
```

**סיכום מאמץ:** גבוה — ארכיטקטורה מחודשת של מסך הפיד

---

## 6. 💬 כרטיסייה נשארת פתוחה למשתמש שהגיב

**מצב נוכחי:**
כשמשתמש לוחץ על נוטיפיקציית תגובה, הוא מנווט ל-`SecretDetailScreen`. אם הוא לא ב-radius — הכרטיסייה נראית כנעולה.

**שינויים נדרשים:**

| שכבה | קובץ | פעולה |
|-------|-------|-------|
| **Functions** | `functions/src/index.ts` (`revealSecret`) | הוסף בדיקה: אם למשתמש יש תגובה ב-`secrets/{secretId}/comments` → דלג על בדיקת מרחק ותן גישה |
| **Client** | `lib/screens/secret_detail_screen.dart` | כשנכנסים מנוטיפיקציה (`type=comment`, `type=like` etc.), שלח `bypassDistance: true` ל-`revealSecret` |
| **Functions** | `revealSecret` | אם `bypassDistance === true`, ודא שהמשתמש אכן הגיב (query ל-comments sub-collection) לפני חשיפה |

**טריגרים לגישה ללא מרחק:**
- ✅ מישהו הגיב לתגובה שלי
- ✅ מישהו עשה לייק לתגובה שלי
- ✅ תגובה חדשה להאשש שהגבתי עליו
- ✅ לחצתי על נוטיפיקציה מסוג comment/like שקשורה אליי

**סיכום מאמץ:** גבוה — שינוי ב-Functions + Client + לוגיקת אימות

---

## 7. 📖 הדרכת בועות בפיד הראשי (Tutorial)

**מצב נוכחי:**
קיים `TutorialCoachMark` ב-`FollowingScreen` ו-`AppShell`. אין הדרכה בפיד הראשי.

**שינויים נדרשים:**

| שכבה | קובץ | פעולה |
|-------|-------|-------|
| **Client** | `lib/screens/feed_screen.dart` | הוסף `_showFeedTutorial()` שיציג 3-4 שלבי הדרכה |
| **Client** | (באותו קובץ) | צור כרטיסיות פיקטיביות (mock widgets) שייראו כמו כרטיסיות אמיתיות |
| **Client** | `lib/models/hush_user.dart` | הוסף שדה `hasSeenFeedTutorial` |
| **Firestore** | `users` collection | שדה חדש `hasSeenFeedTutorial: false` |

**תוכן ההדרכה (3 כרטיסיות הדמיה):**

| כרטיסייה | מצב | תוכן |
|-----------|------|-------|
| 1 | **פתוחה (טקסט)** | "ברוכים הבאים ל-Hushhh 🎉" |
| 2 | **נעולה (קבוצתית)** | הסבר שצריך להגיע פיזית + כמה אנשים |
| 3 | **פתוחה (קול)** | גלי סאונד מונפשים |

**שלבי ההדרכה:**
1. "לחץ על כרטיסייה כדי לפתוח האשש" (Target: כרטיסייה 1)
2. "👍 לייק = שווה ללכת | 👎 דיסלייק = אפשר לדלג. הדיסלייק עוזר לך להחליט אם שווה ללכת להאשש מרוחק" (Target: כפתורי לייק/דיסלייק)
3. "שמור Hushhh שאהבת — ניתן לצפות בהם מהפרופיל ומהפיד (עד 50)" (Target: כפתור שמירה)

**סיכום מאמץ:** גבוה — UI מורכב עם הדמיות

---

## 8. 📝 ברירת מחדל טקסט בעמוד יצירת האשש

**מצב נוכחי:**
ב-[create_screen.dart](file:///c:/Dev/hush-app/lib/screens/create_screen.dart) משתנה `_activeTab` מתחיל ב-0 (שזה כנראה כבר טקסט, אבל צריך לוודא).

**שינויים נדרשים:**

| שכבה | קובץ | פעולה |
|-------|-------|-------|
| **Client** | `lib/screens/create_screen.dart` | ודא ש-`_activeTab` מתחיל ב-`0` (Tab של טקסט) |

**סיכום מאמץ:** נמוך מאוד — אימות + שינוי שורה אחת אם נדרש

---

## 9. ⚙️ הגדרת ברירת מחדל ליצירת האשש (טקסט/קול) בהגדרות

**שינויים נדרשים:**

| שכבה | קובץ | פעולה |
|-------|-------|-------|
| **Client** | `lib/screens/settings_screen.dart` | הוסף אפשרות חדשה "ברירת מחדל ליצירת Hushhh" עם `SegmentedButton` (טקסט / קול) |
| **Firestore** | `users` collection | שדה `defaultCreateMode: 'text'` |
| **Client** | `lib/models/hush_user.dart` | הוסף שדה `defaultCreateMode` |
| **Client** | `lib/screens/create_screen.dart` | ב-`initState`, קרא את ההגדרה ושנה `_activeTab` בהתאם |

**סיכום מאמץ:** בינוני-נמוך

---

## 10. 🚨 איחוד דיווחים כפולים על אותו פוסט

**מצב נוכחי:**
ב-[secret_service.dart.bak](file:///c:/Dev/hush-app/lib/services/secret_service.dart.bak#L322) כבר נעשה שימוש ב-`docId = '${secretId}_${user.uid}'` — כלומר **כבר יש מניעת כפילויות** לפי משתמש!
אבל מכמה משתמשים שונים, נוצרים דיווחים נפרדים.

**שינויים נדרשים:**

| שכבה | קובץ | פעולה |
|-------|-------|-------|
| **Functions** | `functions/src/index.ts` | הוסף trigger `onNewReport` שמאזין ל-`reports/{reportId}` ← כשנוצר, בדוק אם כבר קיימים דיווחים על אותו `secretId`. אם כן, עדכן counter + הוסף את הרפורטר לרשימה במקום ליצור מסמך חדש |
| **Client** | `lib/screens/admin_screen.dart` | בעמוד הדיווחים, הצג `reportCount` ליד כל דיווח ייחודי (למשל "3 דיווחים") |
| **Functions** | (אופציונלי) | אם `reportCount >= 3` — הסתר אוטומטית את ההאשש (`isHidden: true`) עד לבדיקת אדמין |

**סיכום מאמץ:** בינוני

---

## 11. 📊 הצעות לסטטיסטיקות נוספות בפאנל הניהול

הנה רעיונות לסטטיסטיקות שיועילו לניהול:

| סטטיסטיקה | מקור מידע | ערך |
|------------|-----------|------|
| **סה"כ האששים מכל הזמנים** (כולל מחוקים) | counter ב-collection `stats` שגדל בכל create ולא קטן ב-delete | מבט כולל על פעילות |
| **האששים פעילים כרגע** | `secrets` where `isHidden == false` | מצב נוכחי |
| **האששים שנמחקו בדעיכה** | counter שגדל ב-`decaySecretsJob` | אפקטיביות תוכן |
| **ממוצע חיי האשש** (ימים) | חישוב avg של `(deletedAt - createdAt)` | בריאות תוכן |
| **אחוז האששים שנשמרו (saved)** | `saveCount > 0` / total | איכות תוכן |
| **טופ 10 יוצרים** | aggregation לפי `creatorId` | engagement |
| **התפלגות סוג תוכן** | טקסט vs קול vs קבוצתי | מגמות |
| **שיעור דיווחים** | reports / total secrets | בריאות קהילה |
| **משתמשים חדשים (7 ימים)** | users where `createdAt > 7d ago` | צמיחה |
| **משתמשים פעילים (DAU/WAU)** | `lastActive` field | retention |
| **התפלגות דרגות** | group by `tierLevel` | התקדמות |
| **ממוצע לייקים/דיסלייקים להאשש** | avg(likes), avg(dislikes) | sentiment |
| **גרף יצירה יומי** | time series של secret creation | מגמות |

**סיכום מאמץ:** גבוה (תלוי כמה סטטיסטיקות לממש)

---

## 12. 📄 עדכון קבצי MD

**קבצים שיעודכנו:**

| קובץ | שינוי |
|-------|-------|
| [Hushhh_App_Overview.md](file:///c:/Dev/hush-app/docs/AI_Documents/Hushhh_App_Overview.md) | הוספת מידע על רדיוסים (500m feed, 1km map, 15m reveal), מנגנון 24h cache, טאבים בפיד |
| [Hushhh_Architecture_Technical.md](file:///c:/Dev/hush-app/docs/AI_Documents/Hushhh_Architecture_Technical.md) | עדכון Cloud Functions (שעות schedule חדשות, `onUserProfileUpdate`), מנגנון דיווחים, ברירת מחדל ליצירה |
| [hushhh_tiers_logic.md](file:///c:/Dev/hush-app/docs/AI_Documents/hushhh_tiers_logic.md) | הפניה לקובץ הדרגות החדש |

---

## 13. 🏅 קובץ MD מפורט של מערך הדרגות

ייווצר קובץ חדש: `docs/AI_Documents/Hushhh_Tiers_Complete.md`
יכלול: שמות, תרגומים, צבעים (hex), רדיוסי חשיפה, הצלחות נדרשות, משתמשים מקסימליים בקבוצה.

---

## 14. 🚀 דחיפה לגיט

בסיום כל המשימות — `git add -A ; git commit -m "..." ; git push`

---

## סדר עדיפויות מומלץ

| עדיפות | משימה | מאמץ |
|--------|-------|------|
| 🔴 גבוהה | 2. שעות נוטיפיקציות | נמוך מאוד |
| 🔴 גבוהה | 8. ברירת מחדל טקסט | נמוך מאוד |
| 🔴 גבוהה | 4. תיעוד רדיוסים | תיעוד בלבד |
| 🟠 בינונית | 1. cache 24h | בינוני |
| 🟠 בינונית | 3. עדכון שם יוצר | בינוני |
| 🟠 בינונית | 9. הגדרת ברירת מחדל | בינוני-נמוך |
| 🟠 בינונית | 10. איחוד דיווחים | בינוני |
| 🟡 רגילה | 5. טאבים בפיד | גבוה |
| 🟡 רגילה | 6. גישה מנוטיפיקציה | גבוה |
| 🟡 רגילה | 7. הדרכת פיד | גבוה |
| 🟡 רגילה | 11. סטטיסטיקות | גבוה |
| ⚪ סיום | 12. עדכון MD | נמוך |
| ⚪ סיום | 13. קובץ דרגות | נמוך |
| ⚪ סיום | 14. Push Git | — |
