// Fix #7: added canUseVibes() method so permission check lives in the
// repository layer instead of directly in the provider.
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';

abstract class IStoryRepository {
  Future<List<StoryModel>> getActiveStories(
      Position location, double radiusMeters);
  Future<void> createStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
    String? textOverlay,
    bool showInZone,
    required Position location,
  });
  Future<void> viewStory(String storyId, String userId);
  Future<List<String>> getViewedStories(String userId);
  // Fix #7: permission check extracted from provider
  Future<bool> canUseVibes(String userId);
}

class SupabaseStoryRepository implements IStoryRepository {
  final SupabaseClient _supabase;

  SupabaseStoryRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  @override
  Future<List<StoryModel>> getActiveStories(
      Position location, double radiusMeters) async {
    final response = await _supabase.rpc('get_nearby_stories', params: {
      'user_lat': location.latitude,
      'user_lon': location.longitude,
      'radius_meters': radiusMeters,
    });
    return (response as List<dynamic>)
        .map((json) => StoryModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> createStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
    String? textOverlay,
    bool showInZone = true,
    required Position location,
  }) async {
    // Upload media
    final ext = mediaFile.path.split('.').last;
    final path = 'stories/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage
        .from('media')
        .upload(path, mediaFile);
    final url = _supabase.storage.from('media').getPublicUrl(path);

    await _supabase.from('stories').insert({
      'user_id': userId,
      'media_url': url,
      'media_type': mediaType,
      'text_overlay': textOverlay,
      'show_in_zone': showInZone,
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
  }

  @override
  Future<void> viewStory(String storyId, String userId) async {
    await _supabase.from('story_views').upsert({
      'story_id': storyId,
      'viewer_id': userId,
      'viewed_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<String>> getViewedStories(String userId) async {
    final response = await _supabase
        .from('story_views')
        .select('story_id')
        .eq('viewer_id', userId);
    return (response as List<dynamic>)
        .map((row) => row['story_id'] as String)
        .toList();
  }

  // Fix #7: permission check — only Supabase call, repository layer only
  @override
  Future<bool> canUseVibes(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select('can_use_vibes, is_admin')
        .eq('id', userId)
        .single();
    return profile['can_use_vibes'] == true || profile['is_admin'] == true;
  }
}

final storyRepositoryProvider = Provider<IStoryRepository>((ref) {
  return SupabaseStoryRepository(supabase: Supabase.instance.client);
});
