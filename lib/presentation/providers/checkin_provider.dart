import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/checkin_model.dart';
import '../../data/models/badge_model.dart';
import '../../data/repositories/checkin_repository.dart';

class CheckinState {
  final List<CheckinModel> checkins;
  final List<UserBadgeModel> badges;
  final bool isLoading;
  final String? error;

  const CheckinState({
    this.checkins = const [],
    this.badges = const [],
    this.isLoading = false,
    this.error,
  });

  CheckinState copyWith({
    List<CheckinModel>? checkins,
    List<UserBadgeModel>? badges,
    bool? isLoading,
    String? error,
  }) {
    return CheckinState(
      checkins: checkins ?? this.checkins,
      badges: badges ?? this.badges,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CheckinNotifier extends StateNotifier<CheckinState> {
  final ICheckinRepository _repo;

  CheckinNotifier(this._repo) : super(const CheckinState()) {
    _init();
  }

  Future<void> _init() async {}

  Future<void> checkin(String placeName, double lat, double lng) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.checkinPlace(placeName, lat, lng);
      await loadCheckins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadCheckins() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getUserCheckins();
      final items = data.map((e) => CheckinModel.fromJson(e)).toList();
      state = state.copyWith(checkins: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadBadges() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getUserBadges();
      final items = data.map((e) => UserBadgeModel.fromJson(e)).toList();
      state = state.copyWith(badges: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final checkinProvider = StateNotifierProvider<CheckinNotifier, CheckinState>((ref) {
  return CheckinNotifier(ref.watch(checkinRepositoryProvider));
});
