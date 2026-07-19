import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/story_model.dart';
import '../../data/repositories/story_repository.dart';
import '../../services/location_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/firebase_uuid.dart';

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
      final fbUser = FirebaseAuth.instance.currentUser;
      List<String> viewedIds = [];
      if (fbUser != null) {
        viewedIds = await _repo.getViewedStories(FirebaseUuid.toUuid(fbUser.uid));
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
    bool showInZone = true,
  }) async {
    final pos = await _locationService.initializeLocation();
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('Not authenticated');
    final uid = FirebaseUuid.toUuid(fbUser.uid);

    // Check if user has permission to use vibes
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('can_use_vibes, is_admin')
        .eq('id', uid)
        .single();
    if (profile['can_use_vibes'] != true && profile['is_admin'] != true) {
      throw Exception('Vous n\'etes pas autorise a utiliser les Vibes. Contactez l\'administrateur.');
    }

    await _repo.createStory(
      userId: uid,
      mediaFile: mediaFile,
      mediaType: mediaType,
      textOverlay: textOverlay,
      showInZone: showInZone,
      location: pos,
    );
    await loadStories();
  }

  Future<void> viewStory(String storyId) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;
    try {
      await _repo.viewStory(storyId, FirebaseUuid.toUuid(fbUser.uid));
      if (!state.viewedStoryIds.contains(storyId)) {
        state = state.copyWith(
          viewedStoryIds: [...state.viewedStoryIds, storyId],
        );
      }
    } catch (e) { debugPrint('StoryProvider.viewStory: $e'); }
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
