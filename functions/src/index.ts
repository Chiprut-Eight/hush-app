import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();

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

        // Delete audio file from Storage if voice secret
        if (secret.type === "voice") {
          try {
            const bucket = storage.bucket();
            const file = bucket.file(`audio/${doc.id}.m4a`);
            const [exists] = await file.exists();
            if (exists) await file.delete();

            // Also try URL-based path for pre-migration secrets
            if (secret.audioURL) {
              const pathMatch = secret.audioURL.match(/\/o\/(.+?)\?/);
              if (pathMatch) {
                const filePath = decodeURIComponent(pathMatch[1]);
                const altFile = bucket.file(filePath);
                const [altExists] = await altFile.exists();
                if (altExists) await altFile.delete();
              }
            }
          } catch (err) {
            console.error(`Decay: failed to delete audio for ${doc.id}:`, err);
          }
        }

        // Delete content subcollection
        try {
          await doc.ref.collection("content").doc("data").delete();
        } catch (_) { /* may not exist */ }

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

    const commenterName = comment.userName || "Someone";
    const commentPreview = comment.text?.substring(0, 100) || "";
    const replyToUserId = comment.replyToUserId;

    // 1. Notify the user being replied to (if any and it's not themselves)
    if (replyToUserId && replyToUserId !== comment.userId) {
      await sendPushToUser(
        replyToUserId,
        {
          en: `${commenterName} replied to you 💬`,
          he: `${commenterName} הגיב/ה לך 💬`,
        },
        {
          en: commentPreview || "New reply to your comment",
          he: commentPreview || "תגובה חדשה לתגובה שלך",
        },
        { type: "comment", secretId }
      );
    }

    // 2. Notify the secret creator (if they are not the ones commenting, and if they weren't just notified as the reply target)
    if (creatorId !== comment.userId && creatorId !== replyToUserId) {
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
    }
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
// 6. EXPIRING SOON — Daily cron at MIDNIGHT (00:00)
//    MUST run BEFORE decaySecretsJob (02:00) so warnings go out first.
//    Warns creators ~48 hours before their Hushhh is deleted.
//    Covers ALL 3 decay rules (60-day, 0 views/7 days, <5 views/21 days)
//    Uses 2-day wide windows to prevent secrets from "jumping" over
//    the detection range between daily cron runs.
// ============================================================
export const onSecretExpiringSoon = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("Asia/Jerusalem")
  .onRun(async () => {
    const now = new Date();

    // Rule A: 60-day absolute expiry → warn between day 56-58
    //   (2-day window ensures we catch it regardless of creation time)
    const fiftyEightDaysAgo = new Date(now.getTime() - 58 * 24 * 60 * 60 * 1000);
    const fiftySixDaysAgo = new Date(now.getTime() - 56 * 24 * 60 * 60 * 1000);

    // Rule B: 0 views in 7 days → warn between day 5-7
    //   (warn up until the cutoff; decay job at 02:00 handles deletion)
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const fiveDaysAgo = new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000);

    // Rule C: <5 views in 21 days → warn between day 19-21
    const twentyOneDaysAgo = new Date(now.getTime() - 21 * 24 * 60 * 60 * 1000);
    const nineteenDaysAgo = new Date(now.getTime() - 19 * 24 * 60 * 60 * 1000);

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

      // Skip if already warned (prevents duplicate notifications)
      if (secret.expiryWarned === true) continue;

      const views = secret.views || 0;
      let warningEN = "";
      let warningHE = "";

      // Rule A: Approaching 60-day absolute expiry
      if (createdAt <= fiftySixDaysAgo && createdAt >= fiftyEightDaysAgo) {
        warningEN = "Your Hushhh has been alive for over 56 days and will be deleted soon. Save it now to protect it forever!";
        warningHE = "ה-Hushhh שלך קיים כבר מעל 56 ימים ויימחק בקרוב. שמור אותו עכשיו כדי לשמר אותו לנצח!";
      }
      // Rule B: 0 views between day 5-7 (will hit 7-day cutoff)
      else if (createdAt <= fiveDaysAgo && createdAt >= sevenDaysAgo && views === 0) {
        warningEN = "Your Hushhh has had 0 views and will be deleted soon unless someone discovers it. Share a hint nearby!";
        warningHE = "ה-Hushhh שלך לא קיבל אף צפייה ויימחק בקרוב אלא אם מישהו יגלה אותו. שתף רמז בקרבת מקום!";
      }
      // Rule C: <5 views between day 19-21 (will hit 21-day cutoff)
      else if (createdAt <= nineteenDaysAgo && createdAt >= twentyOneDaysAgo && views < 5) {
        warningEN = `Your Hushhh has only ${views} view${views === 1 ? "" : "s"} and will be deleted soon. Save it to keep it forever!`;
        warningHE = `ל-Hushhh שלך יש רק ${views} ${views === 1 ? "צפייה" : "צפיות"} ויימחק בקרוב. שמור אותו כדי לשמר אותו לנצח!`;
      }

      if (warningEN && secret.creatorId) {
        await sendPushToUser(
          secret.creatorId,
          { en: "⚠️ Your Hushhh is about to be deleted", he: "⚠️ ה-Hushhh שלך עומד להימחק" },
          { en: warningEN, he: warningHE },
          { type: "expiring", secretId: doc.id }
        );

        // Mark as warned to prevent duplicate notifications
        await doc.ref.update({ expiryWarned: true });

        notifiedCount++;
      }
    }

    console.log(`Sent ${notifiedCount} expiring-soon notifications.`);
  });

