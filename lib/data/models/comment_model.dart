class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime? createdAt;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.createdAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
