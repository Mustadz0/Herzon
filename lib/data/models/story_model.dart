class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType;
  final String? textOverlay;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.textOverlay,
    this.createdAt,
    this.expiresAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      textOverlay: json['text_overlay'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'text_overlay': textOverlay,
    };
  }
}