// ============================================================
// UTILITY: Haversine distance in meters
// ============================================================
function distanceInMeters(
  lat1: number, lng1: number, lat2: number, lng2: number
): number {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ============================================================
// UTILITY: Tier reveal radius mapping (mirrors client tiers.dart)
// ============================================================
const TIER_REVEAL_RADIUS: Record<number, number> = {
  1: 15, 2: 15, 3: 15, 4: 15, 5: 30,
  6: 40, 7: 60, 8: 80, 9: 100, 10: 150,
};

function getRevealRadius(tierLevel: number, isGroup: boolean): number {
  if (!isGroup) return 15; // Regular secrets always 15m
  return TIER_REVEAL_RADIUS[tierLevel] || 15;
}

// ============================================================
// UTILITY: Simple in-memory rate limiter
// ============================================================
const rateLimitMap: Record<string, { count: number; resetAt: number }> = {};

function checkRateLimit(
  key: string, maxPerMinute: number
): boolean {
  const now = Date.now();
  const entry = rateLimitMap[key];
  if (!entry || now > entry.resetAt) {
    rateLimitMap[key] = { count: 1, resetAt: now + 60000 };
    return true;
  }
  if (entry.count >= maxPerMinute) return false;
  entry.count++;
  return true;
}

// ============================================================
// UTILITY: GPS velocity check
// ============================================================
const lastLocationMap: Record<string, { lat: number; lng: number; ts: number }> = {};

function checkVelocity(uid: string, lat: number, lng: number): boolean {
  const now = Date.now();
  const last = lastLocationMap[uid];
  lastLocationMap[uid] = { lat, lng, ts: now };

  if (!last) return true; // First reading

  const elapsed = (now - last.ts) / 1000; // seconds
  if (elapsed < 1) return true; // Too close in time to judge

  const dist = distanceInMeters(last.lat, last.lng, lat, lng);
  const speed = dist / elapsed; // m/s
  // 83 m/s ≈ 300 km/h — reject anything faster
  return speed <= 83;
}

// ============================================================
// 7. VERIFY GROUP UNLOCK — With distance + IP uniqueness
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

    if (!secretId || userLat == null || userLng == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters"
      );
    }

    // Rate limit: 10 per minute
    if (!checkRateLimit(`groupUnlock:${uid}`, 10)) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Too many requests. Try again later."
      );
    }

    // Velocity check
    if (!checkVelocity(uid, userLat, userLng)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Location change too rapid."
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

    // ---- NEW: Distance check ----
    const secretLat = secret.lat;
    const secretLng = secret.lng;
    const tierLevel = secret.creatorTierLevel || 1;
    const revealRadius = getRevealRadius(tierLevel, true);
    const dist = distanceInMeters(userLat, userLng, secretLat, secretLng);

    if (dist > revealRadius) {
      return {
        success: false,
        message: `Too far from the secret (${Math.round(dist)}m). Need to be within ${revealRadius}m.`,
      };
    }

    const requiredUsers = secret.requiredUsers || 3;
    const timeWindowMinutes = secret.timeWindowMinutes || 5;

    const cutoff = new Date();
    cutoff.setMinutes(cutoff.getMinutes() - timeWindowMinutes);

    // Record this user's unlock attempt
    const attemptsRef = secretRef.collection("unlockAttempts");

    // ---- NEW: IP uniqueness check ----
    const rawIp =
      (context.rawRequest?.headers?.["x-forwarded-for"] as string)?.split(",")[0]?.trim() ||
      context.rawRequest?.ip ||
      "unknown";

    await attemptsRef.doc(uid).set({
      lat: userLat,
      lng: userLng,
      ip: rawIp,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    const recentAttemptsSnap = await attemptsRef
      .orderBy("timestamp")
      .startAt(admin.firestore.Timestamp.fromDate(cutoff))
      .get();
    const recentAttempts = recentAttemptsSnap.docs;

    // ---- NEW: Deduplicate by IP ----
    const uniqueIps = new Set<string>();
    const uniqueAttempts = recentAttempts.filter((d: any) => {
      const ip = d.data()?.ip || "unknown";
      if (uniqueIps.has(ip)) return false;
      uniqueIps.add(ip);
      return true;
    });

    if (uniqueAttempts.length >= requiredUsers) {
      const unlockedUids = uniqueAttempts.map((d: any) => d.id);

      await secretRef.update({
        unlockedBy: admin.firestore.FieldValue.arrayUnion(...unlockedUids),
      });

      if (secret.creatorId) {
        await db.collection("users").doc(secret.creatorId).update({
          groupSuccesses: admin.firestore.FieldValue.increment(1),
        });
      }

      return { success: true, message: "Group secret unlocked!" };
    }

    return {
      success: false,
      message: `Need ${
        requiredUsers - uniqueAttempts.length
      } more people within ${timeWindowMinutes} minutes.`,
      currentCount: uniqueAttempts.length,
      requiredCount: requiredUsers,
    };
  }
);

// ============================================================
// 8. REVEAL SECRET — Server-side content access with proximity check
// ============================================================
export const revealSecret = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth)
      throw new functions.https.HttpsError("unauthenticated", "Login required");

    const { secretId, userLat, userLng } = data;
    const uid = context.auth.uid;

    if (!secretId) {
      throw new functions.https.HttpsError("invalid-argument", "Missing secretId");
    }

    // Rate limit: 30 per minute
    if (!checkRateLimit(`reveal:${uid}`, 30)) {
      throw new functions.https.HttpsError("resource-exhausted", "Too many requests");
    }

    // Velocity check (only if location provided)
    if (userLat != null && userLng != null) {
      if (!checkVelocity(uid, userLat, userLng)) {
        throw new functions.https.HttpsError("permission-denied", "Location change too rapid");
      }
    }

    // Fetch secret metadata
    const secretRef = db.collection("secrets").doc(secretId);
    const secretSnap = await secretRef.get();

    if (!secretSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Secret not found");
    }

    const secret = secretSnap.data()!;

    // --- Access decision ---
    let allowed = false;

    // 1. Creator always has access
    if (secret.creatorId === uid) {
      allowed = true;
    }

    // 2. User has saved this secret → access from anywhere
    if (!allowed) {
      const userDoc = await db.collection("users").doc(uid).get();
      const savedIds: string[] = userDoc.data()?.savedSecretIds || [];
      if (savedIds.includes(secretId)) {
        allowed = true;
      }
    }

    // 3. Already unlocked (group secret)
    if (!allowed && secret.isGroup) {
      const unlockedBy: string[] = secret.unlockedBy || [];
      if (unlockedBy.includes(uid)) {
        allowed = true;
      }
    }

    // 4. Proximity check for regular secrets
    if (!allowed) {
      if (userLat == null || userLng == null) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Location required to reveal this secret"
        );
      }

      const tierLevel = secret.creatorTierLevel || 1;
      const revealRadius = getRevealRadius(tierLevel, secret.isGroup || false);
      const dist = distanceInMeters(userLat, userLng, secret.lat, secret.lng);

      if (dist > revealRadius) {
        throw new functions.https.HttpsError(
          "permission-denied",
          `Too far (${Math.round(dist)}m). Must be within ${revealRadius}m.`
        );
      }

      // Group secrets require group unlock flow, not individual reveal
      if (secret.isGroup) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Group secret requires group unlock"
        );
      }

      allowed = true;
    }

    if (!allowed) {
      throw new functions.https.HttpsError("permission-denied", "Access denied");
    }

    // --- Fetch content ---
    // Try protected subcollection first (new format)
    const contentSnap = await secretRef.collection("content").doc("data").get();

    let textContent: string | null = null;
    let audioURL: string | null = null;
    let audioDuration: number = 0;

    if (contentSnap.exists) {
      const contentData = contentSnap.data()!;
      textContent = contentData.textContent || null;
      audioURL = contentData.audioURL || null;
      audioDuration = contentData.audioDuration || 0;
    } else {
      // Fallback: read from main doc (pre-migration secrets)
      textContent = secret.textContent || null;
      audioURL = secret.audioURL || null;
      audioDuration = secret.audioDuration || 0;
    }

    // For audio: generate a signed URL (expires in 15 minutes)
    let signedAudioURL: string | null = null;
    if (audioURL) {
      try {
        // Extract storage path from download URL
        const pathMatch = audioURL.match(/\/o\/(.+?)\?/);
        if (pathMatch) {
          const filePath = decodeURIComponent(pathMatch[1]);
          const bucket = storage.bucket();
          const file = bucket.file(filePath);
          const [url] = await file.getSignedUrl({
            action: "read",
            expires: Date.now() + 15 * 60 * 1000, // 15 minutes
          });
          signedAudioURL = url;
        } else {
          // If we can't parse, return original (backward compat)
          signedAudioURL = audioURL;
        }
      } catch (err) {
        console.error("Failed to generate signed URL, using original:", err);
        signedAudioURL = audioURL;
      }
    }

    return {
      success: true,
      textContent,
      audioURL: signedAudioURL,
      audioDuration,
    };
  }
);

