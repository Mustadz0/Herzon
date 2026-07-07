import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IFollowRepository {
  Future<bool> isFollowing(String followerId, String followingId);
  Future<void> follow(String followerId, String followingId);
  Future<void> unfollow(String followerId, String followingId);
  Future<int> getFollowerCount(String userId);
  Future<int> getFollowingCount(String userId);
}

class SupabaseFollowRepository implements IFollowRepository {
  final SupabaseClient _supabase;

  SupabaseFollowRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
    final data = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return data != null;
  }

  @override
  Future<void> follow(String followerId, String followingId) async {
    await _supabase.from('follows').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  @override
  Future<void> unfollow(String followerId, String followingId) async {
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  @override
  Future<int> getFollowerCount(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('id')
        .eq('following_id', userId);
    return data.length;
  }

  @override
  Future<int> getFollowingCount(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', userId);
    return data.length;
  }
}

final followRepositoryProvider = Provider<IFollowRepository>((ref) {
  return SupabaseFollowRepository(supabase: Supabase.instance.client);
});
