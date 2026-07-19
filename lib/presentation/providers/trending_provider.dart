import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../services/location_service.dart';
import '../../core/constants/app_constants.dart';

class TrendingState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  const TrendingState({this.posts = const [], this.isLoading = false, this.error});

  TrendingState copyWith({List<PostModel>? posts, bool? isLoading, String? error}) {
    return TrendingState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TrendingNotifier extends StateNotifier<TrendingState> {
  final LocationService _locationService;
  final IPostRepository _postRepo;

  TrendingNotifier(this._locationService, this._postRepo) : super(const TrendingState());

  Future<void> loadTrending() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final posts = await _postRepo.getTrendingPosts(
        LatLng(pos.latitude, pos.longitude),
        AppConstants.proximityRadiusMeters,
        resultLimit: 20,
      );
      state = TrendingState(posts: posts);
    } catch (e) {
      state = TrendingState(error: e.toString());
    }
  }
}

final trendingProvider = StateNotifierProvider<TrendingNotifier, TrendingState>((ref) {
  return TrendingNotifier(
    ref.watch(locationServiceProvider),
    ref.watch(postRepositoryProvider),
  );
});
