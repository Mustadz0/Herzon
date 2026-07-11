import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/zone_model.dart';
import '../../data/repositories/zone_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------
final zoneRepositoryProvider = Provider<IZoneRepository>((ref) {
  return SupabaseZoneRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class ZoneState {
  final bool isLoading;
  final List<ZoneModel> zones;
  final String? error;

  const ZoneState({
    this.isLoading = false,
    this.zones = const [],
    this.error,
  });

  ZoneState copyWith({
    bool? isLoading,
    List<ZoneModel>? zones,
    String? error,
  }) {
    return ZoneState(
      isLoading: isLoading ?? this.isLoading,
      zones: zones ?? this.zones,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class ZoneNotifier extends StateNotifier<ZoneState> {
  final IZoneRepository _repository;

  ZoneNotifier(this._repository) : super(const ZoneState());

  Future<void> loadNearbyZones({
    required double lat,
    required double lng,
    int radiusMeters = 500,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final zones = await _repository.getNearbyZones(
        userLat: lat,
        userLng: lng,
        radiusMeters: radiusMeters,
      );
      state = state.copyWith(isLoading: false, zones: zones);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clear() => state = const ZoneState();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final zoneProvider =
    StateNotifierProvider<ZoneNotifier, ZoneState>((ref) {
  return ZoneNotifier(ref.read(zoneRepositoryProvider));
});
