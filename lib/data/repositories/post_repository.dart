import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/post_model.dart';

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
}

class SupabasePostRepository implements IPostRepository {
  final SupabaseClient _supabase;

  SupabasePostRepository({required SupabaseClient supabase}) : _supabase = supabase;

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

    return (response as List<dynamic>)
        .map((json) => PostModel(
              id: json['id'] as String,
              userId: json['user_id'] as String,
              content: json['content'] as String,
              mediaUrls: List<String>.from(json['media_urls'] ?? []),
              mediaType: _parseMediaType(json['media_type']),
              latitude: location.latitude,
              longitude: location.longitude,
              contextTag: json['context_tag'] as String?,
              reactionCounts: Map<String, int>.from(json['reaction_counts'] ?? {}),
              createdAt: json['created_at'] != null
                  ? DateTime.parse(json['created_at'] as String)
                  : null,
              userUsername: json['username'] as String?,
              userDisplayName: json['display_name'] as String?,
              userAvatarUrl: json['avatar_url'] as String?,
              distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
              commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
              stickerId: json['sticker_id'] as String?,
              videoUrl: json['video_url'] as String?,
              pollOptions: json['poll'] != null
                  ? (json['poll'] as List<dynamic>)
                      .map((e) => PollOptionData.fromJson(e as Map<String, dynamic>))
                      .toList()
                  : null,
              pollTotalVotes: json['poll_total_votes'] as int?,
              userPollVoteIndex: json['user_poll_vote_index'] as int?,
            ))
        .toList();
  }

  @override
  Future<int> getNearbyPostsCount(LatLng location, double radiusMeters) async {
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
    final response = await _supabase.from('posts').insert({
      'user_id': post.userId,
      'content': post.content,
      'media_urls': post.mediaUrls,
      'media_type': post.mediaType.name,
      'location': 'POINT(${post.longitude} ${post.latitude})',
      'context_tag': post.contextTag,
      if (post.stickerId != null) 'sticker_id': post.stickerId,
    }).select().single();

    return PostModel.fromJson(response);
  }

  @override
  Future<void> reactToPost(String postId, String reactionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase.from('reactions').upsert({
      'post_id': postId,
      'user_id': userId,
      'reaction_type': reactionType,
    }, onConflict: 'post_id,user_id,reaction_type');
  }

  @override
  Future<void> removeReaction(String postId, String reactionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _supabase
        .from('reactions')
        .delete()
        .eq('post_id', postId)
        .eq('reaction_type', reactionType)
        .eq('user_id', userId);
  }

  @override
  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  @override
  Future<void> updatePost(String postId, String content) async {
    await _supabase.from('posts').update({'content': content}).eq('id', postId);
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
