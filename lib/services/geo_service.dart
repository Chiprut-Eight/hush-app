import 'dart:math';

/// Geographic utility functions — matches web geoService.ts
class GeoService {
  /// Calculate distance between two lat/lng points in meters using Haversine formula
  static double distanceInMeters(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0; // Earth's radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Check if two positions are within a given radius
  static bool isWithinRadius(
    double userLat, double userLng,
    double targetLat, double targetLng,
    double radiusMeters,
  ) {
    return distanceInMeters(userLat, userLng, targetLat, targetLng) <= radiusMeters;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
