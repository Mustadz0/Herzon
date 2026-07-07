// â”€â”€â”€ UserLevelModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Tracks a user's gamification stats (XP, level, activity counters).
/// Parses both `user_levels` table rows and `get_user_gamification` RPC response.
class UserLevelModel {
  final String?    userId;
  final int       xp;
  final int       level;
  final int       nextLevelXp;
  final int       progressPercent;
  final int       totalPosts;
  final int       totalReactionsReceived;
  final int       totalCommentsReceived;
  final int       totalCheckins;
  final DateTime?  updatedAt;

  const UserLevelModel({
    this.userId,
    this.xp = 0,
    this.level = 1,
    this.nextLevelXp = 100,
    this.progressPercent = 0,
    this.totalPosts = 0,
    this.totalReactionsReceived = 0,
    this.totalCommentsReceived = 0,
    this.totalCheckins = 0,
    this.updatedAt,
  });

  factory UserLevelModel.fromJson(Map<String, dynamic> json) {
    final xp = (json['xp'] as num?)?.toInt() ?? 0;
    final level = (json['level'] as num?)?.toInt() ?? 1;
    final nextXp = (json['next_level_xp'] as num?)?.toInt() ?? (level * 100);
    return UserLevelModel(
      userId:                json['user_id'] as String?,
      xp:                    xp,
      level:                 level,
      nextLevelXp:          nextXp,
      progressPercent:      (json['progress_percent'] as num?)?.toInt() ?? (xp % 100),
      totalPosts:           (json['total_posts'] as num?)?.toInt() ?? 0,
      totalReactionsReceived: (json['total_reactions_received'] as num?)?.toInt() ?? 0,
      totalCommentsReceived: (json['total_comments_received'] as num?)?.toInt() ?? 0,
      totalCheckins:        (json['total_checkins'] as num?)?.toInt() ?? 0,
      updatedAt:            json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (userId != null) 'user_id':                     userId,
    'xp':                          xp,
    'level':                       level,
    'next_level_xp':               nextLevelXp,
    'progress_percent':            progressPercent,
    'total_posts':                 totalPosts,
    'total_reactions_received':    totalReactionsReceived,
    'total_comments_received':     totalCommentsReceived,
    if (totalCheckins > 0) 'total_checkins':          totalCheckins,
    if (updatedAt != null) 'updated_at':               updatedAt!.toIso8601String(),
  };
}

// â”€â”€â”€ XpTransactionModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Records an individual XP credit or debit.
class XpTransactionModel {
  final String    id;
  final String    userId;
  final int       amount;
  final String    reason;
  final String?   sourceId;
  final DateTime  createdAt;

  const XpTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    this.sourceId,
    required this.createdAt,
  });

  factory XpTransactionModel.fromJson(Map<String, dynamic> json) => XpTransactionModel(
    id:        json['id']        as String,
    userId:    json['user_id']   as String,
    amount:    json['amount']    as int,
    reason:    json['reason']    as String,
    sourceId:  json['source_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id':         id,
    'user_id':    userId,
    'amount':     amount,
    'reason':     reason,
    'source_id':  sourceId,
    'created_at': createdAt.toIso8601String(),
  };
}

// â”€â”€â”€ LeaderboardEntryModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Represents a single row on a leaderboard.
class LeaderboardEntryModel {
  final String    userId;
  final String    username;
  final String?   displayName;
  final String?   avatarUrl;
  final int       xp;
  final int       level;
  final int       rank;

  const LeaderboardEntryModel({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.xp,
    required this.level,
    required this.rank,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) => LeaderboardEntryModel(
    userId:      json['user_id']    as String,
    username:    json['username']   as String,
    displayName: json['display_name']as String?,
    avatarUrl:   json['avatar_url'] as String?,
    xp:          json['xp']         as int,
    level:       json['level']      as int,
    rank:        json['rank']       as int,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user_id':      userId,
    'username':     username,
    'display_name': displayName,
    'avatar_url':   avatarUrl,
    'xp':           xp,
    'level':        level,
    'rank':         rank,
  };
}
