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
              id: json['id'],
              userId: json['user_id'],
              content: json['content'],
              mediaUrls: List<String>.from(json['media_urls'] ?? []),
              mediaType: _parseMediaType(json['media_type']),
              latitude: location.latitude,
              longitude: location.longitude,
              contextTag: json['context_tag'],
              reactionCounts: Map<String, int>.from(json['reaction_counts'] ?? {}),
              createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
              userUsername: json['username'],
              userDisplayName: json['display_name'],
              userAvatarUrl: json['avatar_url'],
              distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
              commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
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
    }).select().single();

    return PostModel.fromJson(response);
  }

  @override
  Future<void> reactToPost(String postId, String reactionType) async {
    await _supabase.from('reactions').insert({
      'post_id': postId,
      'reaction_type': reactionType,
    });
  }

  @override
  Future<void> removeReaction(String postId, String reactionType) async {
    await _supabase
        .from('reactions')
        .delete()
        .eq('post_id', postId)
        .eq('reaction_type', reactionType);
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
