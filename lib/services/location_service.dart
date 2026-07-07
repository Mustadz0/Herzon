import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/utils/location_utils.dart';
import '../core/constants/app_constants.dart';

/// Service for tracking user location and managing geofencing
class LocationService {
  StreamSubscription<Position>? _positionStream;
  LatLng? _lastKnownPosition;

  LatLng? get lastKnownPosition => _lastKnownPosition;

  /// Initialize and start location tracking
  Future<LatLng> initializeLocation() async {
    final position = await LocationUtils.getCurrentPosition();
    _lastKnownPosition = LocationUtils.positionToLatLng(position);
    return _lastKnownPosition!;
  }

  /// Start listening to location updates
  void startLocationTracking(Function(LatLng) onLocationUpdate) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _lastKnownPosition = LocationUtils.positionToLatLng(position);
      onLocationUpdate(_lastKnownPosition!);
    });
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Check if the user is in active mode (within 500m of last post)
  bool isInActiveMode(LatLng postLocation, {double? radius}) {
    if (_lastKnownPosition == null) return false;
    return LocationUtils.isWithinRadius(
      _lastKnownPosition!,
      postLocation,
      radius ?? AppConstants.proximityRadiusMeters,
    );
  }
}

/// Riverpod Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// State for location
final currentLocationProvider = StateNotifierProvider<LocationNotifier, LatLng?>((ref) {
  return LocationNotifier(ref.read(locationServiceProvider));
});

class LocationNotifier extends StateNotifier<LatLng?> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      final position = await _locationService.initializeLocation();
      state = position;
      _locationService.startLocationTracking((newLocation) {
        state = newLocation;
      });
    } catch (e) {
      // Handle location permission errors
    }
  }

  @override
  void dispose() {
    _locationService.stopLocationTracking();
    super.dispose();
  }
}
