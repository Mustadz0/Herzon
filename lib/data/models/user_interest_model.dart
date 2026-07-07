// â”€â”€â”€ UserInterestModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Stores a user's weighted interest in a tag/topic.
class UserInterestModel {
  final String    userId;
  final String    tag;
  final double    weight;
  final DateTime  lastInteraction;

  const UserInterestModel({
    required this.userId,
    required this.tag,
    this.weight = 0.0,
    required this.lastInteraction,
  });

  factory UserInterestModel.fromJson(Map<String, dynamic> json) => UserInterestModel(
    userId:          json['user_id']          as String,
    tag:             json['tag']              as String,
    weight:          (json['weight'] as num?)?.toDouble() ?? 0.0,
    lastInteraction: DateTime.parse(json['last_interaction'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user_id':           userId,
    'tag':               tag,
    'weight':            weight,
    'last_interaction':  lastInteraction.toIso8601String(),
  };
}
