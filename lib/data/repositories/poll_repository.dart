import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/firebase_uuid.dart';

abstract class IPollRepository {
  /// Cast a vote on a poll post
  Future<void> votePoll(String postId, int optionIndex);

  /// Get aggregated poll results for a post
  Future<Map<String, dynamic>> getPollResults(String postId);

  /// Check if a user has already voted on a given poll
  Future<bool> hasVoted(String postId, String userId);
}

class SupabasePollRepository implements IPollRepository {
  final SupabaseClient _supabase;

  SupabasePollRepository({required SupabaseClient supabase}) : _supabase = supabase;

  /// Returns the current user's UUID v5 (converted from Firebase UID).
  String _currentUuid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseUuid.toUuid(uid);
  }

  @override
  Future<void> votePoll(String postId, int optionIndex) async {
    // FIX: كان يستخدم _supabase.auth.currentUser (Supabase Auth)
    // المشروع يعتمد Firebase Auth — يجب استخدام Firebase UUID
    final uuid = _currentUuid();
    await _supabase.rpc('vote_poll', params: {
      'post_id': postId,
      'user_id': uuid,
      'option_index': optionIndex,
    });
  }

  @override
  Future<Map<String, dynamic>> getPollResults(String postId) async {
    final response = await _supabase.rpc('get_poll_results', params: {'post_id': postId});
    return response as Map<String, dynamic>;
  }

  @override
  Future<bool> hasVoted(String postId, String userId) async {
    final result = await _supabase
        .from('poll_votes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    return result != null;
  }
}

final pollRepositoryProvider = Provider<IPollRepository>((ref) {
  return SupabasePollRepository(supabase: Supabase.instance.client);
});
