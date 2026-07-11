import 'package:herzon/data/models/post_model.dart';

/// Lightweight post returned by get_zone_posts RPC.
/// Mirrors PostModel fields needed for PostCard rendering.
class ZonePostModel {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? content;
  final String? mediaUrl;
  final String? mediaType;
  final String? contextTag;
  final int reactionsCount;
  final int commentsCount;
  final DateTime createdAt;
  final double distanceMeters;

  const ZonePostModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.content,
    this.mediaUrl,
    this.mediaType,
    this.contextTag,
    required this.reactionsCount,
    required this.commentsCount,
    required this.createdAt,
    required this.distanceMeters,
  });

  factory ZonePostModel.fromJson(Map<String, dynamic> j) => ZonePostModel(
        id: j['post_id'] as String,
        userId: j['user_id'] as String,
        displayName: j['display_name'] as String? ?? 'Utilisateur',
        avatarUrl: j['avatar_url'] as String?,
        content: j['content'] as String?,
        mediaUrl: j['media_url'] as String?,
        mediaType: j['media_type'] as String?,
        contextTag: j['context_tag'] as String?,
        reactionsCount: (j['reactions_count'] as num?)?.toInt() ?? 0,
        commentsCount: (j['comments_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
        distanceMeters: (j['distance_meters'] as num?)?.toDouble() ?? 0,
      );
}
