class Geolocator {
  static Future<dynamic> getCurrentPosition({dynamic desiredAccuracy, dynamic timeLimit, dynamic locationSettings}) async => Position();
  static Future<dynamic> getLastKnownPosition() async => Position();
  static Future<bool> isLocationServiceEnabled() async => true;
  static Future<dynamic> checkPermission() async => LocationPermission.always;
}
class Position {
  final double latitude = 32.0853;
  final double longitude = 34.7818;
  final DateTime timestamp = DateTime.now();
}
class LocationPermission {
  static const always = 0;
  static const whileInUse = 1;
}
class LocationSettings {
  const LocationSettings({dynamic accuracy, dynamic distanceFilter, dynamic timeLimit});
}
class LocationAccuracy {
  static const high = 0;
  static const low = 1;
}
