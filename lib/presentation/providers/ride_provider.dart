import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/ride_repository.dart';
import '../../services/location_service.dart';

class RideState {
  final List<RideModel> rides;
  final bool isLoading;
  final String? error;

  const RideState({
    this.rides = const [],
    this.isLoading = false,
    this.error,
  });

  RideState copyWith({
    List<RideModel>? rides,
    bool? isLoading,
    String? error,
  }) {
    return RideState(
      rides: rides ?? this.rides,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RideNotifier extends StateNotifier<RideState> {
  final IRideRepository _repo;
  final LocationService _locationService;

  RideNotifier(this._repo, this._locationService) : super(const RideState()) {
    _init();
  }

  Future<void> _init() async {}

  Future<void> loadNearbyRides({double radiusMeters = 10000}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final data = await _repo.getNearbyRides(pos.latitude, pos.longitude, radiusMeters: radiusMeters);
      final items = data.map((e) => RideModel.fromJson(e)).toList();
      state = state.copyWith(rides: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createRide(Map<String, dynamic> params) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.createRide(params);
      await loadNearbyRides();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> bookRide(String rideId, int seats) async {
    try {
      await _repo.bookRide(rideId, seats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  return RideNotifier(
    ref.watch(rideRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
