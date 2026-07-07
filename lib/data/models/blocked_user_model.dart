class BlockedUserModel {
  final String id;
  final String blockerId;
  final String blockedId;
  final String? reason;
  final DateTime createdAt;

  BlockedUserModel({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    this.reason,
    required this.createdAt,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: json['id'] as String,
      blockerId: json['blocker_id'] as String,
      blockedId: json['blocked_id'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'blocker_id': blockerId,
    'blocked_id': blockedId,
    'reason': reason,
    'created_at': createdAt.toIso8601String(),
  };
}
