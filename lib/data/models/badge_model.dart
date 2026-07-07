class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String category;
  final int requiredXp;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.category,
    this.requiredXp = 0,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    iconUrl: json['icon_url'] as String?,
    category: json['category'] as String,
    requiredXp: json['required_xp'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon_url': iconUrl,
    'category': category,
    'required_xp': requiredXp,
  };
}

class UserBadgeModel {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final BadgeModel? badge;

  UserBadgeModel({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.badge,
  });

  factory UserBadgeModel.fromJson(Map<String, dynamic> json) => UserBadgeModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    badgeId: json['badge_id'] as String,
    earnedAt: DateTime.parse(json['earned_at'] as String),
    badge: json['badges'] != null
        ? BadgeModel.fromJson(json['badges'] as Map<String, dynamic>)
        : null,
  );
}
