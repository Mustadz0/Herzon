// Fix: _init() كان فارغاً — الآن يُحمّل الصفحات القريبة تلقائياً.
// Fix: الإحداثيات الافتراضية المُضمّنة (36.75, 3.05) مُبقاة كـ fallback فقط.
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../data/models/page_model.dart';
import '../../data/repositories/page_repository.dart';
import '../../services/location_service.dart';

class PageState {
  final List<PageModel> pages;
  final List<PostModel>? pagePosts;
  final bool isLoading;
  final String? error;

  const PageState({
    this.pages = const [],
    this.pagePosts,
    this.isLoading = false,
    this.error,
  });

  PageState copyWith({
    List<PageModel>? pages,
    List<PostModel>? pagePosts,
    bool? isLoading,
    String? error,
  }) {
    return PageState(
      pages: pages ?? this.pages,
      pagePosts: pagePosts ?? this.pagePosts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PageNotifier extends StateNotifier<PageState> {
  final IPageRepository _repo;
  final LocationService _locationService;

  PageNotifier(this._repo, this._locationService) : super(const PageState()) {
    _init();
  }

  // Fix: auto-load on creation
  Future<void> _init() async {
    await loadNearbyPages();
  }

  Future<void> loadNearbyPages({String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      double lat = 36.7538;
      double lng = 3.0588;
      try {
        final pos = await _locationService.initializeLocation();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (e) {
        dev.log('Location failed, using defaults: \$e', name: 'PageProvider');
      }
      final data = await _repo.getNearbyPages(lat, lng, category: category);
      dev.log('RPC returned \${data.length} pages', name: 'PageProvider');
      final items = data.map((e) {
        try {
          return PageModel.fromJson(e);
        } catch (e2) {
          dev.log('Failed to parse page: \$e2\ndata=\$e', name: 'PageProvider');
          rethrow;
        }
      }).toList();
      if (mounted) state = state.copyWith(pages: items, isLoading: false);
    } catch (e, st) {
      dev.log('loadNearbyPages error: \$e',
          name: 'PageProvider', error: e, stackTrace: st);
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createPage({
    required String name,
    required String slug,
    required String category,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.createPage(
        name: name,
        slug: slug,
        category: category,
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      await loadNearbyPages();
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getPagePosts(String pageId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getPagePosts(pageId);
      final posts = data.map((e) => PostModel.fromJson(e)).toList();
      if (mounted) state = state.copyWith(pagePosts: posts, isLoading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final pageProvider =
    StateNotifierProvider<PageNotifier, PageState>((ref) {
  return PageNotifier(
    ref.watch(pageRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
