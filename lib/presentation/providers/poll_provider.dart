import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/poll_repository.dart';

class PollResult {
  final String label;
  final int votes;
  final double percentage;

  const PollResult({
    required this.label,
    required this.votes,
    required this.percentage,
  });
}

class PollState {
  final bool hasVoted;
  final int? selectedOption;
  final bool isLoading;
  final List<PollResult> results;
  final String? error;

  const PollState({
    this.hasVoted = false,
    this.selectedOption,
    this.isLoading = false,
    this.results = const [],
    this.error,
  });

  PollState copyWith({
    bool? hasVoted,
    int? selectedOption,
    bool? isLoading,
    List<PollResult>? results,
    String? error,
  }) {
    return PollState(
      hasVoted: hasVoted ?? this.hasVoted,
      selectedOption: selectedOption ?? this.selectedOption,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error ?? this.error,
    );
  }
}

class PollNotifier extends StateNotifier<PollState> {
  final IPollRepository _repo;

  PollNotifier(this._repo) : super(const PollState()) {
    _init();
  }

  Future<void> _init() async {}

  Future<void> vote(String postId, int optionIndex) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.votePoll(postId, optionIndex);
      state = state.copyWith(
        hasVoted: true,
        selectedOption: optionIndex,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadResults(String postId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getPollResults(postId);
      final resultsList = (data['options'] as List<dynamic>? ?? []).map((e) {
        final map = e as Map<String, dynamic>;
        return PollResult(
          label: map['label'] as String? ?? '',
          votes: map['votes'] as int? ?? 0,
          percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
      state = state.copyWith(
        results: resultsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final pollProvider = StateNotifierProvider<PollNotifier, PollState>((ref) {
  return PollNotifier(ref.watch(pollRepositoryProvider));
});
