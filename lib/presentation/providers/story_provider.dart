import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/story_model.dart';
import '../../data/repositories/story_repository.dart';
import '../../services/location_service.dart';
import '../../core/constants/app_constants.dart';

class StoriesState {
  final List<StoryModel> stories;
  final bool isLoading;
  final String? error;
  final List<String> viewedStoryIds;

  const StoriesState({
    this.stories = const [],
    this.isLoading = false,
    this.error,
    this.viewedStoryIds = const [],
  });

  StoriesState copyWith({
    List<StoryModel>? stories,
    bool? isLoading,
    String? error,
    List<String>? viewedStoryIds,
  }) {
    return StoriesState(
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      viewedStoryIds: viewedStoryIds ?? this.viewedStoryIds,
    );
  }
}

class StoryNotifier extends StateNotifier<StoriesState> {
  final IStoryRepository _repo;
  final LocationService _locationService;

  StoryNotifier(this._repo, this._locationService) : super(const StoriesState());

  Future<void> loadStories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final stories = await _repo.getActiveStories(pos, AppConstants.proximityRadiusMeters);
      final user = Supabase.instance.client.auth.currentUser;
      List<String> viewedIds = [];
      if (user != null) {
        viewedIds = await _repo.getViewedStories(user.id);
      }
      state = StoriesState(stories: stories, viewedStoryIds: viewedIds);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createStory({
    required File mediaFile,
    required String mediaType,
    String? textOverlay,
  }) async {
    final pos = await _locationService.initializeLocation();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _repo.createStory(
      userId: user.id,
      mediaFile: mediaFile,
      mediaType: mediaType,
      textOverlay: textOverlay,
      location: pos,
    );
    await loadStories();
  }

  Future<void> viewStory(String storyId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await _repo.viewStory(storyId, user.id);
      if (!state.viewedStoryIds.contains(storyId)) {
        state = state.copyWith(
          viewedStoryIds: [...state.viewedStoryIds, storyId],
        );
      }
    } catch (_) {}
  }

  List<StoryModel> getUnviewedStories() {
    return state.stories
        .where((s) => !state.viewedStoryIds.contains(s.id))
        .toList();
  }
}

final storyProvider = StateNotifierProvider<StoryNotifier, StoriesState>((ref) {
  return StoryNotifier(
    ref.watch(storyRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
