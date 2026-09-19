/**
 * Diagnose & Reset Tier Data for Hush App
 * 
 * Usage:
 *   node diagnose_tiers.js                  — Show all users' tier data
 *   node diagnose_tiers.js --reset ADMIN_UID — Reset a specific user's tier data
 * 
 * Requires: Firebase Admin SDK (uses service account from GOOGLE_APPLICATION_CREDENTIALS
 *           or falls back to default app credentials)
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin with project ID
// Uses Application Default Credentials (gcloud auth or GOOGLE_APPLICATION_CREDENTIALS)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "hush-7bab0",
  });
}
const db = admin.firestore();

const TIER_REQUIRED_SUCCESSES = {
  1: 0, 2: 5, 3: 10, 4: 15, 5: 20,
  6: 25, 7: 30, 8: 35, 9: 40, 10: 50,
};

const TIER_NAMES = {
  1: "Default (Gray)",
  2: "Novice (Blue)",
  3: "Apprentice (Green)",
  4: "Adept (Yellow)",
  5: "Expert (Orange)",
  6: "Master (Red)",
  7: "Grandmaster (Purple)",
  8: "Legend (Pink)",
  9: "Mythic (Cyan)",
  10: "God Tier (Gold)",
};

function calculateTierLevel(totalSuccesses) {
  let level = 1;
  for (let tier = 1; tier <= 10; tier++) {
    if (totalSuccesses >= TIER_REQUIRED_SUCCESSES[tier]) {
      level = tier;
    } else {
      break;
    }
  }
  return level;
}

async function diagnoseAllUsers() {
  console.log("\n📊 HUSH TIER DIAGNOSTIC REPORT");
  console.log("=".repeat(80));
  
  const usersSnapshot = await db.collection("users").get();
  
  if (usersSnapshot.empty) {
    console.log("No users found.");
    return;
  }

  console.log(`\nFound ${usersSnapshot.size} users:\n`);
  console.log(
    "UID".padEnd(30) +
    "Email".padEnd(35) +
    "groupSucc".padEnd(12) +
    "tierLevel".padEnd(12) +
    "Expected".padEnd(12) +
    "Match?"
  );
  console.log("-".repeat(110));

  let mismatchCount = 0;

  for (const doc of usersSnapshot.docs) {
    const data = doc.data();
    const uid = doc.id;
    const email = data.email || "(no email)";
    const groupSuccesses = data.groupSuccesses || 0;
    const tierLevel = data.tierLevel || 1;
    const expectedTier = calculateTierLevel(groupSuccesses);
    const match = tierLevel === expectedTier;

    if (!match) mismatchCount++;

    console.log(
      uid.substring(0, 28).padEnd(30) +
      email.substring(0, 33).padEnd(35) +
      String(groupSuccesses).padEnd(12) +
      String(tierLevel).padEnd(12) +
      String(expectedTier).padEnd(12) +
      (match ? "✅" : "❌ MISMATCH!")
    );
  }

  console.log("-".repeat(110));
  console.log(`\n${mismatchCount > 0 ? `⚠️  ${mismatchCount} mismatches found!` : "✅ All tiers are consistent."}\n`);
}

async function resetUser(uid) {
  console.log(`\n🔄 RESETTING TIER DATA FOR USER: ${uid}`);
  console.log("=".repeat(60));

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    console.log(`❌ User ${uid} not found!`);
    return;
  }

  const data = userSnap.data();
  console.log(`\n📋 BEFORE RESET:`);
  console.log(`   Email:           ${data.email || "(none)"}`);
  console.log(`   groupSuccesses:  ${data.groupSuccesses || 0}`);
  console.log(`   tierLevel:       ${data.tierLevel || 1} (${TIER_NAMES[data.tierLevel || 1]})`);
  console.log(`   tierSuccesses:   ${JSON.stringify(data.tierSuccesses || [])}`);

  await userRef.update({
    groupSuccesses: 0,
    tierLevel: 1,
    tierSuccesses: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  });

  console.log(`\n✅ AFTER RESET:`);
  console.log(`   groupSuccesses:  0`);
  console.log(`   tierLevel:       1 (Default - Gray)`);
  console.log(`   tierSuccesses:   [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]`);
  console.log(`\n🎉 User ${uid} has been reset to Tier 1 (Default).\n`);
}

// Also reset successCounted on all secrets owned by this user
async function resetSecretFlags(uid) {
  console.log(`\n🔄 RESETTING successCounted flags for secrets by user: ${uid}`);
  
  const secretsSnapshot = await db.collection("secrets")
    .where("creatorId", "==", uid)
    .where("isGroup", "==", true)
    .get();

  let resetCount = 0;
  for (const doc of secretsSnapshot.docs) {
    const data = doc.data();
    if (data.successCounted) {
      await doc.ref.update({ successCounted: false });
      resetCount++;
    }
  }

  console.log(`   Reset ${resetCount} secret(s) successCounted flag.\n`);
}

async function main() {
  const args = process.argv.slice(2);
  
  if (args.includes("--reset")) {
    const uidIndex = args.indexOf("--reset") + 1;
    const uid = args[uidIndex];
    if (!uid) {
      console.log("Usage: node diagnose_tiers.js --reset <USER_UID>");
      process.exit(1);
    }
    await resetUser(uid);
    await resetSecretFlags(uid);
  } else {
    await diagnoseAllUsers();
  }

  process.exit(0);
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
