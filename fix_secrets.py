import re

with open('lib/services/secret_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix getNearbySecrets
nearby_mock_pattern = r'Future<List<Secret>> getNearbySecrets\(double a, double b, \{String\? userId, List<String> savedSecretIds = const \[\]\}\) async \{\s*return \[\s*Secret\(\s*id: "mock_sec_1".*?\];\s*\}'
nearby_real = '''Future<List<Secret>> getNearbySecrets(double userLat, double userLng, {String? userId, List<String> savedSecretIds = const []}) async {
    final now = DateTime.now();
    final snapshot = await _secretsRef
        .where('isHidden', isEqualTo: false)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .get();

    final secrets = snapshot.docs
        .map((doc) => Secret.fromFirestore(doc))
        .where((secret) =>
            secret.creatorId == userId || 
            savedSecretIds.contains(secret.id) ||
            GeoService.isWithinRadius(
              userLat, userLng,
              secret.lat, secret.lng,
              AppConstants.feedRadiusMeters,
            ))
        .toList();

    return secrets;
  }'''
content = re.sub(nearby_mock_pattern, nearby_real, content, flags=re.DOTALL)

# Fix getUserSecrets
user_mock_pattern = r'Future<List<Secret>> getUserSecrets\(String userId\) async \{\s*return \[\s*Secret\(\s*id: "mock_sec_1".*?\];\s*\}'
user_real = '''Future<List<Secret>> getUserSecrets(String userId) async {
    final snapshot = await _secretsRef
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Secret.fromFirestore(doc)).toList();
  }'''
content = re.sub(user_mock_pattern, user_real, content, flags=re.DOTALL)

# Fix getSavedSecrets
saved_mock_pattern = r'Future<List<Secret>> getSavedSecrets\(List<String> secretIds\) async \{\s*return \[\s*Secret\(\s*id: "mock_sec_1".*?\];\s*\}'
saved_real = '''Future<List<Secret>> getSavedSecrets(List<String> secretIds) async {
    if (secretIds.isEmpty) return [];
    List<Secret> results = [];
    for (var i = 0; i < secretIds.length; i += 10) {
      final chunk = secretIds.sublist(i, min(i + 10, secretIds.length));
      final snapshot = await _secretsRef.where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(snapshot.docs.map((doc) => Secret.fromFirestore(doc)));
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }'''
content = re.sub(saved_mock_pattern, saved_real, content, flags=re.DOTALL)

# Fix getFollowingSecrets
following_mock_pattern = r'Future<List<Secret>> getFollowingSecrets\(List<String> followingIds\) async \{\s*return \[\s*Secret\(\s*id: "mock_sec_1".*?\];\s*\}'
following_real = '''Future<List<Secret>> getFollowingSecrets(List<String> followingIds) async {
    if (followingIds.isEmpty) return [];
    final now = DateTime.now();
    List<Secret> results = [];
    for (var i = 0; i < followingIds.length; i += 10) {
      final chunk = followingIds.sublist(i, min(i + 10, followingIds.length));
      final snapshot = await _secretsRef
          .where('creatorId', whereIn: chunk)
          .where('isHidden', isEqualTo: false)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .get();
      results.addAll(snapshot.docs.map((doc) => Secret.fromFirestore(doc)));
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }'''
content = re.sub(following_mock_pattern, following_real, content, flags=re.DOTALL)

# Fix getSecretsForMap
map_mock_pattern = r'Future<List<Secret>> getSecretsForMap\(double a, double b\) async \{\s*return \[\s*Secret\(\s*id: "mock_sec_1".*?\];\s*\}'
map_real = '''Future<List<Secret>> getSecretsForMap(double userLat, double userLng) async {
    final now = DateTime.now();
    final snapshot = await _secretsRef
        .where('isHidden', isEqualTo: false)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .get();

    return snapshot.docs
        .map((doc) => Secret.fromFirestore(doc))
        .where((secret) =>
            GeoService.isWithinRadius(
              userLat, userLng,
              secret.lat, secret.lng,
              AppConstants.echoMapRadiusMeters,
            ))
        .toList();
  }'''
content = re.sub(map_mock_pattern, map_real, content, flags=re.DOTALL)

with open('lib/services/secret_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
