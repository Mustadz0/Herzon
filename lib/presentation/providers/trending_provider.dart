// Fix: TrendingNotifier استدعى Supabase مباشرة —
// الآن مُنقول إلى repository منفصل.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';
import '../../services/location_service.dart';
import '../../core/constants/app_constants.dart';

// ── Repository ────────────────────────────────────────────────────────────
abstract class ITrendingRepository {
  Future<List<Map<String, dynamic>>> getTrendingPosts({
    required double lat,
    required double lng,
    required double radiusMeters,
    int limit,
  });
}

class SupabaseTrendingRepository implements ITrendingRepository {
  final SupabaseClient _supabase;
  SupabaseTrendingRepository(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getTrendingPosts({
    required double lat,
    required double lng,
    required double radiusMeters,
    int limit = 20,
  }) async {
    final response = await _supabase.rpc(
      'get_trending_posts',
      params: {
        'user_lat': lat,
        'user_lng': lng,
        'radius_meters': radiusMeters,
        'result_limit': limit,
      },
    );
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }
}

final trendingRepositoryProvider = Provider<ITrendingRepository>((ref) {
  return SupabaseTrendingRepository(Supabase.instance.client);
});

// ── State ─────────────────────────────────────────────────────────────────
class TrendingState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  const TrendingState(
      {this.posts = const [], this.isLoading = false, this.error});

  TrendingState copyWith(
      {List<PostModel>? posts, bool? isLoading, String? error}) {
    return TrendingState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────
class TrendingNotifier extends StateNotifier<TrendingState> {
  final ITrendingRepository _repo;
  final LocationService _locationService;

  TrendingNotifier(this._repo, this._locationService)
      : super(const TrendingState());

  Future<void> loadTrending() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final raw = await _repo.getTrendingPosts(
        lat: pos.latitude,
        lng: pos.longitude,
        radiusMeters: AppConstants.proximityRadiusMeters,
      );
      final posts = raw.map((json) => PostModel(
            id: json['id'] as String,
            userId: json['user_id'] as String,
            content: json['content'] as String? ?? '',
            mediaUrls: List<String>.from(json['media_urls'] ?? []),
            mediaType: _parseMediaType(json['media_type'] as String?),
            latitude: pos.latitude,
            longitude: pos.longitude,
            contextTag: json['context_tag'] as String?,
            reactionCounts:
                Map<String, int>.from(json['reaction_counts'] ?? {}),
            createdAt: json['created_at'] != null
                ? DateTime.parse(json['created_at'] as String)
                : null,
            userUsername: json['username'] as String?,
            userDisplayName: json['display_name'] as String?,
            userAvatarUrl: json['avatar_url'] as String?,
            distanceMeters:
                (json['distance'] as num?)?.toDouble() ?? 0.0,
            commentCount:
                (json['comment_count'] as num?)?.toInt() ?? 0,
          ))
          .toList();
      if (mounted) state = TrendingState(posts: posts);
    } catch (e) {
      if (mounted) state = TrendingState(error: e.toString());
    }
  }

  MediaType _parseMediaType(String? type) {
    return MediaType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => MediaType.text,
    );
  }
}

final trendingProvider =
    StateNotifierProvider<TrendingNotifier, TrendingState>((ref) {
  return TrendingNotifier(
    ref.watch(trendingRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