// ============================================================
// 9. CREATE SECRET V2 — Content stored in protected subcollection
// ============================================================
export const createSecretV2 = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth)
      throw new functions.https.HttpsError("unauthenticated", "Login required");

    const uid = context.auth.uid;

    const {
      type, textContent, audioURL, audioDuration,
      lat, lng, isGroup, requiredUsers, timeWindowMinutes,
    } = data;

    if (!type || lat == null || lng == null) {
      throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
    }
    if (type === "text" && (!textContent || textContent.length > 140)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid text content");
    }
    if (type === "voice" && !audioURL) {
      throw new functions.https.HttpsError("invalid-argument", "Missing audio URL");
    }

    // Rate limit: 5 creates per minute
    if (!checkRateLimit(`create:${uid}`, 5)) {
      throw new functions.https.HttpsError("resource-exhausted", "Too many requests");
    }

    // Get creator profile
    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data() || {};

    const creatorName =
      `${userData.firstName || ""} ${userData.lastName || ""}`.trim() ||
      userData.displayName || "Anonymous";
    const creatorPhotoURL = userData.useGenericPhoto ? "generic" : (userData.photoURL || null);
    const tierLevel = userData.tierLevel || 1;
    const tierColors: Record<number, string> = {
      1: "#8b8b8b", 2: "#4a9eff", 3: "#34d399", 4: "#fbbf24", 5: "#f97316",
      6: "#ef4444", 7: "#a855f7", 8: "#ec4899", 9: "#06b6d4", 10: "#ffd700",
    };

    // Create the secret document (metadata only — NO content fields)
    const secretRef = db.collection("secrets").doc();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    await secretRef.set({
      creatorId: uid,
      creatorName,
      creatorPhotoURL,
      creatorTierLevel: tierLevel,
      creatorTierColor: tierColors[tierLevel] || "#8b8b8b",
      type,
      lat,
      lng,
      views: 0,
      likes: 0,
      dislikes: 0,
      saveCount: 0,
      isGroup: isGroup || false,
      minTierLevel: null,
      requiredUsers: isGroup ? (requiredUsers || 3) : null,
      timeWindowMinutes: isGroup ? (timeWindowMinutes || 5) : null,
      unlockedBy: [],
      reportCount: 0,
      commentCount: 0,
      isHidden: false,
      createdAt: admin.firestore.Timestamp.fromDate(now),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      // Keep type info for display but NOT content
      audioDuration: type === "voice" ? (audioDuration || 0) : 0,
    });

    // Store content in protected subcollection
    const contentData: any = {};
    if (type === "text") {
      contentData.textContent = textContent;
    } else if (type === "voice") {
      contentData.audioURL = audioURL;
      contentData.audioDuration = audioDuration || 0;
    }
    await secretRef.collection("content").doc("data").set(contentData);

    // Increment published count
    await db.collection("users").doc(uid).update({
      totalPublished: admin.firestore.FieldValue.increment(1),
    });

    return { success: true, secretId: secretRef.id };
  }
);

