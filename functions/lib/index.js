"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyGroupUnlock = exports.onSecretExpiringSoon = exports.onNewSecret = exports.onNewFollower = exports.onNewComment = exports.onNewLike = exports.decaySecretsJob = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
// ============================================================
// HELPER: Send push notification to a specific user
// ============================================================
async function sendPushToUser(userId, title, body, data) {
    var _a;
    const userDoc = await db.collection("users").doc(userId).get();
    const fcmToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
    if (!fcmToken) {
        console.log(`No FCM token for user ${userId}, skipping notification.`);
        return;
    }
    try {
        await admin.messaging().send({
            token: fcmToken,
            notification: { title, body },
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
        console.log(`Notification sent to ${userId}: ${title}`);
    }
    catch (error) {
        // If token is invalid, clean it up
        if (error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered") {
            console.log(`Invalid token for ${userId}, removing.`);
            await db.collection("users").doc(userId).update({
                fcmToken: admin.firestore.FieldValue.delete(),
            });
        }
        else {
            console.error(`Error sending notification to ${userId}:`, error);
        }
    }
}
// ============================================================
// 1. DECAY CRON JOB — Runs every night at 2:00 AM
//    Now respects Immunity (saveCount > 0) and sends notifications
// ============================================================
exports.decaySecretsJob = functions.pubsub
    .schedule("0 2 * * *")
    .timeZone("Asia/Jerusalem")
    .onRun(async () => {
    var _a;
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
        const createdAt = (_a = secret.createdAt) === null || _a === void 0 ? void 0 : _a.toDate();
        if (!createdAt)
            continue;
        const saveCount = secret.saveCount || 0;
        // IMMUNITY: Skip saved secrets
        if (saveCount > 0)
            continue;
        let reason = "";
        // Rule A: Absolute delete after 60 days
        if (createdAt <= sixtyDaysAgo) {
            reason = "Hushhh expired (60 days)";
        }
        // Rule B: 0 listens in 1 week
        else if (createdAt <= oneWeekAgo && (secret.views || 0) === 0) {
            reason = "Hushhh had 0 listens in 7 days";
        }
        // Rule C: < 5 listens in 3 weeks
        else if (createdAt <= threeWeeksAgo && (secret.views || 0) < 5) {
            reason = "Hushhh had less than 5 listens in 21 days";
        }
        if (reason) {
            // Notify creator before deletion
            if (secret.creatorId) {
                await sendPushToUser(secret.creatorId, "Hushhh Removed 🗑️", reason, { type: "decay", secretId: doc.id });
            }
            batch.delete(doc.ref);
            deleteCount++;
        }
    }
    if (deleteCount > 0) {
        await batch.commit();
        console.log(`Decayed ${deleteCount} secrets.`);
    }
    else {
        console.log("No secrets to decay today.");
    }
});
// ============================================================
// 2. NEW LIKE — Notify secret creator
// ============================================================
exports.onNewLike = functions.firestore
    .document("secrets/{secretId}")
    .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    // Only trigger if likes increased
    if ((after.likes || 0) <= (before.likes || 0))
        return;
    const creatorId = after.creatorId;
    if (!creatorId)
        return;
    await sendPushToUser(creatorId, "Someone liked your Hushhh ❤️", "Your Hushhh is getting attention!", { type: "like", secretId: change.after.id });
});
// ============================================================
// 3. NEW COMMENT — Notify secret creator
// ============================================================
exports.onNewComment = functions.firestore
    .document("secrets/{secretId}/comments/{commentId}")
    .onCreate(async (snap, context) => {
    var _a;
    const comment = snap.data();
    const secretId = context.params.secretId;
    // Get the secret to find the creator
    const secretDoc = await db.collection("secrets").doc(secretId).get();
    if (!secretDoc.exists)
        return;
    const secret = secretDoc.data();
    const creatorId = secret === null || secret === void 0 ? void 0 : secret.creatorId;
    if (!creatorId)
        return;
    // Don't notify if the creator commented on their own secret
    if (comment.userId === creatorId)
        return;
    const commenterName = comment.userName || "Someone";
    await sendPushToUser(creatorId, `${commenterName} commented 💬`, ((_a = comment.text) === null || _a === void 0 ? void 0 : _a.substring(0, 100)) || "New comment on your Hushhh", { type: "comment", secretId });
});
// ============================================================
// 4. NEW FOLLOWER — Notify the followed user
// ============================================================
exports.onNewFollower = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change) => {
    var _a, _b, _c;
    const beforeFollowers = change.before.data().followerIds || [];
    const afterFollowers = change.after.data().followerIds || [];
    // Only trigger if followers increased
    if (afterFollowers.length <= beforeFollowers.length)
        return;
    // Find new follower(s)
    const newFollowers = afterFollowers.filter((id) => !beforeFollowers.includes(id));
    const targetUserId = change.after.id;
    for (const followerId of newFollowers) {
        // Get follower name
        const followerDoc = await db.collection("users").doc(followerId).get();
        const followerName = ((_a = followerDoc.data()) === null || _a === void 0 ? void 0 : _a.displayName) ||
            `${((_b = followerDoc.data()) === null || _b === void 0 ? void 0 : _b.firstName) || ""} ${((_c = followerDoc.data()) === null || _c === void 0 ? void 0 : _c.lastName) || ""}`.trim() ||
            "Someone";
        await sendPushToUser(targetUserId, `${followerName} followed you 👋`, "You have a new follower!", { type: "follower", followerId });
    }
});
// ============================================================
// 5. FOLLOWED USER PUBLISHED — Notify followers
// ============================================================
exports.onNewSecret = functions.firestore
    .document("secrets/{secretId}")
    .onCreate(async (snap) => {
    const secret = snap.data();
    const creatorId = secret.creatorId;
    if (!creatorId)
        return;
    // Get creator info
    const creatorDoc = await db.collection("users").doc(creatorId).get();
    if (!creatorDoc.exists)
        return;
    const creator = creatorDoc.data();
    const creatorName = (creator === null || creator === void 0 ? void 0 : creator.displayName) ||
        `${(creator === null || creator === void 0 ? void 0 : creator.firstName) || ""} ${(creator === null || creator === void 0 ? void 0 : creator.lastName) || ""}`.trim() ||
        "Someone";
    // Get followers of the creator
    const followerIds = (creator === null || creator === void 0 ? void 0 : creator.followerIds) || [];
    if (followerIds.length === 0)
        return;
    // Send notification to each follower (max 50 to avoid timeout)
    const batchFollowers = followerIds.slice(0, 50);
    const promises = batchFollowers.map((followerId) => sendPushToUser(followerId, `${creatorName} planted a new Hushhh 🌱`, "Go explore and find it!", { type: "new_secret", secretId: snap.id, creatorId }));
    await Promise.all(promises);
});
// ============================================================
// 6. EXPIRING SOON — Daily cron at 10:00 AM
//    Warns creators 3 days before their Hushhh expires (60 day mark)
// ============================================================
exports.onSecretExpiringSoon = functions.pubsub
    .schedule("0 10 * * *")
    .timeZone("Asia/Jerusalem")
    .onRun(async () => {
    const now = new Date();
    const fiftySevenDaysAgo = new Date(now.getTime() - 57 * 24 * 60 * 60 * 1000);
    const fiftyEightDaysAgo = new Date(now.getTime() - 58 * 24 * 60 * 60 * 1000);
    // Find secrets created 57-58 days ago (will expire in 2-3 days)
    const expiringQuery = await db
        .collection("secrets")
        .where("isHidden", "==", false)
        .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(fiftyEightDaysAgo))
        .where("createdAt", "<=", admin.firestore.Timestamp.fromDate(fiftySevenDaysAgo))
        .get();
    let notifiedCount = 0;
    for (const doc of expiringQuery.docs) {
        const secret = doc.data();
        // Don't warn if saved (immune)
        if ((secret.saveCount || 0) > 0)
            continue;
        if (secret.creatorId) {
            await sendPushToUser(secret.creatorId, "Your Hushhh expires soon ⏳", "Save it to keep it alive forever! It will be removed in 3 days.", { type: "expiring", secretId: doc.id });
            notifiedCount++;
        }
    }
    console.log(`Sent ${notifiedCount} expiring-soon notifications.`);
});
// ============================================================
// 7. VERIFY GROUP UNLOCK (existing)
// ============================================================
exports.verifyGroupUnlock = functions.https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
    const { secretId, userLat, userLng } = data;
    const uid = context.auth.uid;
    if (!secretId || !userLat || !userLng) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required parameters");
    }
    const secretRef = db.collection("secrets").doc(secretId);
    const secretSnap = await secretRef.get();
    if (!secretSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Secret not found.");
    }
    const secret = secretSnap.data();
    if (!(secret === null || secret === void 0 ? void 0 : secret.isGroup)) {
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
        const unlockedUids = recentAttempts.map((d) => d.id);
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
        message: `Need ${requiredUsers - recentAttempts.length} more people within ${timeWindowMinutes} minutes.`,
        currentCount: recentAttempts.length,
        requiredCount: requiredUsers,
    };
});
//# sourceMappingURL=index.js.map