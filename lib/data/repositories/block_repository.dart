import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IBlockRepository {
  /// Block a user
  Future<void> blockUser(String blockedId, String? reason);

  /// Unblock a user
  Future<void> unblockUser(String blockedId);

  /// Get list of blocked users for the current user
  Future<List<Map<String, dynamic>>> getBlockedUsers();

  /// Check if a user is blocked by the current user
  Future<bool> isBlocked(String userId);

  /// Get a list of blocked user IDs
  Future<List<String>> getBlockedUserIds();
}

class SupabaseBlockRepository implements IBlockRepository {
  final SupabaseClient _supabase;

  SupabaseBlockRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<void> blockUser(String blockedId, String? reason) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('blocks').insert({
      'blocker_id': userId,
      'blocked_id': blockedId,
      'reason': reason,
    });
  }

  @override
  Future<void> unblockUser(String blockedId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('blocks')
        .delete()
        .eq('blocker_id', userId)
        .eq('blocked_id', blockedId);
  }

  @override
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return await _supabase
        .from('blocks')
        .select('*, blocked:profiles!blocked_id(username, display_name, avatar_url)')
        .eq('blocker_id', userId)
        .order('created_at', ascending: false);
  }

  @override
  Future<bool> isBlocked(String userId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final result = await _supabase
        .from('blocks')
        .select('id')
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', userId)
        .maybeSingle();
    return result != null;
  }

  @override
  Future<List<String>> getBlockedUserIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = await _supabase
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', userId);

    return (data as List<dynamic>)
        .map((e) => e['blocked_id'] as String)
        .toList();
  }
}

final blockRepositoryProvider = Provider<IBlockRepository>((ref) {
  return SupabaseBlockRepository(supabase: Supabase.instance.client);
});
