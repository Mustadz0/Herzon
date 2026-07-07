class CheckinModel {
  final String id;
  final String userId;
  final String placeName;
  final double? placeLat;
  final double? placeLng;
  final int checkinCount;
  final DateTime lastCheckinAt;
  final DateTime createdAt;

  CheckinModel({
    required this.id,
    required this.userId,
    required this.placeName,
    this.placeLat,
    this.placeLng,
    required this.checkinCount,
    required this.lastCheckinAt,
    required this.createdAt,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) => CheckinModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    placeName: json['place_name'] as String,
    placeLat: (json['place_lat'] as num?)?.toDouble(),
    placeLng: (json['place_lng'] as num?)?.toDouble(),
    checkinCount: json['checkin_count'] as int? ?? 1,
    lastCheckinAt: DateTime.parse(json['last_checkin_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
