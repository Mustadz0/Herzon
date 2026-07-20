// Fix: AdminStatsNotifier استخدم SupabaseClient مباشرة وكان يتحقق من is_admin
// يدوياً — الآن عبر AdminRepository الذي يتحقق داخلياً.
// DashboardStats معرّف هنا — الترحيل سيكسر admin_repository إذا كان معرفاً هناك.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_provider.dart' show adminRepositoryProvider;

export '../../data/repositories/admin_repository.dart' show DashboardStats;

class AdminStatsNotifier
    extends StateNotifier<AsyncValue<DashboardStats>> {
  final AdminRepository _repo;

  AdminStatsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      // admin check happens inside _repo.getStats()
      final stats = await _repo.getStats();
      if (mounted) state = AsyncValue.data(stats);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}

final adminStatsProvider = StateNotifierProvider<AdminStatsNotifier,
    AsyncValue<DashboardStats>>((ref) {
  return AdminStatsNotifier(ref.watch(adminRepositoryProvider));
});
