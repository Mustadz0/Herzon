/// Post content types
enum MediaType { text, image, video, vibe }

/// Post Model - represents a feed post
class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> mediaUrls;
  final MediaType mediaType;
  final double latitude;
  final double longitude;
  final String? contextTag;
  final Map<String, int> reactionCounts;
  final DateTime? createdAt;

  // Denormalized user data (for feed display)
  final String? userUsername;
  final String? userDisplayName;
  final String? userAvatarUrl;

  // Computed fields
  final double distanceMeters;
  final int commentCount;

  const PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrls = const [],
    this.mediaType = MediaType.text,
    required this.latitude,
    required this.longitude,
    this.contextTag,
    this.reactionCounts = const {},
    this.createdAt,
    this.userUsername,
    this.userDisplayName,
    this.userAvatarUrl,
    this.distanceMeters = 0.0,
    this.commentCount = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      mediaType: _parseMediaType(json['media_type']),
      latitude: (json['latitude'] as num?)?.toDouble() ??
          ((json['location'] as Map<String, dynamic>?)?['coordinates'] as List?)?.last ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ??
          ((json['location'] as Map<String, dynamic>?)?['coordinates'] as List?)?.first ?? 0.0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'media_urls': mediaUrls,
      'media_type': mediaType.name,
      'latitude': latitude,
      'longitude': longitude,
      'context_tag': contextTag,
      'reaction_counts': reactionCounts,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? mediaUrls,
    MediaType? mediaType,
    double? latitude,
    double? longitude,
    String? contextTag,
    Map<String, int>? reactionCounts,
    DateTime? createdAt,
    String? userUsername,
    String? userDisplayName,
    String? userAvatarUrl,
    double? distanceMeters,
    int? commentCount,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contextTag: contextTag ?? this.contextTag,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      createdAt: createdAt ?? this.createdAt,
      userUsername: userUsername ?? this.userUsername,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  static MediaType _parseMediaType(String? type) {
    return MediaType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => MediaType.text,
    );
  }
}
