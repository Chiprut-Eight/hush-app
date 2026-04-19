import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ============================================================
// LOCALIZATION: Bilingual notification texts (EN / HE)
// ============================================================
interface LocalizedText {
  en: string;
  he: string;
}

function t(texts: LocalizedText, lang: string): string {
  return lang === "he" ? texts.he : texts.en;
}

// ============================================================
// HELPER: Send push notification to a specific user
// Reads user's 'language' field for localization
// ============================================================
async function sendPushToUser(
  userId: string,
  title: LocalizedText,
  body: LocalizedText,
  data?: { [key: string]: string }
): Promise<void> {
  const userDoc = await db.collection("users").doc(userId).get();
  const userData = userDoc.data();
  const fcmToken = userData?.fcmToken;

  const lang = userData?.language || "en";

  // Persistent Notification History
  try {
    const notifRef = db.collection("users").doc(userId).collection("notifications").doc();
    await notifRef.set({
      title: title, // save the LocalizedText object directly
      body: body,   // save the LocalizedText object directly
      data: data || {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });
  } catch (err) {
    console.error(`Failed to save notification to history for ${userId}:`, err);
  }

  if (!fcmToken) {
    console.log(`No FCM token for user ${userId}, skipping push delivery.`);
    return;
  }

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: t(title, lang),
        body: t(body, lang),
      },
      data: data || {},
      android: {
        priority: "high",
        notification: {
          channelId: "hush_notifications",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
    console.log(`Notification sent to ${userId} [${lang}]: ${t(title, lang)}`);
  } catch (error: any) {
    // If token is invalid, clean it up
    if (
      error.code === "messaging/invalid-registration-token" ||
      error.code === "messaging/registration-token-not-registered"
    ) {
      console.log(`Invalid token for ${userId}, removing.`);
      await db.collection("users").doc(userId).update({
        fcmToken: admin.firestore.FieldValue.delete(),
      });
    } else {
      console.error(`Error sending notification to ${userId}:`, error);
    }
  }
}

// ============================================================
// 1. DECAY CRON JOB — Runs every night at 2:00 AM
//    Respects Immunity (saveCount > 0) and sends notifications
// ============================================================
export const decaySecretsJob = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("Asia/Jerusalem")
  .onRun(async () => {
    const now = new Date();

    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const threeWeeksAgo = new Date(now.getTime() - 21 * 24 * 60 * 60 * 1000);
    const sixtyDaysAgo = new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000);

    const secretsRef = db.collection("secrets");

    // Fetch candidates (only non-hidden)
    const allSecrets = await secretsRef
      .where("isHidden", "==", false)
      .get();

    const batch = db.batch();
    let deleteCount = 0;

    for (const doc of allSecrets.docs) {
      const secret = doc.data();
      const createdAt = secret.createdAt?.toDate();
      if (!createdAt) continue;

      const saveCount = secret.saveCount || 0;

      // IMMUNITY: Skip saved secrets
      if (saveCount > 0) continue;

      let reasonEN = "";
      let reasonHE = "";

      // Rule A: Absolute delete after 60 days
      if (createdAt <= sixtyDaysAgo) {
        reasonEN = "Your Hushhh expired after 60 days";
        reasonHE = "ה-Hushhh שלך פג תוקף לאחר 60 יום";
      }
      // Rule B: 0 listens in 1 week
      else if (createdAt <= oneWeekAgo && (secret.views || 0) === 0) {
        reasonEN = "Your Hushhh had 0 listens in 7 days";
        reasonHE = "ה-Hushhh שלך לא זכה לאף האזנה ב-7 ימים";
      }
      // Rule C: < 5 listens in 3 weeks
      else if (createdAt <= threeWeeksAgo && (secret.views || 0) < 5) {
        reasonEN = "Your Hushhh had less than 5 listens in 21 days";
        reasonHE = "ה-Hushhh שלך לא הגיע ל-5 האזנות ב-21 יום";
      }

      if (reasonEN) {
        // Notify creator before deletion
        if (secret.creatorId) {
          await sendPushToUser(
            secret.creatorId,
            { en: "Hushhh Removed 🗑️", he: "Hushhh הוסר 🗑️" },
            { en: reasonEN, he: reasonHE },
            { type: "decay", secretId: doc.id }
          );
        }

        batch.delete(doc.ref);
        deleteCount++;
      }
    }

    if (deleteCount > 0) {
      await batch.commit();
      console.log(`Decayed ${deleteCount} secrets.`);
    } else {
      console.log("No secrets to decay today.");
    }
  });

// ============================================================
// 2. NEW LIKE — Notify secret creator
// ============================================================
export const onNewLike = functions.firestore
  .document("secrets/{secretId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger if likes increased
    if ((after.likes || 0) <= (before.likes || 0)) return;

    const creatorId = after.creatorId;
    if (!creatorId) return;

    await sendPushToUser(
      creatorId,
      { en: "Someone liked your Hushhh ❤️", he: "מישהו עשה לייק ל-Hushhh שלך ❤️" },
      { en: "Your Hushhh is getting attention!", he: "ה-Hushhh שלך מקבל תשומת לב!" },
      { type: "like", secretId: change.after.id }
    );
  });

