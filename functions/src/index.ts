import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// 1. Decay Cron Job: Runs every night at 2:00 AM
export const decaySecretsJob = functions.pubsub.schedule("0 2 * * *").onRun(async () => {
  const now = new Date();
  
  const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const threeWeeksAgo = new Date(now.getTime() - 21 * 24 * 60 * 60 * 1000);
  const sixtyDaysAgo = new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000);

  const secretsRef = db.collection("secrets");
  
  // Rule A: Absolute delete after 60 days
  const expiredQuery = await secretsRef.where("createdAt", "<=", sixtyDaysAgo).get();
  
  // Rule B: 0 listens in 1 week
  const noListenersQuery = await secretsRef
      .where("createdAt", "<=", oneWeekAgo)
      .where("listens", "==", 0)
      .get();
      
  // Rule C: < 5 listens in 3 weeks
  const lowListenersQuery = await secretsRef
      .where("createdAt", "<=", threeWeeksAgo)
      .where("listens", "<", 5)
      .get();

  const batch = db.batch();
  let deleteCount = 0;

  const processDeletion = (doc: admin.firestore.QueryDocumentSnapshot) => {
    batch.delete(doc.ref);
    deleteCount++;
  };

  expiredQuery.docs.forEach(processDeletion);
  noListenersQuery.docs.forEach(processDeletion);
  lowListenersQuery.docs.forEach(processDeletion);

  if (deleteCount > 0) {
    await batch.commit();
    console.log(`Decayed ${deleteCount} secrets.`);
  } else {
    console.log("No secrets to decay today.");
  }
});

// 2. Verify Group Unlock
export const verifyGroupUnlock = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "User must be logged in");

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
    timestamp: admin.firestore.FieldValue.serverTimestamp() // Works across servers
  });

  // Since FieldValue.serverTimestamp() is calculated on write, querying immediately might be tricky
  // with `>= cutoff` if it relies on client time vs server time. For this proof-of-concept
  // we use a snapshot fetch.
  const recentAttemptsSnap = await attemptsRef.orderBy("timestamp").startAt(admin.firestore.Timestamp.fromDate(cutoff)).get();
  const recentAttempts = recentAttemptsSnap.docs;
  
  if (recentAttempts.length >= requiredUsers) {
    const unlockedUids = recentAttempts.map((d: any) => d.id);
    
    await secretRef.update({
      unlockedBy: admin.firestore.FieldValue.arrayUnion(...unlockedUids)
    });

    if (secret.creatorId) {
      // Award Clout to creator
      await db.collection("users").doc(secret.creatorId).update({
        groupSuccesses: admin.firestore.FieldValue.increment(1)
      });
    }
    
    return { success: true, message: "Group secret unlocked!" };
  }

  return { 
    success: false, 
    message: `Need ${requiredUsers - recentAttempts.length} more people within ${timeWindowMinutes} minutes.`,
    currentCount: recentAttempts.length,
    requiredCount: requiredUsers
  };
});
