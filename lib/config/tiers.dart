import 'package:flutter/material.dart';

/// Define the attributes associated with each Clout Tier.
class TierDef {
  final int level;
  final String colorHex;
  final Color color;
  final String name;
  final int requiredSuccesses;
  final int maxGroupUsers;
  final int timeWindowMinutes;

  const TierDef({
    required this.level,
    required this.colorHex,
    required this.color,
    required this.name,
    required this.requiredSuccesses,
    required this.maxGroupUsers,
    required this.timeWindowMinutes,
  });
}

/// The 10 official HUSH Tiers based on group secret successes.
class HushTiers {
  static const List<TierDef> tiers = [
    TierDef(
      level: 1,
      name: 'Default',
      colorHex: '#808080',
      color: Colors.grey,
      requiredSuccesses: 0,
      maxGroupUsers: 3,
      timeWindowMinutes: 1,
    ),
    TierDef(
      level: 2,
      name: 'Novice',
      colorHex: '#2196F3',
      color: Colors.blue,
      requiredSuccesses: 5,
      maxGroupUsers: 8,
      timeWindowMinutes: 2,
    ),
    TierDef(
      level: 3,
      name: 'Apprentice',
      colorHex: '#4CAF50',
      color: Colors.green,
      requiredSuccesses: 10,
      maxGroupUsers: 15,
      timeWindowMinutes: 3,
    ),
    TierDef(
      level: 4,
      name: 'Adept',
      colorHex: '#FFEB3B',
      color: Colors.yellow,
      requiredSuccesses: 15,
      maxGroupUsers: 25,
      timeWindowMinutes: 4,
    ),
    TierDef(
      level: 5,
      name: 'Expert',
      colorHex: '#FF9800',
      color: Colors.orange,
      requiredSuccesses: 20,
      maxGroupUsers: 40,
      timeWindowMinutes: 5,
    ),
    TierDef(
      level: 6,
      name: 'Master',
      colorHex: '#F44336',
      color: Colors.red,
      requiredSuccesses: 25,
      maxGroupUsers: 70,
      timeWindowMinutes: 6,
    ),
    TierDef(
      level: 7,
      name: 'Grandmaster',
      colorHex: '#9C27B0',
      color: Colors.purple,
      requiredSuccesses: 30,
      maxGroupUsers: 120,
      timeWindowMinutes: 8,
    ),
    TierDef(
      level: 8,
      name: 'Legend',
      colorHex: '#E91E63',
      color: Colors.pink,
      requiredSuccesses: 35,
      maxGroupUsers: 200,
      timeWindowMinutes: 10,
    ),
    TierDef(
      level: 9,
      name: 'Mythic',
      colorHex: '#00BCD4',
      color: Colors.cyan,
      requiredSuccesses: 40,
      maxGroupUsers: 350,
      timeWindowMinutes: 12,
    ),
    TierDef(
      level: 10,
      name: 'God Tier',
      colorHex: '#FFD700', // Pulsing Gold
      color: Color(0xFFFFD700),
      requiredSuccesses: 50,
      maxGroupUsers: 500, // Or infinity
      timeWindowMinutes: 15,
    ),
  ];

  static TierDef getTier(int level) {
    if (level < 1) return tiers.first;
    if (level > 10) return tiers.last;
    return tiers[level - 1];
  }

  /// Evaluates total successes and returns the designated tier level.
  static int calculateTierLevel(int totalSuccesses) {
    int level = 1;
    for (var tier in tiers) {
      if (totalSuccesses >= tier.requiredSuccesses) {
        level = tier.level;
      } else {
        break;
      }
    }
    return level;
  }
}
