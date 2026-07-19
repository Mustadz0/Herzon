import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/firebase_uuid.dart';

class DashboardStats {
  final int totalUsers;
  final int totalPosts;
  final int pendingReports;
  final int activeUsersToday;
  final List<Map<String, dynamic>> postsLast7Days;
  final List<Map<String, dynamic>> topZones;

  DashboardStats({
    this.totalUsers = 0,
    this.totalPosts = 0,
    this.pendingReports = 0,
    this.activeUsersToday = 0,
    this.postsLast7Days = const [],
    this.topZones = const [],
  });
}

class AdminStatsNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final SupabaseClient _supabase;

  AdminStatsNotifier(this._supabase) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('Not authenticated');
      final currentUserId = FirebaseUuid.toUuid(firebaseUser.uid);

      final profile = await _supabase.from('profiles').select('is_admin').eq('id', currentUserId).single();
      if (profile['is_admin'] != true) throw Exception('Unauthorized: admin only');

      final usersCountResp = await _supabase.from('profiles').select('id').count();
      final postsCountResp = await _supabase.from('posts').select('id').count();
      final reportsCountResp = await _supabase.from('reports').select('id').eq('status', 'pending').count();
      final activeCountResp = await _supabase.from('profiles').select('id').gte('last_active_at', DateTime.now().subtract(const Duration(hours: 24)).toIso8601String()).count();
      final postsLast7Days = await _supabase.rpc('get_posts_last_7_days');
      final topZones = await _supabase.rpc('get_top_zones');

      final stats = DashboardStats(
        totalUsers: usersCountResp.count,
        totalPosts: postsCountResp.count,
        pendingReports: reportsCountResp.count,
        activeUsersToday: activeCountResp.count,
        postsLast7Days: (postsLast7Days as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        topZones: (topZones as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      );

      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminStatsProvider = StateNotifierProvider<AdminStatsNotifier, AsyncValue<DashboardStats>>((ref) {
  return AdminStatsNotifier(Supabase.instance.client);
});