// ============================================================
// 3. NEW COMMENT — Notify secret creator
// ============================================================
export const onNewComment = functions.firestore
  .document("secrets/{secretId}/comments/{commentId}")
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const secretId = context.params.secretId;

    // Get the secret to find the creator
    const secretDoc = await db.collection("secrets").doc(secretId).get();
    if (!secretDoc.exists) return;

    const secret = secretDoc.data();
    const creatorId = secret?.creatorId;
    if (!creatorId) return;

    // Don't notify if the creator commented on their own secret
    if (comment.userId === creatorId) return;

    const commenterName = comment.userName || "Someone";
    const commentPreview = comment.text?.substring(0, 100) || "";

    await sendPushToUser(
      creatorId,
      {
        en: `${commenterName} commented 💬`,
        he: `${commenterName} הגיב/ה 💬`,
      },
      {
        en: commentPreview || "New comment on your Hushhh",
        he: commentPreview || "תגובה חדשה על ה-Hushhh שלך",
      },
      { type: "comment", secretId }
    );
  });

// ============================================================
// 4. NEW FOLLOWER — Notify the followed user
// ============================================================
export const onNewFollower = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change) => {
    const beforeFollowers: string[] = change.before.data().followerIds || [];
    const afterFollowers: string[] = change.after.data().followerIds || [];

    // Only trigger if followers increased
    if (afterFollowers.length <= beforeFollowers.length) return;

    // Find new follower(s)
    const newFollowers = afterFollowers.filter(
      (id) => !beforeFollowers.includes(id)
    );

    const targetUserId = change.after.id;

    for (const followerId of newFollowers) {
      // Get follower name
      const followerDoc = await db.collection("users").doc(followerId).get();
      const followerName =
        followerDoc.data()?.displayName ||
        `${followerDoc.data()?.firstName || ""} ${
          followerDoc.data()?.lastName || ""
        }`.trim() ||
        "Someone";

      await sendPushToUser(
        targetUserId,
        {
          en: `${followerName} followed you 👋`,
          he: `${followerName} עוקב/ת אחריך 👋`,
        },
        {
          en: "You have a new follower!",
          he: "יש לך עוקב/ת חדש/ה!",
        },
        { type: "follower", followerId }
      );
    }
  });

// ============================================================
// 5. FOLLOWED USER PUBLISHED — Notify followers
// ============================================================
export const onNewSecret = functions.firestore
  .document("secrets/{secretId}")
  .onCreate(async (snap) => {
    const secret = snap.data();
    const creatorId = secret.creatorId;
    if (!creatorId) return;

    // Get creator info
    const creatorDoc = await db.collection("users").doc(creatorId).get();
    if (!creatorDoc.exists) return;

    const creator = creatorDoc.data();
    const creatorName =
      creator?.displayName ||
      `${creator?.firstName || ""} ${creator?.lastName || ""}`.trim() ||
      "Someone";

    // Get followers of the creator
    const followerIds: string[] = creator?.followerIds || [];
    if (followerIds.length === 0) return;

    // Send notification to each follower (max 50 to avoid timeout)
    const batchFollowers = followerIds.slice(0, 50);

    const promises = batchFollowers.map((followerId) =>
      sendPushToUser(
        followerId,
        {
          en: `${creatorName} planted a new Hushhh 🌱`,
          he: `${creatorName} הטמין/ה Hushhh חדש 🌱`,
        },
        {
          en: "Go explore and find it!",
          he: "צאו לחפש ולגלות!",
        },
        { type: "new_secret", secretId: snap.id, creatorId }
      )
    );

    await Promise.all(promises);
  });

