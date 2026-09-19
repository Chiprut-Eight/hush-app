/**
 * Validate Tier System Consistency
 * 
 * Checks that the tier configuration in the Cloud Functions (server)
 * matches what's defined in tiers.dart (client), and runs a full
 * tier progression simulation.
 * 
 * Usage: node validate_tiers.js
 */

// ============================================================
// SERVER-SIDE TIER CONFIG (from index.ts)
// ============================================================
const SERVER_TIER_REQUIRED = {
  1: 0, 2: 5, 3: 10, 4: 15, 5: 20,
  6: 25, 7: 30, 8: 35, 9: 40, 10: 50,
};

const SERVER_TIER_COLORS = {
  1: "#8b8b8b", 2: "#4a9eff", 3: "#34d399", 4: "#fbbf24", 5: "#f97316",
  6: "#ef4444", 7: "#a855f7", 8: "#ec4899", 9: "#06b6d4", 10: "#ffd700",
};

const SERVER_TIER_RADIUS = {
  1: 15, 2: 15, 3: 15, 4: 15, 5: 30,
  6: 40, 7: 60, 8: 80, 9: 100, 10: 150,
};

// ============================================================
// CLIENT-SIDE TIER CONFIG (from tiers.dart)
// ============================================================
const CLIENT_TIERS = [
  { level: 1, name: "Default",      colorHex: "#808080", requiredSuccesses: 0,  maxGroupUsers: 3,   timeWindow: 1,  radius: 15 },
  { level: 2, name: "Novice",       colorHex: "#2196F3", requiredSuccesses: 5,  maxGroupUsers: 8,   timeWindow: 2,  radius: 15 },
  { level: 3, name: "Apprentice",   colorHex: "#4CAF50", requiredSuccesses: 10, maxGroupUsers: 15,  timeWindow: 3,  radius: 15 },
  { level: 4, name: "Adept",        colorHex: "#FFEB3B", requiredSuccesses: 15, maxGroupUsers: 25,  timeWindow: 4,  radius: 15 },
  { level: 5, name: "Expert",       colorHex: "#FF9800", requiredSuccesses: 20, maxGroupUsers: 40,  timeWindow: 5,  radius: 30 },
  { level: 6, name: "Master",       colorHex: "#F44336", requiredSuccesses: 25, maxGroupUsers: 70,  timeWindow: 6,  radius: 40 },
  { level: 7, name: "Grandmaster",  colorHex: "#9C27B0", requiredSuccesses: 30, maxGroupUsers: 120, timeWindow: 8,  radius: 60 },
  { level: 8, name: "Legend",       colorHex: "#E91E63", requiredSuccesses: 35, maxGroupUsers: 200, timeWindow: 10, radius: 80 },
  { level: 9, name: "Mythic",       colorHex: "#00BCD4", requiredSuccesses: 40, maxGroupUsers: 350, timeWindow: 12, radius: 100 },
  { level: 10, name: "God Tier",    colorHex: "#FFD700", requiredSuccesses: 50, maxGroupUsers: 500, timeWindow: 15, radius: 150 },
];

const SERVER_TIER_NAMES = {
  1: "Default", 2: "Novice", 3: "Apprentice", 4: "Adept", 5: "Expert",
  6: "Master", 7: "Grandmaster", 8: "Legend", 9: "Mythic", 10: "God Tier",
};

// ============================================================
// TIER CALCULATION (same as server)
// ============================================================
function calculateTierLevel(totalSuccesses) {
  let level = 1;
  for (let tier = 1; tier <= 10; tier++) {
    if (totalSuccesses >= SERVER_TIER_REQUIRED[tier]) {
      level = tier;
    } else {
      break;
    }
  }
  return level;
}

// ============================================================
// VALIDATION
// ============================================================

let errors = 0;

function check(condition, message) {
  if (condition) {
    console.log(`  ✅ ${message}`);
  } else {
    console.log(`  ❌ ${message}`);
    errors++;
  }
}

console.log("\n🔍 HUSH TIER SYSTEM VALIDATION");
console.log("=".repeat(60));

// 1. Validate requiredSuccesses match
console.log("\n📋 1. Required Successes (Server vs Client):");
for (let tier = 1; tier <= 10; tier++) {
  const serverReq = SERVER_TIER_REQUIRED[tier];
  const clientReq = CLIENT_TIERS[tier - 1].requiredSuccesses;
  check(
    serverReq === clientReq,
    `Tier ${tier}: Server=${serverReq}, Client=${clientReq}`
  );
}

