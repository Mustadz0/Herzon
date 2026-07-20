// Fix: _init() كان فارغاً — الآن يُحمّل الاقتراحات تلقائياً عند إنشاء الـ provider.
// Fix: mounted مضاف قبل كل تعديل للـ state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/suggestion_repository.dart';
import '../../services/location_service.dart';

class SuggestionState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  const SuggestionState(
      {this.posts = const [], this.isLoading = false, this.error});

  SuggestionState copyWith(
      {List<PostModel>? posts, bool? isLoading, String? error}) {
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

  SuggestionNotifier(this._repo, this._locationService)
      : super(const SuggestionState()) {
    _init();
  }

  // Fix: auto-load suggestions on creation
  Future<void> _init() async {
    await loadSuggestions();
  }

  Future<void> loadSuggestions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final data =
          await _repo.getSuggestedPosts(pos.latitude, pos.longitude);
      final posts = data
          .map((e) => PostModel(
                id: e['id'] as String,
                userId: e['user_id'] as String,
                content: e['content'] as String? ?? '',
                mediaUrls:
                    (e['media_urls'] as List<dynamic>?)?.cast<String>() ?? [],
                mediaType: MediaType.text,
                latitude: (e['latitude'] as num?)?.toDouble() ?? 0,
                longitude: (e['longitude'] as num?)?.toDouble() ?? 0,
                contextTag: e['context_tag'] as String?,
                reactionCounts: e['reaction_counts'] != null
                    ? Map<String, int>.from(e['reaction_counts'] as Map)
                    : {},
                createdAt: e['created_at'] != null
                    ? DateTime.parse(e['created_at'] as String)
                    : null,
                userUsername: e['username'] as String?,
                userDisplayName: e['display_name'] as String?,
                userAvatarUrl: e['avatar_url'] as String?,
                distanceMeters:
                    (e['distance_meters'] as num?)?.toDouble() ?? 0,
                commentCount: (e['comment_count'] as num?)?.toInt() ?? 0,
              ))
          .toList();
      if (mounted) state = SuggestionState(posts: posts);
    } catch (e) {
      if (mounted) state = SuggestionState(error: e.toString());
    }
  }
}

final suggestionProvider =
    StateNotifierProvider<SuggestionNotifier, SuggestionState>((ref) {
  return SuggestionNotifier(
    ref.watch(suggestionRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
