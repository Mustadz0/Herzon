// Fix: pollProvider family لا يُمرّر postId للـ Notifier — النتيجة:
// loadResults(postId) يجب استدعاؤه يدوياً ولا يعرف الـ notifier أي poll يخصّه.
// الإصلاح: تحويله لـ .family يُمرّر postId للـ notifier ويُحمّل النتائج تلقائياً.
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
  final String postId; // Fix: postId الآن جزء من الـ notifier

  PollNotifier(this._repo, this.postId) : super(const PollState()) {
    loadResults(); // Fix: auto-load
  }

  Future<void> vote(int optionIndex) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.votePoll(postId, optionIndex);
      state = state.copyWith(
        hasVoted: true,
        selectedOption: optionIndex,
        isLoading: false,
      );
      await loadResults(); // Refresh after vote
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadResults() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getPollResults(postId);
      final resultsList =
          (data['options'] as List<dynamic>? ?? []).map((e) {
        final map = e as Map<String, dynamic>;
        return PollResult(
          label: map['label'] as String? ?? '',
          votes: map['votes'] as int? ?? 0,
          percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
      if (mounted) {
        state = state.copyWith(results: resultsList, isLoading: false);
      }
    } catch (e) {
      if (mounted)
        state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Fix: postId مُمرَّر للـ Notifier
final pollProvider =
    StateNotifierProvider.family<PollNotifier, PollState, String>(
  (ref, postId) {
    return PollNotifier(ref.watch(pollRepositoryProvider), postId);
  },
);
