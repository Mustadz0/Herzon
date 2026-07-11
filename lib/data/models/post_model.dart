/// Post content types
enum MediaType { text, image, video, vibe, sticker }

/// Poll option data
class PollOptionData {
  final String text;
  final int votes;

  const PollOptionData({required this.text, this.votes = 0});

  factory PollOptionData.fromJson(Map<String, dynamic> json) =>
      PollOptionData(
        text: json['text'] as String? ?? '',
        votes: json['votes'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'text': text, 'votes': votes};

  /// Returns the percentage of this option out of [totalVotes].
  /// Returns 0.0 if [totalVotes] is 0 to avoid division by zero.
  double percentageOf(int totalVotes) =>
      totalVotes == 0 ? 0.0 : (votes / totalVotes) * 100;
}

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

  // Poll support
  final List<PollOptionData>? pollOptions;
  final int? userPollVoteIndex;
  final int? pollTotalVotes;

  // Sticker support
  final String? stickerId;

  // Video support
  final String? videoUrl;

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
    this.pollOptions,
    this.userPollVoteIndex,
    this.pollTotalVotes,
    this.stickerId,
    this.videoUrl,
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
      pollOptions: json['poll'] != null
          ? (json['poll'] as List<dynamic>)
              .map((e) => PollOptionData.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      userPollVoteIndex: json['user_poll_vote_index'] as int?,
      pollTotalVotes: json['poll_total_votes'] as int?,
      stickerId: json['sticker_id'] as String?,
      videoUrl: json['video_url'] as String?,
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
      'distance_meters': distanceMeters,
      'comment_count': commentCount,
      'poll': pollOptions?.map((e) => e.toJson()).toList(),
      'poll_total_votes': pollTotalVotes,
      'user_poll_vote_index': userPollVoteIndex,
      'sticker_id': stickerId,
      'video_url': videoUrl,
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
    List<PollOptionData>? pollOptions,
    int? userPollVoteIndex,
    int? pollTotalVotes,
    String? stickerId,
    String? videoUrl,
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
      pollOptions: pollOptions ?? this.pollOptions,
      userPollVoteIndex: userPollVoteIndex ?? this.userPollVoteIndex,
      pollTotalVotes: pollTotalVotes ?? this.pollTotalVotes,
      stickerId: stickerId ?? this.stickerId,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  static MediaType _parseMediaType(String? type) {
    return MediaType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => MediaType.text,
    );
  }
}