// ============================================================
// 6. EXPIRING SOON — Daily cron at 10:00 AM
//    Warns creators 48 hours before their Hushhh is deleted
//    Covers ALL 3 decay rules (60-day, 0 views/7 days, <5 views/21 days)
// ============================================================
export const onSecretExpiringSoon = functions.pubsub
  .schedule("0 10 * * *")
  .timeZone("Asia/Jerusalem")
  .onRun(async () => {
    const now = new Date();

    // Rule A: 60-day absolute expiry → warn at day 58
    const fiftyEightDaysAgo = new Date(now.getTime() - 58 * 24 * 60 * 60 * 1000);
    const fiftySevenDaysAgo = new Date(now.getTime() - 57 * 24 * 60 * 60 * 1000);

    // Rule B: 0 views in 7 days → warn at day 5 (2 days before cutoff)
    const fiveDaysAgo = new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000);
    const fourDaysAgo = new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000);

    // Rule C: <5 views in 21 days → warn at day 19 (2 days before cutoff)
    const nineteenDaysAgo = new Date(now.getTime() - 19 * 24 * 60 * 60 * 1000);
    const eighteenDaysAgo = new Date(now.getTime() - 18 * 24 * 60 * 60 * 1000);

    const allSecrets = await db.collection("secrets")
      .where("isHidden", "==", false)
      .get();

    let notifiedCount = 0;

    for (const doc of allSecrets.docs) {
      const secret = doc.data();
      const createdAt = secret.createdAt?.toDate();
      if (!createdAt || !secret.creatorId) continue;

      // IMMUNITY: Don't warn about saved secrets
      if ((secret.saveCount || 0) > 0) continue;

      const views = secret.views || 0;
      let warningEN = "";
      let warningHE = "";

      // Rule A: Approaching 60-day absolute expiry
      if (createdAt <= fiftyEightDaysAgo && createdAt >= fiftySevenDaysAgo) {
        warningEN = "Your Hushhh has been alive for 58 days and will be deleted in 2 days. Save it now to protect it forever!";
        warningHE = "ה-Hushhh שלך קיים כבר 58 ימים ויימחק בעוד יומיים. שמור אותו עכשיו כדי לשמר אותו לנצח!";
      }
      // Rule B: 0 views after 5 days (will hit 7-day cutoff in 2 days)
      else if (createdAt <= fiveDaysAgo && createdAt >= fourDaysAgo && views === 0) {
        warningEN = "Your Hushhh has had 0 views in 5 days. It will be deleted in 2 days unless someone discovers it. Share a hint nearby!";
        warningHE = "ה-Hushhh שלך לא קיבל אף צפייה ב-5 ימים. הוא יימחק בעוד יומיים אלא אם מישהו יגלה אותו. שתף רמז בקרבת מקום!";
      }
      // Rule C: <5 views after 19 days (will hit 21-day cutoff in 2 days)
      else if (createdAt <= nineteenDaysAgo && createdAt >= eighteenDaysAgo && views < 5) {
        warningEN = `Your Hushhh has only ${views} view${views === 1 ? "" : "s"} after 19 days. It will be deleted in 2 days. Save it to keep it forever!`;
        warningHE = `ל-Hushhh שלך יש רק ${views} ${views === 1 ? "צפייה" : "צפיות"} אחרי 19 ימים. הוא יימחק בעוד יומיים. שמור אותו כדי לשמר א­ותו לנצח!`;
      }

      if (warningEN && secret.creatorId) {
        await sendPushToUser(
          secret.creatorId,
          { en: "⚠️ Your Hushhh is about to be deleted", he: "⚠️ ה-Hushhh שלך עומד להימחק" },
          { en: warningEN, he: warningHE },
          { type: "expiring", secretId: doc.id }
        );
        notifiedCount++;
      }
    }

    console.log(`Sent ${notifiedCount} expiring-soon notifications.`);
  });

// ============================================================
// 7. VERIFY GROUP UNLOCK (existing)
// ============================================================
export const verifyGroupUnlock = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth)
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in"
      );

    const { secretId, userLat, userLng } = data;
    const uid = context.auth.uid;

    if (!secretId || !userLat || !userLng) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters"
      );
    }

    const secretRef = db.collection("secrets").doc(secretId);
    const secretSnap = await secretRef.get();

    if (!secretSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Secret not found.");
    }

    const secret = secretSnap.data();
    if (!secret?.isGroup) {
      return { success: true, message: "Not a group secret." };
    }

    const requiredUsers = secret.requiredUsers || 3;
    const timeWindowMinutes = secret.timeWindowMinutes || 5;

    // Calculate cutoff time
    const cutoff = new Date();
    cutoff.setMinutes(cutoff.getMinutes() - timeWindowMinutes);

    // Record this user's unlock attempt
    const attemptsRef = secretRef.collection("unlockAttempts");
    await attemptsRef.doc(uid).set({
      lat: userLat,
      lng: userLng,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    const recentAttemptsSnap = await attemptsRef
      .orderBy("timestamp")
      .startAt(admin.firestore.Timestamp.fromDate(cutoff))
      .get();
    const recentAttempts = recentAttemptsSnap.docs;

    if (recentAttempts.length >= requiredUsers) {
      const unlockedUids = recentAttempts.map((d: any) => d.id);

      await secretRef.update({
        unlockedBy: admin.firestore.FieldValue.arrayUnion(...unlockedUids),
      });

      if (secret.creatorId) {
        // Award Clout to creator
        await db.collection("users").doc(secret.creatorId).update({
          groupSuccesses: admin.firestore.FieldValue.increment(1),
        });
      }

      return { success: true, message: "Group secret unlocked!" };
    }

    return {
      success: false,
      message: `Need ${
        requiredUsers - recentAttempts.length
      } more people within ${timeWindowMinutes} minutes.`,
      currentCount: recentAttempts.length,
      requiredCount: requiredUsers,
    };
  }
);
