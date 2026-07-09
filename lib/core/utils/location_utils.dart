import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Geolocation utilities for Proximité
class LocationUtils {
  /// Earth's radius in meters
  static const double earthRadius = 6371000;

  /// Calculate distance between two points in meters
  static double distanceInMeters(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, from, to);
  }

  /// Check if a point is within a given radius from a center point
  static bool isWithinRadius(LatLng center, LatLng point, double radiusMeters) {
    return distanceInMeters(center, point) <= radiusMeters;
  }

  /// Convert Position (from geolocator) to LatLng (for flutter_map)
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
