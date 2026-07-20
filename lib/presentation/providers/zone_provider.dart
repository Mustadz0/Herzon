// Fix: zoneProvider كان يستخدم ref.read للـ repository — غُيّر لـ ref.watch.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/zone_model.dart';
import '../../data/repositories/zone_repository.dart';

final zoneRepositoryProvider = Provider<IZoneRepository>((ref) {
  return SupabaseZoneRepository(Supabase.instance.client);
});

class ZoneState {
  final bool isLoading;
  final List<ZoneModel> zones;
  final List<ZoneModel> searchResults;
  final String searchQuery;
  final String? error;

  const ZoneState({
    this.isLoading = false,
    this.zones = const [],
    this.searchResults = const [],
    this.searchQuery = '',
    this.error,
  });

  List<ZoneModel> get displayedZones =>
      searchQuery.isNotEmpty ? searchResults : zones;

  ZoneState copyWith({
    bool? isLoading,
    List<ZoneModel>? zones,
    List<ZoneModel>? searchResults,
    String? searchQuery,
    String? error,
  }) {
    return ZoneState(
      isLoading: isLoading ?? this.isLoading,
      zones: zones ?? this.zones,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

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
      if (mounted) state = state.copyWith(isLoading: false, zones: zones);
    } catch (e) {
      if (mounted)
        state = state.copyWith(
          isLoading: false,
          error: 'Impossible de charger les zones.',
        );
    }
  }

  Future<void> searchZones(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        searchResults: [],
        error: null,
      );
      return;
    }
    state = state.copyWith(
      isLoading: true,
      searchQuery: trimmed,
      error: null,
    );
    try {
      final results = await _repository.searchZonesByName(trimmed);
      if (mounted)
        state = state.copyWith(isLoading: false, searchResults: results);
    } catch (e) {
      if (mounted)
        state = state.copyWith(isLoading: false, error: 'Recherche impossible.');
    }
  }

  void clear() => state = const ZoneState();
}

// Fix: ref.watch بدل ref.read
final zoneProvider =
    StateNotifierProvider<ZoneNotifier, ZoneState>((ref) {
  return ZoneNotifier(ref.watch(zoneRepositoryProvider));
});