// ============================================================
// 10. DELETE SECRET V2 — Deletes secret + content + storage file
// ============================================================
export const deleteSecretV2 = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth)
      throw new functions.https.HttpsError("unauthenticated", "Login required");

    const uid = context.auth.uid;
    const { secretId } = data;

    if (!secretId) {
      throw new functions.https.HttpsError("invalid-argument", "Missing secretId");
    }

    const secretRef = db.collection("secrets").doc(secretId);
    const secretSnap = await secretRef.get();

    if (!secretSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Secret not found");
    }

    const secret = secretSnap.data()!;

    // Only creator or admin can delete
    const userDoc = await db.collection("users").doc(uid).get();
    const isAdmin = userDoc.data()?.isAdmin === true;

    if (secret.creatorId !== uid && !isAdmin) {
      throw new functions.https.HttpsError("permission-denied", "Not the creator");
    }

    // Delete audio file from Storage if voice secret
    if (secret.type === "voice") {
      try {
        // Try standard path first
        const bucket = storage.bucket();
        const file = bucket.file(`audio/${secretId}.m4a`);
        const [exists] = await file.exists();
        if (exists) await file.delete();

        // Also try to extract path from audioURL (pre-migration)
        const audioURL = secret.audioURL;
        if (audioURL) {
          const pathMatch = audioURL.match(/\/o\/(.+?)\?/);
          if (pathMatch) {
            const filePath = decodeURIComponent(pathMatch[1]);
            const altFile = bucket.file(filePath);
            const [altExists] = await altFile.exists();
            if (altExists) await altFile.delete();
          }
        }
      } catch (err) {
        console.error(`Failed to delete audio for ${secretId}:`, err);
      }
    }

    // Delete content subcollection
    try {
      await secretRef.collection("content").doc("data").delete();
    } catch (_) { /* may not exist for old secrets */ }

    // Delete the secret document
    await secretRef.delete();

    // Decrement published count
    await db.collection("users").doc(secret.creatorId).update({
      totalPublished: admin.firestore.FieldValue.increment(-1),
    });

    return { success: true };
  }
);

