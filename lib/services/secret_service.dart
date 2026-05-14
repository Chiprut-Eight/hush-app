import 'package:flutter/foundation.dart';
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

  /// Fetch all non-hidden, non-expired secrets and filter by proximity.
  /// User's own secrets and saved secrets always appear regardless of distance.
  /// NOTE: Content (textContent/audioURL) is NOT included — use revealSecret() to get it.
  Future<List<Secret>> getNearbySecrets(
    double userLat,
    double userLng, {
    String? userId,
    List<String> savedSecretIds = const [],
  }) async {
    final now = DateTime.now();
    final snapshot = await _secretsRef
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    final savedSet = savedSecretIds.toSet();

    final secrets = snapshot.docs
        .map((doc) => Secret.fromFirestore(doc))
        .where((secret) => Secret.isSurvivor(secret, now))
        .where((secret) {
          // Always show user's own secrets and saved secrets
          if (userId != null && secret.creatorId == userId) return true;
          if (savedSet.contains(secret.id)) return true;
          // Otherwise filter by proximity
          return GeoService.isWithinRadius(
            userLat, userLng,
            secret.lat, secret.lng,
            AppConstants.feedRadiusMeters,
          );
        })
        .toList();

    return secrets;
  }

  /// Fetch a single secret by ID
  Future<Secret?> getSecret(String secretId) async {
    final doc = await _secretsRef.doc(secretId).get();
    if (!doc.exists) return null;
    return Secret.fromFirestore(doc);
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

  // ============================================================
  // SECURE: Reveal secret content via Cloud Function
  // ============================================================

  /// Request secret content from server (with proximity verification)
  Future<Map<String, dynamic>> revealSecret({
    required String secretId,
    double? lat,
    double? lng,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('revealSecret');
      final result = await callable.call({
        'secretId': secretId,
        'userLat': ?lat,
        'userLng': ?lng,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('revealSecret error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================================
  // SECURE: Create secret via Cloud Function (V2)
  // ============================================================

  /// Create a new text secret via Cloud Function
  Future<String> createTextSecret({
    required String content,
    required double lat,
    required double lng,
    bool isGroup = false,
    int? minTierLevel,
    int? requiredUsers,
    int? timeWindowMinutes,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('createSecretV2');
    final result = await callable.call({
      'type': 'text',
      'textContent': content,
      'lat': lat,
      'lng': lng,
      'isGroup': isGroup,
      'requiredUsers': ?requiredUsers,
      'timeWindowMinutes': ?timeWindowMinutes,
    });
    final data = Map<String, dynamic>.from(result.data);
    if (data['success'] != true) throw Exception(data['message'] ?? 'Create failed');
    return data['secretId'] as String;
  }

  /// Create a voice secret via Cloud Function
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
    final callable = FirebaseFunctions.instance.httpsCallable('createSecretV2');
    final result = await callable.call({
      'type': 'voice',
      'audioURL': audioURL,
      'audioDuration': audioDuration,
      'lat': lat,
      'lng': lng,
      'isGroup': isGroup,
      'requiredUsers': ?requiredUsers,
      'timeWindowMinutes': ?timeWindowMinutes,
    });
    final data = Map<String, dynamic>.from(result.data);
    if (data['success'] != true) throw Exception(data['message'] ?? 'Create failed');
    return data['secretId'] as String;
  }

  // ============================================================
  // SECURE: Interactions via Cloud Function
  // ============================================================

  /// Like a secret
  Future<void> likeSecret(String secretId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('interactWithSecret');
      await callable.call({'secretId': secretId, 'action': 'like'});
    } catch (e) {
      debugPrint('likeSecret error: $e');
    }
  }

  /// Remove a like from a secret
  Future<void> unlikeSecret(String secretId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('interactWithSecret');
      await callable.call({'secretId': secretId, 'action': 'unlike'});
    } catch (e) {
      debugPrint('unlikeSecret error: $e');
    }
  }

  /// Dislike a secret
  Future<void> dislikeSecret(String secretId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('interactWithSecret');
      await callable.call({'secretId': secretId, 'action': 'dislike'});
    } catch (e) {
      debugPrint('dislikeSecret error: $e');
    }
  }

  /// Remove a dislike from a secret
  Future<void> undislikeSecret(String secretId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('interactWithSecret');
      await callable.call({'secretId': secretId, 'action': 'undislike'});
    } catch (e) {
      debugPrint('undislikeSecret error: $e');
    }
  }

  /// Increment view count uniquely per user
  Future<void> viewSecret(String secretId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('interactWithSecret');
      await callable.call({'secretId': secretId, 'action': 'view'});
    } catch (e) {
      debugPrint('viewSecret error: $e');
    }
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

  /// Delete a secret (via Cloud Function — deletes doc + storage)
  Future<void> deleteSecret(String secretId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('deleteSecretV2');
    await callable.call({'secretId': secretId});
  }

  /// Add a comment to a secret
  Future<void> addComment(String secretId, String text, {String? replyToUserId, String? replyToUserName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final commentData = {
      'userId': user.uid,
      'userName': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim().isNotEmpty
          ? '${userData['firstName']} ${userData['lastName']}'.trim()
          : user.displayName,
      'userPhotoURL': userData['useGenericPhoto'] == true ? 'generic' : user.photoURL,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    if (replyToUserId != null) {
      commentData['replyToUserId'] = replyToUserId;
      commentData['replyToUserName'] = replyToUserName ?? 'Someone';
    }

    await _secretsRef.doc(secretId).collection('comments').add(commentData);

    // Update comment count on secret
    await _secretsRef.doc(secretId).update({
      'commentCount': FieldValue.increment(1),
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
                'isEdited': data['isEdited'] ?? false,
                'replyToUserId': data['replyToUserId'],
                'replyToUserName': data['replyToUserName'],
              };
            }).toList());
  }

  /// Edit a comment
  Future<void> editComment(String secretId, String commentId, String newText) async {
    await _secretsRef.doc(secretId).collection('comments').doc(commentId).update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a comment
  Future<void> deleteComment(String secretId, String commentId) async {
    await _secretsRef.doc(secretId).collection('comments').doc(commentId).delete();
    
    // Decrement comment count
    await _secretsRef.doc(secretId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  /// Get all secrets for map display.
  /// User's own secrets and saved secrets always appear regardless of distance.
  Future<List<Secret>> getSecretsForMap(
    double userLat,
    double userLng, {
    String? userId,
    List<String> savedSecretIds = const [],
  }) async {
    final now = DateTime.now();
    final snapshot = await _secretsRef
        .where('isHidden', isEqualTo: false)
        .get();

    final savedSet = savedSecretIds.toSet();

    return snapshot.docs
        .map((doc) => Secret.fromFirestore(doc))
        .where((secret) => Secret.isSurvivor(secret, now))
        .where((secret) {
          // Always show user's own secrets and saved secrets
          if (userId != null && secret.creatorId == userId) return true;
          if (savedSet.contains(secret.id)) return true;
          // Otherwise filter by proximity
          return GeoService.isWithinRadius(
            userLat, userLng,
            secret.lat, secret.lng,
            AppConstants.echoMapRadiusMeters,
          );
        })
        .toList();
  }

}
