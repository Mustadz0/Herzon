import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/post_model.dart';
import '../../core/utils/firebase_uuid.dart';

abstract class IPostRepository {
  Future<List<PostModel>> getNearbyPosts(
    LatLng location,
    double radiusMeters, {
    int page = 1,
    int pageSize = 20,
  });

  Future<int> getNearbyPostsCount(LatLng location, double radiusMeters);

  Future<PostModel> createPost(PostModel post);

  Future<void> reactToPost(String postId, String reactionType);

  Future<void> removeReaction(String postId, String reactionType);

  Future<void> deletePost(String postId);

  Future<void> updatePost(String postId, String content);

  Future<void> hidePost(String postId);

  Future<void> unhidePost(String postId);

  Future<Set<String>> getHiddenPostIds();
}

class SupabasePostRepository implements IPostRepository {
  final SupabaseClient _supabase;

  SupabasePostRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  /// Returns the current user's UUID v5 (converted from Firebase UID).
  /// Throws if not authenticated.
  String _currentUuid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    return FirebaseUuid.toUuid(uid);
  }

  @override
  Future<List<PostModel>> getNearbyPosts(
    LatLng location,
    double radiusMeters, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _supabase.rpc(
      'get_nearby_posts',
      params: {
        'user_lat': location.latitude,
        'user_lng': location.longitude,
        'radius_meters': radiusMeters,
        'page': page,
        'page_size': pageSize,
      },
    );

    return (response as List<dynamic>).map((json) {
      final j = json as Map<String, dynamic>;
      List<PollOptionData>? pollOptions;
      final pollRaw = j['poll'];
      if (pollRaw is Map<String, dynamic>) {
        final opts = pollRaw['options'];
        if (opts is List) {
          pollOptions = opts
              .map((e) => PollOptionData.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (pollRaw is List) {
        pollOptions = pollRaw
            .map((e) => PollOptionData.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return PostModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        content: j['content'] as String? ?? '',
        mediaUrls: List<String>.from(j['media_urls'] ?? []),
        mediaType: _parseMediaType(j['media_type']),
        // FIX: كان يستخدم location.latitude/longitude الثابتة من المستخدم
        // الصحيح: استخدام الإحداثيات الفعلية لكل منشور من الـ response
        latitude: (j['post_lat'] as num?)?.toDouble() ?? location.latitude,
        longitude: (j['post_lng'] as num?)?.toDouble() ?? location.longitude,
        zoneId: j['zone_id'] as String?,
        contextTag: j['context_tag'] as String?,
        reactionCounts:
            (j['reaction_counts'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
        userUsername: j['user_username'] as String?,
        userDisplayName: j['user_display_name'] as String?,
        userAvatarUrl: j['user_avatar_url'] as String?,
        distanceMeters: (j['distance'] as num?)?.toDouble() ?? 0.0,
        commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
        pollOptions: pollOptions,
        pollTotalVotes: j['poll_total_votes'] as int?,
        userPollVoteIndex: j['user_poll_vote_index'] as int?,
        stickerId: j['sticker_id'] as String?,
        videoUrl: j['video_url'] as String?,
      );
    }).toList();
  }

  @override
  Future<int> getNearbyPostsCount(
      LatLng location, double radiusMeters) async {
    final response = await _supabase.rpc(
      'get_nearby_posts_count',
      params: {
        'user_lat': location.latitude,
        'user_lng': location.longitude,
        'radius_meters': radiusMeters,
      },
    );
    return (response as num).toInt();
  }

  @override
  Future<PostModel> createPost(PostModel post) async {
    final response = await _supabase.rpc(
      'create_post_with_location',
      params: {
        'p_user_id': post.userId,
        'p_content': post.content,
        'p_media_urls': post.mediaUrls,
        'p_media_type': post.mediaType.name,
        'p_lat': post.latitude,
        'p_lng': post.longitude,
        'p_context_tag': post.contextTag,
        'p_sticker_id': post.stickerId,
        'p_zone_id': post.zoneId,
        'p_poll': post.pollOptions != null
            ? {'options': post.pollOptions!.map((e) => e.toJson()).toList()}
            : null,
      },
    );
    return PostModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> reactToPost(String postId, String reactionType) async {
    final uuid = _currentUuid();
    await _supabase.from('reactions').upsert({
      'post_id': postId,
      'user_id': uuid,
      'reaction_type': reactionType,
    }, onConflict: 'post_id,user_id');
  }

  @override
  Future<void> removeReaction(String postId, String reactionType) async {
    final uuid = _currentUuid();
    await _supabase
        .from('reactions')
        .delete()
        .eq('post_id', postId)
        .eq('reaction_type', reactionType)
        .eq('user_id', uuid);
  }

  @override
  Future<void> deletePost(String postId) async {
    await _supabase
        .from('posts')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', postId);
  }

  @override
  Future<void> updatePost(String postId, String content) async {
    await _supabase
        .from('posts')
        .update({'content': content})
        .eq('id', postId);
  }

  @override
  Future<void> hidePost(String postId) async {
    final uuid = _currentUuid();
    await _supabase.from('hidden_posts').upsert({
      'user_id': uuid,
      'post_id': postId,
    }, onConflict: 'user_id,post_id');
  }

  @override
  Future<void> unhidePost(String postId) async {
    final uuid = _currentUuid();
    await _supabase
        .from('hidden_posts')
        .delete()
        .eq('user_id', uuid)
        .eq('post_id', postId);
  }

  @override
  Future<Set<String>> getHiddenPostIds() async {
    final uuid = _currentUuid();
    final response = await _supabase
        .from('hidden_posts')
        .select('post_id')
        .eq('user_id', uuid);
    return (response as List<dynamic>)
        .map((e) => e['post_id'] as String)
        .toSet();
  }

  MediaType _parseMediaType(String? type) {
    return MediaType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => MediaType.text,
    );
  }
}

final postRepositoryProvider = Provider<IPostRepository>((ref) {
  final supabase = Supabase.instance.client;
  return SupabasePostRepository(supabase: supabase);
});
