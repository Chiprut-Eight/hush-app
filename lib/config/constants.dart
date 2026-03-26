/// App-wide constants matching the web app's configuration
class AppConstants {
  /// Radius (in meters) within which a secret can be revealed
  static const double revealRadiusMeters = 15.0;

  /// Radius (in meters) for fetching nearby secrets in the feed
  static const double feedRadiusMeters = 500.0;

  /// Radius (in meters) for the echo map visualization
  static const double echoMapRadiusMeters = 1000.0;

  /// Maximum number of secrets a user can save
  static const int maxSavedSecrets = 50;

  /// Maximum length of a text secret
  static const int maxSecretLength = 140;

  /// Maximum voice recording duration in seconds
  static const int maxRecordingSeconds = 60;

  /// Minimum distance (meters) user must move before position state updates
  static const double minMoveThreshold = 5.0;

  /// Maximum number of viewed secret IDs to store locally
  static const int maxViewedSecrets = 500;

  /// Admin UID (owner only)
  static const String adminUid = 'A30Br3OakdXF5BnfQFu5pryOsgy2';

  /// Default map zoom level
  static const double defaultMapZoom = 15.0;

  /// Default map center (Tel Aviv)
  static const double defaultLat = 32.08;
  static const double defaultLng = 34.78;
}
