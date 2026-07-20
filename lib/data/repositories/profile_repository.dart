import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class ProfileData {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;

  const ProfileData({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        id: json['id'] as String,
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
      );
}

// ── Abstract ──────────────────────────────────────────────────────────────────

abstract class IProfileRepository {
  Future<ProfileData> getProfile(String userId);
  Future<List<PostModel>> getUserPosts(String userId, {int page = 1, int pageSize = 50});
}

// ── Supabase impl ─────────────────────────────────────────────────────────────

class SupabaseProfileRepository implements IProfileRepository {
  final SupabaseClient _client;
  const SupabaseProfileRepository(this._client);

  @override
  Future<ProfileData> getProfile(String userId) async {
    final result = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileData.fromJson(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<List<PostModel>> getUserPosts(
    String userId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _client.rpc(
      'get_user_posts',
      params: {
        'target_user_id': userId,
        'page': page,
        'page_size': pageSize,
      },
    ) as List;

    return result.map((p) {
      final e = Map<String, dynamic>.from(p as Map);
      return PostModel(
        id: e['id'] as String,
        userId: e['user_id'] as String,
        content: e['content'] as String? ?? '',
        mediaUrls: List<String>.from(e['media_urls'] as List? ?? []),
        mediaType: e['media_type'] == 'image' ? MediaType.image : MediaType.text,
        latitude: 0,
        longitude: 0,
        contextTag: e['context_tag'] as String?,
        reactionCounts:
            Map<String, int>.from(e['reaction_counts'] as Map? ?? {}),
        createdAt: e['created_at'] != null
            ? DateTime.parse(e['created_at'] as String)
            : null,
        userUsername: e['username'] as String?,
        userDisplayName: e['display_name'] as String?,
        userAvatarUrl: e['avatar_url'] as String?,
        distanceMeters: 0,
        commentCount: (e['comment_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});
