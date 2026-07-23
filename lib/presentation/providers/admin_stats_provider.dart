import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository.dart';

class AdminStatsNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final AdminRepository _repo;

  AdminStatsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repo.getStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminStatsProvider =
    StateNotifierProvider<AdminStatsNotifier, AsyncValue<DashboardStats>>((ref) {
  return AdminStatsNotifier(ref.watch(adminRepositoryProvider));
});
