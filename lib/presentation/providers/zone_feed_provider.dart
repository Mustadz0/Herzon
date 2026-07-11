import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/zone_model.dart';
import '../../data/models/zone_post_model.dart';
import '../../data/repositories/zone_feed_repository.dart';

// ── Repository provider ────────────────────────────────────────────────────
final zoneFeedRepositoryProvider = Provider<IZoneFeedRepository>((ref) {
  return SupabaseZoneFeedRepository(Supabase.instance.client);
});

// ── State ──────────────────────────────────────────────────────────────────
class ZoneFeedState {
  final bool isLoading;
  final List<ZonePostModel> posts;
  final String? error;

  const ZoneFeedState({
    this.isLoading = false,
    this.posts = const [],
    this.error,
  });

  ZoneFeedState copyWith({
    bool? isLoading,
    List<ZonePostModel>? posts,
    String? error,
  }) =>
      ZoneFeedState(
        isLoading: isLoading ?? this.isLoading,
        posts: posts ?? this.posts,
        error: error,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────
class ZoneFeedNotifier extends StateNotifier<ZoneFeedState> {
  final IZoneFeedRepository _repository;

  ZoneFeedNotifier(this._repository) : super(const ZoneFeedState());

  Future<void> load({
    required String zoneKey,
    required double lat,
    required double lng,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _repository.getZonePosts(
        zoneKey: zoneKey,
        userLat: lat,
        userLng: lng,
      );
      state = state.copyWith(isLoading: false, posts: posts);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les posts de cette zone.',
      );
    }
  }

  void clear() => state = const ZoneFeedState();
}

// ── Provider (family: one instance per zone) ───────────────────────────────
final zoneFeedProvider =
    StateNotifierProvider.family<ZoneFeedNotifier, ZoneFeedState, String>(
  (ref, zoneKey) => ZoneFeedNotifier(ref.read(zoneFeedRepositoryProvider)),
);
