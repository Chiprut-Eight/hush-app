import 'dart:async';

class Geolocator {
  static Future<Position> getCurrentPosition({dynamic desiredAccuracy, dynamic timeLimit, dynamic locationSettings}) async => Position(latitude: 32.0853, longitude: 34.7818, timestamp: DateTime.now(), accuracy: 10.0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
  static Future<Position> getLastKnownPosition() async => Position(latitude: 32.0853, longitude: 34.7818, timestamp: DateTime.now(), accuracy: 10.0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
  static Future<bool> isLocationServiceEnabled() async => true;
  static Future<LocationPermission> checkPermission() async => LocationPermission.always;
  static Future<LocationPermission> requestPermission() async => LocationPermission.always;
  static Stream<Position> getPositionStream({dynamic locationSettings}) => const Stream.empty();
  static double distanceBetween(double startLatitude, double startLongitude, double endLatitude, double endLongitude) => 0.0;
}

class Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double altitude;
  final double heading;
  final double speed;
  final double speedAccuracy;
  final double altitudeAccuracy;
  final double headingAccuracy;

  Position({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.speedAccuracy,
    this.altitudeAccuracy = 0.0,
    this.headingAccuracy = 0.0,
  });
}

enum LocationPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
}

class LocationSettings {
  const LocationSettings({dynamic accuracy, dynamic distanceFilter, dynamic timeLimit});
}

enum LocationAccuracy {
  lowest,
  low,
  medium,
  high,
  best,
  bestForNavigation,
}
