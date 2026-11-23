import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus { ok, serviceDisabled, denied, deniedForever, error }

class LocationResult {
  final LocationStatus status;
  final Position? position;
  const LocationResult(this.status, [this.position]);

  bool get ok => status == LocationStatus.ok && position != null;
}

/// Thin wrapper around geolocator that handles permission and reliable
/// real-time GPS acquisition with multi-stage accuracy fallbacks.
class LocationService {
  /// True when permission is already granted (no dialog will be shown).
  static Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  static Future<LocationResult> getCurrentPosition({bool askPermission = true}) async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) return const LocationResult(LocationStatus.serviceDisabled);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && askPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }

      Position? position;

      // 1) Try high-accuracy real-time fix
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (e) {
        debugPrint('High accuracy GPS fetch: $e');
      }

      // 2) Fallback to last known position if device was indoors
      if (position == null) {
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      // 3) Fallback to medium accuracy (WiFi/cellular network, fast indoors)
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 7),
            ),
          );
        } catch (_) {}
      }

      if (position != null) {
        return LocationResult(LocationStatus.ok, position);
      }

      return const LocationResult(LocationStatus.error);
    } catch (e) {
      debugPrint('LocationService error: $e');
      return const LocationResult(LocationStatus.error);
    }
  }

  static Future<void> openAppSettings() => Geolocator.openAppSettings();
  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