// ============================================================
// 11. INTERACT WITH SECRET — Like/Unlike/Dislike/Undislike/View
// ============================================================
export const interactWithSecret = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth)
      throw new functions.https.HttpsError("unauthenticated", "Login required");

    const uid = context.auth.uid;
    const { secretId, action } = data;

    if (!secretId || !action) {
      throw new functions.https.HttpsError("invalid-argument", "Missing params");
    }

    // Rate limit: 60 per minute
    if (!checkRateLimit(`interact:${uid}`, 60)) {
      throw new functions.https.HttpsError("resource-exhausted", "Too many requests");
    }

    const secretRef = db.collection("secrets").doc(secretId);

    switch (action) {
      case "like":
        await secretRef.update({ likes: admin.firestore.FieldValue.increment(1) });
        break;
      case "unlike":
        await secretRef.update({ likes: admin.firestore.FieldValue.increment(-1) });
        break;
      case "dislike":
        await secretRef.update({ dislikes: admin.firestore.FieldValue.increment(1) });
        break;
      case "undislike":
        await secretRef.update({ dislikes: admin.firestore.FieldValue.increment(-1) });
        break;
      case "view":
        // Unique view tracking
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(secretRef);
          if (!snap.exists) return;
          const d = snap.data()!;
          const viewedBy: string[] = d.viewedBy || [];
          if (!viewedBy.includes(uid)) {
            viewedBy.push(uid);
            tx.update(secretRef, {
              viewedBy,
              views: admin.firestore.FieldValue.increment(1),
            });
          }
        });
        break;
      default:
        throw new functions.https.HttpsError("invalid-argument", `Unknown action: ${action}`);
    }

    return { success: true };
  }
);

// ============================================================
// 12. MIGRATE EXISTING SECRETS — One-time admin function
//     Copies textContent/audioURL to content subcollection
// ============================================================
export const migrateSecretContent = functions.https.onCall(
  async (_data: any, context: functions.https.CallableContext) => {
    if (!context.auth)
      throw new functions.https.HttpsError("unauthenticated", "Login required");

    // Admin only
    const userDoc = await db.collection("users").doc(context.auth.uid).get();
    if (userDoc.data()?.isAdmin !== true) {
      throw new functions.https.HttpsError("permission-denied", "Admin only");
    }

    const allSecrets = await db.collection("secrets").get();
    let migrated = 0;

    for (const doc of allSecrets.docs) {
      const data = doc.data();
      const contentRef = doc.ref.collection("content").doc("data");
      const contentSnap = await contentRef.get();

      // Skip if already migrated
      if (contentSnap.exists) continue;

      const contentData: any = {};
      if (data.type === "text" && data.textContent) {
        contentData.textContent = data.textContent;
      }
      if (data.type === "voice" && data.audioURL) {
        contentData.audioURL = data.audioURL;
        contentData.audioDuration = data.audioDuration || 0;
      }

      if (Object.keys(contentData).length > 0) {
        await contentRef.set(contentData);
        migrated++;
      }
    }

    return { success: true, migrated, total: allSecrets.size };
  }
);

