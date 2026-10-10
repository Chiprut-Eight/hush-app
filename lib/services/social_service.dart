import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hush_user.dart';
import '../models/secret.dart';

class FollowedUserFeedItem {
  final HushUser user;
  final Secret? latestSecret;

  FollowedUserFeedItem({required this.user, this.latestSecret});
}

class SocialService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  /// Get user data by ID
  Future<HushUser?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return HushUser.fromFirestore(doc);
  }

  /// Get multiple users by IDs
  Future<List<HushUser>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    List<HushUser> users = [];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final usersSnap = await _firestore.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
      users.addAll(usersSnap.docs.map((doc) => HushUser.fromFirestore(doc)));
    }
    return users;
  }

  /// Search users by name prefix (case insensitive indexed search)
  Future<List<HushUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    
    final searchLower = query.toLowerCase().trim();
    
    // Firestore prefix search using range query
    // This scales to millions of users efficiently
    final snapshot = await _firestore.collection('users')
        .where('searchName', isGreaterThanOrEqualTo: searchLower)
        .where('searchName', isLessThan: '$searchLower\uf8ff')
        .limit(20)
        .get();
    
    return snapshot.docs.map((doc) => HushUser.fromFirestore(doc)).toList();
  }

  /// Follow a specific user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'followingIds': FieldValue.arrayUnion([targetUserId])
    });
    batch.update(_firestore.collection('users').doc(targetUserId), {
      'followerIds': FieldValue.arrayUnion([currentUserId])
    });
    await batch.commit();
  }

  /// Unfollow a specific user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'followingIds': FieldValue.arrayRemove([targetUserId])
    });
    batch.update(_firestore.collection('users').doc(targetUserId), {
      'followerIds': FieldValue.arrayRemove([currentUserId])
    });
    await batch.commit();
  }

  /// Get formatted list of followed users merged with their latest secret
  Future<List<FollowedUserFeedItem>> getFollowedUsersFeed(List<String> followingIds) async {
    if (followingIds.isEmpty) return [];

    List<FollowedUserFeedItem> feedItems = [];

    // Chunk because 'in' query supports max 10
    for (var i = 0; i < followingIds.length; i += 10) {
      final chunk = followingIds.sublist(i, i + 10 > followingIds.length ? followingIds.length : i + 10);
      
      final usersSnap = await _firestore.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
      
      final futures = usersSnap.docs.map((userDoc) async {
        final user = HushUser.fromFirestore(userDoc);
        
        // Fetch latest secret for this specific user
        final secretSnap = await _firestore.collection('secrets')
            .where('creatorId', isEqualTo: user.uid)
            .where('isHidden', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
            
        Secret? latest;
        if (secretSnap.docs.isNotEmpty) {
          latest = Secret.fromFirestore(secretSnap.docs.first);
        }
        
        return FollowedUserFeedItem(user: user, latestSecret: latest);
      });
      
      feedItems.addAll(await Future.wait(futures));
    }

    // Sort by whoever mapped latest secret (if they have none, push to bottom)
    feedItems.sort((a, b) {
      final ta = a.latestSecret?.createdAt.millisecondsSinceEpoch ?? 0;
      final tb = b.latestSecret?.createdAt.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta); // Descending
    });

    return feedItems;
  }

  /// Report a user's profile photo
  Future<void> reportProfilePhoto(String targetUserId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get reporter details
    String? reporterEmail = user.email;
    String? reporterName = user.displayName;
    try {
      final reporterDoc = await _firestore.collection('users').doc(user.uid).get();
      if (reporterDoc.exists) {
        final rData = reporterDoc.data();
        if (reporterEmail == null || reporterEmail.isEmpty) {
          reporterEmail = rData?['email'] as String?;
        }
        final firstName = rData?['firstName'] as String? ?? '';
        final lastName = rData?['lastName'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          reporterName = fullName;
        }
      }
    } catch (_) {}

    // Get target user details
    String? targetUserName;
    String? photoURL;
    try {
      final targetDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (targetDoc.exists) {
        final tData = targetDoc.data();
        final firstName = tData?['firstName'] as String? ?? '';
        final lastName = tData?['lastName'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();
        targetUserName = fullName.isNotEmpty ? fullName : tData?['displayName'] as String?;
        photoURL = tData?['photoURL'] as String?;
      }
    } catch (_) {}

    // Create a comprehensive report document using deterministic ID to prevent duplicates
    final docId = 'photo_${targetUserId}_${user.uid}';

    await _firestore.collection('reports').doc(docId).set({
      'targetUserId': targetUserId,
      'reporterId': user.uid,
      'reporterName': reporterName ?? 'Anonymous',
      'reporterEmail': reporterEmail ?? '',
      'creatorId': targetUserId,
      'creatorName': targetUserName ?? 'Unknown User',
      'secretType': 'profile_photo',
      'reportedContent': photoURL ?? '', // Save the photo URL at the time of reporting
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
