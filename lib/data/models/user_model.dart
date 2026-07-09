/// User Model - represents a user profile
class UserModel {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isAnonymous;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final bool isAdmin;
  final bool canUseVibes;
  final Map<String, dynamic> privacySettings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.isAnonymous = false,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.isAdmin = false,
    this.canUseVibes = false,
    this.privacySettings = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      canUseVibes: json['can_use_vibes'] as bool? ?? false,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'] as String)
          : null,
      privacySettings: json['privacy_settings'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'is_anonymous': isAnonymous,
      'is_premium': isPremium,
      'is_admin': isAdmin,
      'can_use_vibes': canUseVibes,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'privacy_settings': privacySettings,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isAnonymous,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    bool? isAdmin,
    bool? canUseVibes,
    Map<String, dynamic>? privacySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      isAdmin: isAdmin ?? this.isAdmin,
      canUseVibes: canUseVibes ?? this.canUseVibes,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
