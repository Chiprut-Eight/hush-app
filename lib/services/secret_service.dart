import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/secret.dart';
import '../config/constants.dart';
import 'geo_service.dart';

/// Service for Firestore secret CRUD operations — matches web secretService.ts
class SecretService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _secretsRef =>
      _firestore.collection('secrets');

  /// Fetch all non-hidden, non-expired secrets and filter by proximity
  Future<List<Secret>> getNearbySecrets(double userLat, double userLng) async {
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
            GeoService.isWithinRadius(
              userLat, userLng,
              secret.lat, secret.lng,
              AppConstants.feedRadiusMeters,
            ))
        .toList();

    return secrets;
  }

  /// Fetch all secrets created by a specific user
  Future<List<Secret>> getUserSecrets(String userId) async {
    final snapshot = await _secretsRef
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Secret.fromFirestore(doc)).toList();
  }

  /// Fetch saved secrets by ID list
  Future<List<Secret>> getSavedSecrets(List<String> secretIds) async {
    if (secretIds.isEmpty) return [];
    
    // Fetch in chunks of 10 for Firestore 'in' query limitation
    List<Secret> results = [];
    for (var i = 0; i < secretIds.length; i += 10) {
      final chunk = secretIds.sublist(i, i + 10 > secretIds.length ? secretIds.length : i + 10);
      final snapshot = await _secretsRef.where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(snapshot.docs.map((doc) => Secret.fromFirestore(doc)));
    }
    
    // Sort by most recently created
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Create a new text secret
  Future<String> createTextSecret({
    required String content,
    required double lat,
    required double lng,
    bool isGroup = false,
    int? minTierLevel,
    int? requiredUsers,
    int? timeWindowMinutes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Get creator profile for denormalized data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final docRef = _secretsRef.doc();
    final secret = Secret(
      id: docRef.id,
      creatorId: user.uid,
      creatorName: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim().isNotEmpty 
          ? '${userData['firstName']} ${userData['lastName']}'.trim() 
          : user.displayName,
      creatorPhotoURL: userData['useGenericPhoto'] == true ? 'generic' : user.photoURL,
      creatorTierLevel: userData['tierLevel'] ?? 1,
      creatorTierColor: _tierLevelToColor(userData['tierLevel'] ?? 1),
      type: 'text',
      textContent: content,
      lat: lat,
      lng: lng,
      isGroup: isGroup,
      minTierLevel: minTierLevel,
      requiredUsers: requiredUsers,
      timeWindowMinutes: timeWindowMinutes,
    );

    await docRef.set(secret.toFirestore());

    // Increment the user's published count
    await _firestore.collection('users').doc(user.uid).update({
      'totalPublished': FieldValue.increment(1),
    });

    return docRef.id;
  }

  /// Create a voice secret with audio URL
  Future<String> createVoiceSecret({
    required String audioURL,
    required int audioDuration,
    required double lat,
    required double lng,
    bool isGroup = false,
    int? minTierLevel,
    int? requiredUsers,
    int? timeWindowMinutes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final docRef = _secretsRef.doc();
    final secret = Secret(
      id: docRef.id,
      creatorId: user.uid,
      creatorName: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim().isNotEmpty 
          ? '${userData['firstName']} ${userData['lastName']}'.trim() 
          : user.displayName,
      creatorPhotoURL: userData['useGenericPhoto'] == true ? 'generic' : user.photoURL,
      creatorTierLevel: userData['tierLevel'] ?? 1,
      creatorTierColor: _tierLevelToColor(userData['tierLevel'] ?? 1),
      type: 'voice',
      audioURL: audioURL,
      audioDuration: audioDuration,
      lat: lat,
      lng: lng,
      isGroup: isGroup,
      minTierLevel: minTierLevel,
      requiredUsers: requiredUsers,
      timeWindowMinutes: timeWindowMinutes,
    );

    await docRef.set(secret.toFirestore());
    await _firestore.collection('users').doc(user.uid).update({
      'totalPublished': FieldValue.increment(1),
    });

    return docRef.id;
  }

  /// Like a secret
  Future<void> likeSecret(String secretId) async {
    await _secretsRef.doc(secretId).update({
      'likes': FieldValue.increment(1),
    });
  }

  /// Dislike a secret
  Future<void> dislikeSecret(String secretId) async {
    await _secretsRef.doc(secretId).update({
      'dislikes': FieldValue.increment(1),
    });
  }

  /// Increment listen count
  Future<void> listenSecret(String secretId) async {
    await _secretsRef.doc(secretId).update({
      'listens': FieldValue.increment(1),
    });
  }

  /// Report a secret
  Future<void> reportSecret(String secretId) async {
    await _secretsRef.doc(secretId).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  /// Save a secret to user's saved list
  Future<void> saveSecret(String secretId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'savedSecretIds': FieldValue.arrayUnion([secretId]),
    });
  }

  /// Unsave a secret
  Future<void> unsaveSecret(String secretId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'savedSecretIds': FieldValue.arrayRemove([secretId]),
    });
  }

  /// Delete a secret (creator only)
  Future<void> deleteSecret(String secretId) async {
    await _secretsRef.doc(secretId).delete();
  }

  /// Get all secrets for map display
  Future<List<Secret>> getSecretsForMap(double userLat, double userLng) async {
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
  }

  String _tierLevelToColor(int level) {
    const colors = [
      '#8b8b8b', '#4a9eff', '#34d399', '#fbbf24', '#f97316',
      '#ef4444', '#a855f7', '#ec4899', '#06b6d4', '#ffd700',
    ];
    return colors[(level - 1).clamp(0, 9)];
  }
}