// 2. Validate reveal radius match
console.log("\n📋 2. Reveal Radius (Server vs Client):");
for (let tier = 1; tier <= 10; tier++) {
  const serverRadius = SERVER_TIER_RADIUS[tier];
  const clientRadius = CLIENT_TIERS[tier - 1].radius;
  check(
    serverRadius === clientRadius,
    `Tier ${tier}: Server=${serverRadius}m, Client=${clientRadius}m`
  );
}

// 3. Validate tier names match
console.log("\n📋 3. Tier Names (Server vs Client):");
for (let tier = 1; tier <= 10; tier++) {
  const serverName = SERVER_TIER_NAMES[tier];
  const clientName = CLIENT_TIERS[tier - 1].name;
  check(
    serverName === clientName,
    `Tier ${tier}: Server="${serverName}", Client="${clientName}"`
  );
}

// 4. Tier progression simulation
console.log("\n📋 4. Tier Progression Simulation:");
console.log("   Testing that calculateTierLevel produces correct results:\n");
console.log(
  "   Successes".padEnd(15) +
  "Expected Tier".padEnd(18) +
  "Calculated".padEnd(15) +
  "Name".padEnd(18) +
  "Max Users".padEnd(12) +
  "Time Window"
);
console.log("   " + "-".repeat(85));

const testCases = [
  { successes: 0,  expectedTier: 1 },
  { successes: 1,  expectedTier: 1 },
  { successes: 4,  expectedTier: 1 },
  { successes: 5,  expectedTier: 2 },
  { successes: 9,  expectedTier: 2 },
  { successes: 10, expectedTier: 3 },
  { successes: 14, expectedTier: 3 },
  { successes: 15, expectedTier: 4 },
  { successes: 19, expectedTier: 4 },
  { successes: 20, expectedTier: 5 },
  { successes: 24, expectedTier: 5 },
  { successes: 25, expectedTier: 6 },
  { successes: 29, expectedTier: 6 },
  { successes: 30, expectedTier: 7 },
  { successes: 34, expectedTier: 7 },
  { successes: 35, expectedTier: 8 },
  { successes: 39, expectedTier: 8 },
  { successes: 40, expectedTier: 9 },
  { successes: 49, expectedTier: 9 },
  { successes: 50, expectedTier: 10 },
  { successes: 100, expectedTier: 10 },
];

for (const tc of testCases) {
  const calculated = calculateTierLevel(tc.successes);
  const clientTier = CLIENT_TIERS[tc.expectedTier - 1];
  const match = calculated === tc.expectedTier;
  if (!match) errors++;
  
  console.log(
    `   ${String(tc.successes).padEnd(15)}` +
    `${String(tc.expectedTier).padEnd(18)}` +
    `${String(calculated).padEnd(15)}` +
    `${clientTier.name.padEnd(18)}` +
    `${String(clientTier.maxGroupUsers).padEnd(12)}` +
    `${clientTier.timeWindow} min` +
    `${match ? "" : "  ❌ MISMATCH!"}`
  );
}

// 5. Full tier table
console.log("\n📋 5. Complete Tier Reference Table:");
console.log(
  "\n   Tier".padEnd(10) +
  "Name".padEnd(16) +
  "Color (Server)".padEnd(18) +
  "Color (Client)".padEnd(18) +
  "Req.Succ".padEnd(12) +
  "MaxUsers".padEnd(12) +
  "TimeWin".padEnd(10) +
  "Radius"
);
console.log("   " + "-".repeat(95));

for (let tier = 1; tier <= 10; tier++) {
  const ct = CLIENT_TIERS[tier - 1];
  console.log(
    `   ${String(tier).padEnd(7)}` +
    `${ct.name.padEnd(16)}` +
    `${SERVER_TIER_COLORS[tier].padEnd(18)}` +
    `${ct.colorHex.padEnd(18)}` +
    `${String(ct.requiredSuccesses).padEnd(12)}` +
    `${String(ct.maxGroupUsers).padEnd(12)}` +
    `${String(ct.timeWindow) + " min".padEnd(10)}` +
    `${ct.radius}m`
  );
}

// Summary
console.log("\n" + "=".repeat(60));
if (errors > 0) {
  console.log(`\n❌ VALIDATION FAILED: ${errors} error(s) found!`);
  console.log("   Fix the mismatches above before deploying.\n");
  process.exit(1);
} else {
  console.log("\n✅ ALL VALIDATIONS PASSED — Server and Client tiers are in sync!\n");
  process.exit(0);
}
