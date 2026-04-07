import 'package:cloud_firestore/cloud_firestore.dart';

/// Secret model — matches Firestore 'secrets' collection schema
class Secret {
  final String id;
  final String creatorId;
  final String? creatorName;
  final String? creatorPhotoURL;
  final int creatorTierLevel;
  final String creatorTierColor;
  final String type; // 'text' | 'voice'
  final String? textContent;
  final String? audioURL;
  final int audioDuration;
  final double lat;
  final double lng;
  final int views;
  final int likes;
  final int dislikes;
  final bool isGroup;
  final int? minTierLevel;
  final int? requiredUsers;
  final int? timeWindowMinutes;
  final int reportCount;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime expiresAt;

  Secret({
    required this.id,
    required this.creatorId,
    this.creatorName,
    this.creatorPhotoURL,
    this.creatorTierLevel = 1,
    this.creatorTierColor = '#8b8b8b',
    this.type = 'text',
    this.textContent,
    this.audioURL,
    this.audioDuration = 0,
    required this.lat,
    required this.lng,
    this.views = 0,
    this.likes = 0,
    this.dislikes = 0,
    this.isGroup = false,
    this.minTierLevel,
    this.requiredUsers,
    this.timeWindowMinutes,
    this.reportCount = 0,
    this.isHidden = false,
    this.unlockedBy = const [],
    DateTime? createdAt,
    DateTime? expiresAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 24));
  
  final List<String> unlockedBy;

  factory Secret.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Secret(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'],
      creatorPhotoURL: data['creatorPhotoURL'],
      creatorTierLevel: data['creatorTierLevel'] ?? 1,
      creatorTierColor: data['creatorTierColor'] ?? '#8b8b8b',
      type: data['type'] ?? 'text',
      textContent: data['textContent'],
      audioURL: data['audioURL'],
      audioDuration: data['audioDuration'] ?? 0,
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      views: data['views'] ?? data['listens'] ?? 0,
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      isGroup: data['isGroup'] ?? false,
      minTierLevel: data['minTierLevel'],
      requiredUsers: data['requiredUsers'],
      timeWindowMinutes: data['timeWindowMinutes'],
      unlockedBy: List<String>.from(data['unlockedBy'] ?? []),
      reportCount: data['reportCount'] ?? 0,
      isHidden: data['isHidden'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'creatorId': creatorId,
    'creatorName': creatorName,
    'creatorPhotoURL': creatorPhotoURL,
    'creatorTierLevel': creatorTierLevel,
    'creatorTierColor': creatorTierColor,
    'type': type,
    'textContent': textContent,
    'audioURL': audioURL,
    'audioDuration': audioDuration,
    'lat': lat,
    'lng': lng,
    'views': views,
    'likes': likes,
    'dislikes': dislikes,
    'isGroup': isGroup,
    'minTierLevel': minTierLevel,
    'requiredUsers': requiredUsers,
    'timeWindowMinutes': timeWindowMinutes,
    'unlockedBy': unlockedBy,
    'reportCount': reportCount,
    'isHidden': isHidden,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
  };
}
