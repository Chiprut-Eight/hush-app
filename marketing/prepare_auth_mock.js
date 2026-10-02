
const fs = require("fs");
const path = require("path");

const authProviderPath = path.join(__dirname, "../lib/providers/auth_provider.dart");

let content = "";
if (fs.existsSync(authProviderPath + ".bak")) {
  content = fs.readFileSync(authProviderPath + ".bak", "utf8");
} else {
  content = fs.readFileSync(authProviderPath, "utf8");
  fs.writeFileSync(authProviderPath + ".bak", content);
}

// Override get hushUser
content = content.replace(/HushUser\?\s+get\s+hushUser\s*=>\s*_hushUser;/, "HushUser? get hushUser => HushUser(uid: \"mock_uid\", email: \"test@test.com\", displayName: \"Hushhh_Fan\", tierLevel: 5, totalPublished: 12, followingIds: [\"1\", \"2\", \"3\"], followerIds: [\"1\", \"2\", \"3\", \"4\"]);");

// Override get isAuthenticated
content = content.replace(/bool\s+get\s+isAuthenticated\s*=>\s*.*?;/, "bool get isAuthenticated => true;");

// Override get firebaseUser
content = content.replace(/User\?\s+get\s+firebaseUser\s*=>\s*_firebaseUser;/, "User? get firebaseUser => null;"); // keep null to avoid real FCM initialization

fs.writeFileSync(authProviderPath, content);
console.log("Mock data injected into AuthProvider");
