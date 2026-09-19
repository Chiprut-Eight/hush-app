import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model — matches Firestore 'users' collection schema
class HushUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final int tierLevel;
  final List<int> tierSuccesses;
  final int totalPublished;
  final int distinguishedCount;
  final int groupSuccesses;
  final List<String> savedSecretIds;
  final bool isGhostMode;
  final DateTime? ghostModeUntil;
  final DateTime createdAt;
  
  // Onboarding
  final bool isOnboarded;
  final bool hasSeenTutorial;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool useGenericPhoto;
  
  // Follow System
  final List<String> followingIds;
  final List<String> followerIds;

  // Search Optimization
  final String searchName;

  // Push Notifications
  final String? fcmToken;
  
  // Admin System
  final bool isAdmin;
  // Settings - Audio & Notifications
  final bool appSoundsMuted;
  final bool notificationsEnabled;
  final bool notifyNewFollowerSecrets;
  final bool notifyGroupUnlocks;
  final bool notifyNewFollower;
  final bool notifyInteractions;
  
  // Settings - Profile
  final DateTime? lastUsernameChange;

  HushUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.tierLevel = 1,
    this.tierSuccesses = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    this.totalPublished = 0,
    this.distinguishedCount = 0,
    this.groupSuccesses = 0,
    this.savedSecretIds = const [],
    this.isGhostMode = false,
    this.ghostModeUntil,
    this.isOnboarded = false,
    this.hasSeenTutorial = false,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.useGenericPhoto = false,
    this.searchName = '',
    this.followingIds = const [],
    this.followerIds = const [],
    this.fcmToken,
    this.isAdmin = false,
    this.appSoundsMuted = false,
    this.notificationsEnabled = true,
    this.notifyNewFollowerSecrets = true,
    this.notifyGroupUnlocks = true,
    this.notifyNewFollower = true,
    this.notifyInteractions = true,
    this.lastUsernameChange,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory HushUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HushUser(
      uid: data['uid'] ?? doc.id,
      displayName: data['displayName'],
      email: data['email'],
      photoURL: data['photoURL'],
      tierLevel: data['tierLevel'] ?? 1,
      tierSuccesses: List<int>.from(data['tierSuccesses'] ?? [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      totalPublished: data['totalPublished'] ?? 0,
      distinguishedCount: data['distinguishedCount'] ?? 0,
      groupSuccesses: data['groupSuccesses'] ?? 0,
      savedSecretIds: List<String>.from(data['savedSecretIds'] ?? []),
      isGhostMode: data['isGhostMode'] ?? false,
      ghostModeUntil: (data['ghostModeUntil'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnboarded: data['isOnboarded'] ?? false,
      hasSeenTutorial: data['hasSeenTutorial'] ?? false,
      firstName: data['firstName'],
      lastName: data['lastName'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: data['gender'],
      useGenericPhoto: data['useGenericPhoto'] ?? false,
      followingIds: List<String>.from(data['followingIds'] ?? []),
      followerIds: List<String>.from(data['followerIds'] ?? []),
      searchName: data['searchName'] ?? '',
      fcmToken: data['fcmToken'],
      isAdmin: data['isAdmin'] == true || data['isAdmin'] == 'true',
      appSoundsMuted: data['appSoundsMuted'] ?? false,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      notifyNewFollowerSecrets: data['notifyNewFollowerSecrets'] ?? true,
      notifyGroupUnlocks: data['notifyGroupUnlocks'] ?? true,
      notifyNewFollower: data['notifyNewFollower'] ?? true,
      notifyInteractions: data['notifyInteractions'] ?? true,
      lastUsernameChange: (data['lastUsernameChange'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoURL': photoURL,
    'tierLevel': tierLevel,
    'tierSuccesses': tierSuccesses,
    'totalPublished': totalPublished,
    'distinguishedCount': distinguishedCount,
    'groupSuccesses': groupSuccesses,
    'savedSecretIds': savedSecretIds,
    'isGhostMode': isGhostMode,
    'ghostModeUntil': ghostModeUntil != null ? Timestamp.fromDate(ghostModeUntil!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'isOnboarded': isOnboarded,
    'hasSeenTutorial': hasSeenTutorial,
    'firstName': firstName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
    'gender': gender,
    'useGenericPhoto': useGenericPhoto,
    'followingIds': followingIds,
    'followerIds': followerIds,
    'searchName': searchName,
    'fcmToken': fcmToken,
    'isAdmin': isAdmin,
    'appSoundsMuted': appSoundsMuted,
    'notificationsEnabled': notificationsEnabled,
    'notifyNewFollowerSecrets': notifyNewFollowerSecrets,
    'notifyGroupUnlocks': notifyGroupUnlocks,
    'notifyNewFollower': notifyNewFollower,
    'notifyInteractions': notifyInteractions,
    'lastUsernameChange': lastUsernameChange != null ? Timestamp.fromDate(lastUsernameChange!) : null,
  };
}
