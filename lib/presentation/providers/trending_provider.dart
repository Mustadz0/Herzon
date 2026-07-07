import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';
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

  TrendingNotifier(this._locationService) : super(const TrendingState());

  Future<void> loadTrending() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final response = await Supabase.instance.client.rpc(
        'get_trending_posts',
        params: {
          'user_lat': pos.latitude,
          'user_lng': pos.longitude,
          'radius_meters': AppConstants.proximityRadiusMeters,
          'result_limit': 20,
        },
      );
      final posts = (response as List<dynamic>).map((json) => PostModel(
        id: json['id'],
        userId: json['user_id'],
        content: json['content'],
        mediaUrls: List<String>.from(json['media_urls'] ?? []),
        mediaType: _parseMediaType(json['media_type']),
        latitude: pos.latitude,
        longitude: pos.longitude,
        contextTag: json['context_tag'],
        reactionCounts: Map<String, int>.from(json['reaction_counts'] ?? {}),
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        userUsername: json['username'],
        userDisplayName: json['display_name'],
        userAvatarUrl: json['avatar_url'],
        distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
        commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      )).toList();
      state = TrendingState(posts: posts);
    } catch (e) {
      state = TrendingState(error: e.toString());
    }
  }

  MediaType _parseMediaType(String? type) {
    return MediaType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => MediaType.text,
    );
  }
}

final trendingProvider = StateNotifierProvider<TrendingNotifier, TrendingState>((ref) {
  return TrendingNotifier(ref.watch(locationServiceProvider));
});
