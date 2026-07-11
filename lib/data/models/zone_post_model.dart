import 'post_model.dart';

/// Lightweight post returned by get_zone_posts RPC.
/// Column names match the updated Supabase RPC (2026-07).
class ZonePostModel {
  final String id;
  final String userId;
  final String? userDisplayName;
  final String? userUsername;
  final String? userAvatarUrl;
  final String? content;
  final List<String> mediaUrls;
  final String? mediaType;
  final String? contextTag;
  final String? stickerId;
  final Map<String, int> reactionCounts;
  final int commentCount;
  final DateTime? createdAt;
  final String? zoneId;

  const ZonePostModel({
    required this.id,
    required this.userId,
    this.userDisplayName,
    this.userUsername,
    this.userAvatarUrl,
    this.content,
    this.mediaUrls = const [],
    this.mediaType,
    this.contextTag,
    this.stickerId,
    this.reactionCounts = const {},
    this.commentCount = 0,
    this.createdAt,
    this.zoneId,
  });

  factory ZonePostModel.fromJson(Map<String, dynamic> j) => ZonePostModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        // New RPC columns: user_display_name, user_username, user_avatar_url
        userDisplayName: j['user_display_name'] as String?,
        userUsername: j['user_username'] as String?,
        userAvatarUrl: j['user_avatar_url'] as String?,
        content: j['content'] as String?,
        mediaUrls: List<String>.from(j['media_urls'] ?? []),
        mediaType: j['media_type'] as String?,
        contextTag: j['context_tag'] as String?,
        stickerId: j['sticker_id'] as String?,
        reactionCounts:
            (j['reaction_counts'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
        commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
        zoneId: j['zone_id'] as String?,
      );

  /// Convert to PostModel for use with PostCard widget.
  PostModel toPostModel({
    double latitude = 0.0,
    double longitude = 0.0,
  }) =>
      PostModel(
        id: id,
        userId: userId,
        content: content ?? '',
        mediaUrls: mediaUrls,
        mediaType: MediaType.values.firstWhere(
          (e) => e.name == mediaType,
          orElse: () => MediaType.text,
        ),
        latitude: latitude,
        longitude: longitude,
        zoneId: zoneId,
        contextTag: contextTag,
        stickerId: stickerId,
        reactionCounts: reactionCounts,
        commentCount: commentCount,
        createdAt: createdAt,
        userDisplayName: userDisplayName,
        userUsername: userUsername,
        userAvatarUrl: userAvatarUrl,
      );
}
