
const fs = require("fs");
const path = require("path");

const secretServicePath = path.join(__dirname, "../lib/services/secret_service.dart");

let content = fs.readFileSync(secretServicePath, "utf8");

// Save backup if not exists
if (!fs.existsSync(secretServicePath + ".bak")) {
  fs.writeFileSync(secretServicePath + ".bak", content);
}

// Inject mock data function
const mockData = `
    return [
      Secret(
        id: "mock_sec_1",
        creatorId: "mock_c1",
        creatorName: "DanLevi",
        creatorTierLevel: 4,
        creatorTierColor: "#67E8F9",
        type: "voice",
        audioDuration: 34,
        likes: 42,
        commentCount: 8,
        lat: 32.0853,
        lng: 34.7818,
      ),
      Secret(
        id: "mock_sec_2",
        creatorId: "mock_c2",
        creatorName: "MayaCohen",
        creatorTierLevel: 2,
        creatorTierColor: "#A855F7",
        type: "text",
        textContent: "גיליתי היום בית קפה מדהים שמוחבא בסמטה הזאת. האקוסטיקה פה משגעת! ☕✨",
        likes: 125,
        commentCount: 14,
        lat: 32.0860,
        lng: 34.7825,
      ),
      Secret(
        id: "mock_sec_3",
        creatorId: "mock_c3",
        creatorName: "SoundSeeker",
        creatorTierLevel: 6,
        creatorTierColor: "#FF69B4",
        type: "voice",
        isGroup: true,
        requiredUsers: 3,
        audioDuration: 45,
        likes: 89,
        commentCount: 6,
        lat: 32.0870,
        lng: 34.7830,
      ),
    ];
`;

content = content.replace(/Future<List<Secret>> getNearbySecrets\([^)]*\)\s*async\s*\{[\s\S]*?return secrets;\s*\}/, "Future<List<Secret>> getNearbySecrets(double a, double b, {String? userId, List<String> savedSecretIds = const []}) async {" + mockData + "}");

content = content.replace(/Future<List<Secret>> getUserSecrets\([^)]*\)\s*async\s*\{[\s\S]*?return snapshot.docs.map[^}]*\.toList\(\);\s*\}/, "Future<List<Secret>> getUserSecrets(String userId) async {" + mockData + "}");

content = content.replace(/Future<List<Secret>> getSavedSecrets\([^)]*\)\s*async\s*\{[\s\S]*?return results;\s*\}/, "Future<List<Secret>> getSavedSecrets(List<String> secretIds) async {" + mockData + "}");

fs.writeFileSync(secretServicePath, content);
console.log("Mock data injected into SecretService");
