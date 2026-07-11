class ZoneModel {
  final String id;
  final String zoneKey;
  final String zoneName;
  final double centerLat;
  final double centerLng;
  final int heatScore;
  final int activeUsers;
  final int recentPosts;
  final int recentVibes;
  final int recentCheckins;
  final String? dominantActivity;
  final DateTime? updatedAt;

  const ZoneModel({
    required this.id,
    required this.zoneKey,
    required this.zoneName,
    required this.centerLat,
    required this.centerLng,
    required this.heatScore,
    required this.activeUsers,
    required this.recentPosts,
    required this.recentVibes,
    required this.recentCheckins,
    this.dominantActivity,
    this.updatedAt,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] as String,
      zoneKey: json['zone_key'] as String,
      zoneName: json['zone_name'] as String,
      centerLat: (json['center_lat'] as num).toDouble(),
      centerLng: (json['center_lng'] as num).toDouble(),
      heatScore: (json['heat_score'] as num?)?.toInt() ?? 0,
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
      recentPosts: (json['recent_posts'] as num?)?.toInt() ?? 0,
      recentVibes: (json['recent_vibes'] as num?)?.toInt() ?? 0,
      recentCheckins: (json['recent_checkins'] as num?)?.toInt() ?? 0,
      dominantActivity: json['dominant_activity'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'zone_key': zoneKey,
        'zone_name': zoneName,
        'center_lat': centerLat,
        'center_lng': centerLng,
        'heat_score': heatScore,
        'active_users': activeUsers,
        'recent_posts': recentPosts,
        'recent_vibes': recentVibes,
        'recent_checkins': recentCheckins,
        'dominant_activity': dominantActivity,
        'updated_at': updatedAt?.toIso8601String(),
      };

  // Heat level helpers
  bool get isCalm    => heatScore < 10;
  bool get isActive  => heatScore >= 10 && heatScore < 25;
  bool get isHot     => heatScore >= 25 && heatScore < 45;
  bool get isOnFire  => heatScore >= 45;

  String get heatLabel {
    if (isOnFire)  return 'Très active';
    if (isHot)     return 'Active';
    if (isActive)  return 'Calme+';
    return 'Calme';
  }

  String get emoji {
    if (isOnFire) return '\uD83D\uDD25'; // 🔥
    if (isHot)    return '\u26A1';       // ⚡
    if (isActive) return '\u2728';       // ✨
    return '\u2022';                     // •
  }

  double get markerSize {
    if (isOnFire)  return 56;
    if (isHot)     return 48;
    if (isActive)  return 40;
    return 28;
  }
}
