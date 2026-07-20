// Fix #7: removed direct Supabase call from provider — moved permission
// check to StoryRepository via new canUseVibes() method.
// The provider now talks only through IStoryRepository.
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/firebase_uuid.dart';
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

  StoryNotifier(this._repo, this._locationService)
      : super(const StoriesState());

  Future<void> loadStories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final stories = await _repo.getActiveStories(
          pos, AppConstants.proximityRadiusMeters);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      List<String> viewedIds = [];
      if (firebaseUser != null) {
        final userId = FirebaseUuid.toUuid(firebaseUser.uid);
        viewedIds = await _repo.getViewedStories(userId);
      }
      if (mounted) state = StoriesState(stories: stories, viewedStoryIds: viewedIds);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createStory({
    required File mediaFile,
    required String mediaType,
    String? textOverlay,
    bool showInZone = true,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw Exception('Not authenticated');
    final userId = FirebaseUuid.toUuid(firebaseUser.uid);
    final pos = await _locationService.initializeLocation();

    // Fix #7: permission check now lives in the repository
    final canUse = await _repo.canUseVibes(userId);
    if (!canUse) {
      throw Exception(
          'Vous n\'etes pas autorisé à utiliser les Vibes. Contactez l\'administrateur.');
    }

    await _repo.createStory(
      userId: userId,
      mediaFile: mediaFile,
      mediaType: mediaType,
      textOverlay: textOverlay,
      showInZone: showInZone,
      location: pos,
    );
    await loadStories();
  }

  Future<void> viewStory(String storyId) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final userId = FirebaseUuid.toUuid(firebaseUser.uid);
    try {
      await _repo.viewStory(storyId, userId);
      if (mounted && !state.viewedStoryIds.contains(storyId)) {
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

final storyProvider =
    StateNotifierProvider<StoryNotifier, StoriesState>((ref) {
  return StoryNotifier(
    ref.watch(storyRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
