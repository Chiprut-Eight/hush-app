import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  Stream<Secret> getSecretStream(String secretId) {
    return _firestore.collection('secrets').doc(secretId).snapshots().map((snapshot) {
      if (!snapshot.exists) throw Exception('Secret not found');
      return Secret.fromFirestore(snapshot);
    });
  }

  Stream<int> getUnlockAttemptsStream(String secretId, int windowMinutes) {
    final cutoff = DateTime.now().subtract(Duration(minutes: windowMinutes));
    
    return _firestore
        .collection('secrets')
        .doc(secretId)
        .collection('unlockAttempts')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Fetch all non-hidden, non-expired secrets and filter by proximity
  Future<List<Secret>> getNearbySecrets(double userLat, double userLng) async {
    final now = DateTime.now();
    final snapshot = await _secretsRef
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    final secrets = snapshot.docs
        .map((doc) => Secret.fromFirestore(doc))
        .where((secret) => Secret.isSurvivor(secret, now))
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

  /// Increment view count
  Future<void> viewSecret(String secretId) async {
    await _secretsRef.doc(secretId).update({
      'views': FieldValue.increment(1),
    });
  }

  /// Verify and attempt to unlock a group secret via Cloud Function
  Future<Map<String, dynamic>> verifyGroupUnlock({
    required String secretId,
    required double lat,
    required double lng,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyGroupUnlock');
      final result = await callable.call({
        'secretId': secretId,
        'userLat': lat,
        'userLng': lng,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Report a secret
  Future<void> reportSecret(String secretId) async {
    await _secretsRef.doc(secretId).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  /// Report a secret with details — creates a report document
  Future<void> reportSecretWithDetails(String secretId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Increment report count on the secret
    await _secretsRef.doc(secretId).update({
      'reportCount': FieldValue.increment(1),
    });

    // Create a report document
    await _firestore.collection('reports').add({
      'secretId': secretId,
      'reporterId': user.uid,
      'reporterName': user.displayName,
      'reporterEmail': user.email,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Submit an appeal for ghost mode
  Future<void> submitAppeal(String reason) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('appeals').add({
      'userId': user.uid,
      'userName': user.displayName,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Save a secret to user's saved list
  /// Toggle save status of a secret (Save/Unsave)
  Future<void> toggleSaveSecret(String secretId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    final List<dynamic> savedIds = userDoc.data()?['savedSecretIds'] ?? [];
    if (savedIds.contains(secretId)) {
      // Unsave
      await _firestore.collection('users').doc(uid).update({
        'savedSecretIds': FieldValue.arrayRemove([secretId]),
      });
      // Decrement counter on the secret itself
      await _secretsRef.doc(secretId).update({
        'saveCount': FieldValue.increment(-1),
      });
    } else {
      // Save
      await _firestore.collection('users').doc(uid).update({
        'savedSecretIds': FieldValue.arrayUnion([secretId]),
      });
      // Increment counter on the secret itself
      await _secretsRef.doc(secretId).update({
        'saveCount': FieldValue.increment(1),
      });
    }
  }

  /// Check if the current user has a valid active participation in a group secret
  Future<bool> isUserParticipating(String secretId, String userId, int windowMinutes) async {
    final cutoff = DateTime.now().subtract(Duration(minutes: windowMinutes));
    
    final snapshot = await _firestore
        .collection('secrets')
        .doc(secretId)
        .collection('unlockAttempts')
        .doc(userId)
        .get();
        
    if (!snapshot.exists) return false;
    
    final timestamp = (snapshot.data()?['timestamp'] as Timestamp?)?.toDate();
    return timestamp != null && timestamp.isAfter(cutoff);
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
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _secretsRef.doc(secretId).delete();
    
    // Decrement published count
    await _firestore.collection('users').doc(user.uid).update({
      'totalPublished': FieldValue.increment(-1),
    });
  }

  /// Add a comment to a secret
  Future<void> addComment(String secretId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    await _secretsRef.doc(secretId).collection('comments').add({
      'userId': user.uid,
      'userName': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim().isNotEmpty
          ? '${userData['firstName']} ${userData['lastName']}'.trim()
          : user.displayName,
      'userPhotoURL': userData['useGenericPhoto'] == true ? 'generic' : user.photoURL,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get comments stream for a secret
  Stream<List<Map<String, dynamic>>> getCommentsStream(String secretId) {
    return _secretsRef
        .doc(secretId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'userId': data['userId'],
                'userName': data['userName'],
                'userPhotoURL': data['userPhotoURL'],
                'text': data['text'],
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
              };
            }).toList());
  }

  /// Delete a comment
  Future<void> deleteComment(String secretId, String commentId) async {
    await _secretsRef.doc(secretId).collection('comments').doc(commentId).delete();
  }

  /// Get all secrets for map display
  Future<List<Secret>> getSecretsForMap(double userLat, double userLng) async {
    final now = DateTime.now();
    final snapshot = await _secretsRef
        .where('isHidden', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => Secret.fromFirestore(doc))
        .where((secret) => Secret.isSurvivor(secret, now))
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

