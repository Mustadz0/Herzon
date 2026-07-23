abstract class PollOption {
  String get text;
  int get votes;
  double get percentage;
}

class PollModel {
  final List<PollOptionItem> options;
  final int totalVotes;
  final int? userVoteIndex;

  PollModel({
    required this.options,
    required this.totalVotes,
    this.userVoteIndex,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final optionsList = (json['options'] as List<dynamic>?) ?? [];
    return PollModel(
      options: optionsList
          .map((e) => PollOptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
      userVoteIndex: (json['user_vote_index'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'options': options.map((e) => e.toJson()).toList(),
        'total_votes': totalVotes,
        'user_vote_index': userVoteIndex,
      };

  bool get hasVoted => userVoteIndex != null;
}

class PollOptionItem implements PollOption {
  @override
  final String text;
  @override
  final int votes;
  @override
  final double percentage;

  PollOptionItem({
    required this.text,
    this.votes = 0,
    this.percentage = 0.0,
  });

  factory PollOptionItem.fromJson(Map<String, dynamic> json) {
    return PollOptionItem(
      text: json['text'] as String? ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'votes': votes,
        'percentage': percentage,
      };
}
