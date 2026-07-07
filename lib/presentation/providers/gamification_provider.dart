import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gamification_model.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../services/location_service.dart';

class GamificationState {
  final UserLevelModel? userLevel;
  final List<LeaderboardEntryModel> leaderboard;
  final bool isLoading;
  final String? error;

  const GamificationState({
    this.userLevel,
    this.leaderboard = const [],
    this.isLoading = false,
    this.error,
  });

  GamificationState copyWith({
    UserLevelModel? userLevel,
    List<LeaderboardEntryModel>? leaderboard,
    bool? isLoading,
    String? error,
  }) {
    return GamificationState(
      userLevel: userLevel ?? this.userLevel,
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  final IGamificationRepository _repo;
  final LocationService _locationService;

  GamificationNotifier(this._repo, this._locationService) : super(const GamificationState()) {
    _init();
  }

  Future<void> _init() async {}

  Future<void> loadUserStats(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getUserGamification(userId);
      if (data.isEmpty) {
        state = const GamificationState(isLoading: false);
        return;
      }
      final stats = UserLevelModel.fromJson(data);
      state = state.copyWith(userLevel: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadLeaderboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final data = await _repo.getLeaderboard(pos.latitude, pos.longitude);
      final items = data.map((e) => LeaderboardEntryModel.fromJson(e)).toList();
      state = state.copyWith(leaderboard: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier(
    ref.watch(gamificationRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
