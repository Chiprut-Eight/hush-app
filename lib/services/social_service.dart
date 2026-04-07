import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hush_user.dart';
import '../models/secret.dart';

class FollowedUserFeedItem {
  final HushUser user;
  final Secret? latestSecret;

  FollowedUserFeedItem({required this.user, this.latestSecret});
}

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      
      for (var userDoc in usersSnap.docs) {
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
        
        feedItems.add(FollowedUserFeedItem(user: user, latestSecret: latest));
      }
    }

    // Sort by whoever mapped latest secret (if they have none, push to bottom)
    feedItems.sort((a, b) {
      final ta = a.latestSecret?.createdAt.millisecondsSinceEpoch ?? 0;
      final tb = b.latestSecret?.createdAt.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta); // Descending
    });

    return feedItems;
  }
}
