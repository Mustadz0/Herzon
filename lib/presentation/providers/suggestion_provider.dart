import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/suggestion_repository.dart';
import '../../services/location_service.dart';

class SuggestionState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  const SuggestionState({this.posts = const [], this.isLoading = false, this.error});

  SuggestionState copyWith({List<PostModel>? posts, bool? isLoading, String? error}) {
    return SuggestionState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SuggestionNotifier extends StateNotifier<SuggestionState> {
  final ISuggestionRepository _repo;
  final LocationService _locationService;

  SuggestionNotifier(this._repo, this._locationService) : super(const SuggestionState()) {
    _init();
  }

  Future<void> _init() async {}

  Future<void> loadSuggestions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final data = await _repo.getSuggestedPosts(pos.latitude, pos.longitude);
      final posts = data
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = SuggestionState(posts: posts);
    } catch (e) {
      state = SuggestionState(error: e.toString());
    }
  }
}

final suggestionProvider = StateNotifierProvider<SuggestionNotifier, SuggestionState>((ref) {
  return SuggestionNotifier(
    ref.watch(suggestionRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
