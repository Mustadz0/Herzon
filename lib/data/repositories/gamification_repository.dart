import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IGamificationRepository {
  /// Get gamification stats for a user
  Future<Map<String, dynamic>> getUserGamification(String userId);

  /// Get the local leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard(double userLat, double userLng, {int limit = 50});
}

class SupabaseGamificationRepository implements IGamificationRepository {
  final SupabaseClient _supabase;

  SupabaseGamificationRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<Map<String, dynamic>> getUserGamification(String userId) async {
    final response = await _supabase.rpc('get_user_gamification', params: {
      'p_user_id': userId,
    }).maybeSingle();
    return response ?? <String, dynamic>{};
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(double userLat, double userLng, {int limit = 50}) async {
    final response = await _supabase.rpc('get_nearby_leaderboard', params: {
      'p_user_lat': userLat,
      'p_user_lng': userLng,
      'p_limit': limit,
    });

    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }
}

final gamificationRepositoryProvider = Provider<IGamificationRepository>((ref) {
  return SupabaseGamificationRepository(supabase: Supabase.instance.client);
});
