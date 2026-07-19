import 'dart:math';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';

/// Geolocation utilities for Proximité
class LocationUtils {
  /// Earth's radius in meters
  static const double earthRadius = 6371000;

  /// Calculate distance between two points in meters using the Haversine formula.
  static double distanceInMeters(LatLng from, LatLng to) {
    final double lat1 = from.latitude * pi / 180;
    final double lat2 = to.latitude * pi / 180;
    final double dLat = (to.latitude - from.latitude) * pi / 180;
    final double dLng = (to.longitude - from.longitude) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Check if a point is within a given radius from a center point
  static bool isWithinRadius(LatLng center, LatLng point, double radiusMeters) {
    return distanceInMeters(center, point) <= radiusMeters;
  }

  /// Convert Position (from geolocator) to MapLibre LatLng
  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  /// Get current position with high accuracy
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Create a circle polygon (approximation) for map display
  static List<LatLng> createCirclePolygon(LatLng center, double radiusMeters, {int points = 64}) {
    final List<LatLng> polygonPoints = [];
    final double lat = center.latitude;
    final double lng = center.longitude;

    for (int i = 0; i < points; i++) {
      final double angle = 2 * pi * i / points;
      final double dx = radiusMeters * cos(angle);
      final double dy = radiusMeters * sin(angle);

      final double newLat = lat + (dy / earthRadius) * (180 / pi);
      final double newLng = lng + (dx / (earthRadius * cos(pi * lat / 180))) * (180 / pi);

      polygonPoints.add(LatLng(newLat, newLng));
    }

    return polygonPoints;
  }
}
