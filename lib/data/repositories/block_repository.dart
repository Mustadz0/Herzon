import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/firebase_uuid.dart';

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
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('User not authenticated');
    final userId = FirebaseUuid.toUuid(fbUser.uid);

    await _supabase.from('blocks').insert({
      'blocker_id': userId,
      'blocked_id': FirebaseUuid.toUuid(blockedId),
      'reason': reason,
    });
  }

  @override
  Future<void> unblockUser(String blockedId) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('User not authenticated');
    final userId = FirebaseUuid.toUuid(fbUser.uid);

    await _supabase
        .from('blocks')
        .delete()
        .eq('blocker_id', userId)
        .eq('blocked_id', FirebaseUuid.toUuid(blockedId));
  }

  @override
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('User not authenticated');
    final userId = FirebaseUuid.toUuid(fbUser.uid);

    return await _supabase
        .from('blocks')
        .select('*, blocked:profiles!blocked_id(username, display_name, avatar_url)')
        .eq('blocker_id', userId)
        .order('created_at', ascending: false);
  }

  @override
  Future<bool> isBlocked(String userId) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('User not authenticated');
    final currentUserId = FirebaseUuid.toUuid(fbUser.uid);

    final result = await _supabase
        .from('blocks')
        .select('id')
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', FirebaseUuid.toUuid(userId))
        .maybeSingle();
    return result != null;
  }

  @override
  Future<List<String>> getBlockedUserIds() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('User not authenticated');
    final userId = FirebaseUuid.toUuid(fbUser.uid);

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
