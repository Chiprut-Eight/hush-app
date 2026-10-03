import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/constants.dart';
import '../services/geo_service.dart';

/// Location provider — matches web useGeolocation hook
class LocationProvider extends ChangeNotifier {
  double? _lat;
  double? _lng;
  double? _accuracy;
  String? _error;
  bool _loading = true;
  double? _lastLat;
  double? _lastLng;

  double? get lat => _lat;
  double? get lng => _lng;
  double? get accuracy => _accuracy;
  String? get error => _error;
  bool get loading => _loading;
  bool get hasPosition => _lat != null && _lng != null;

  LocationProvider() {
    _startWatching();
  }

  Future<void> _startWatching() async {
    _loading = true;
    _error = null;
    notifyListeners();

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'LOCATION_DISABLED';
      _loading = false;
      notifyListeners();
      return;
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'PERMISSION_DENIED';
        _loading = false;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error = 'PERMISSION_DENIED';
      _loading = false;
      notifyListeners();
      return;
    }

    // Start listening to position updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // We handle our own threshold
      ),
    ).listen(
      (Position position) {
        final newLat = position.latitude;
        final newLng = position.longitude;

        // Only update if first reading or moved more than threshold
        if (_lastLat == null ||
            _lastLng == null ||
            GeoService.distanceInMeters(_lastLat!, _lastLng!, newLat, newLng) >=
                AppConstants.minMoveThreshold) {
          _lastLat = newLat;
          _lastLng = newLng;
          _lat = newLat;
          _lng = newLng;
          _accuracy = position.accuracy;
          _loading = false;
          _error = null;
          notifyListeners();
        }
      },
      onError: (error) {
        _error = 'POSITION_UNAVAILABLE';
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> retry() async {
    await _startWatching();
  }
}
