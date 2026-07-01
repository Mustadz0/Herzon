import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/story_model.dart';
import '../../services/media_upload_service.dart';

abstract class IStoryRepository {
  Future<List<StoryModel>> getActiveStories(LatLng location, double radiusMeters);
  Future<StoryModel> createStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
    String? textOverlay,
    required LatLng location,
  });
  Future<void> viewStory(String storyId, String userId);
  Future<List<String>> getViewedStories(String userId);
}

class SupabaseStoryRepository implements IStoryRepository {
  final SupabaseClient _supabase;
  final MediaUploadService _mediaUpload;

  SupabaseStoryRepository({
    required SupabaseClient supabase,
    required MediaUploadService mediaUpload,
  })  : _supabase = supabase,
        _mediaUpload = mediaUpload;

  @override
  Future<List<StoryModel>> getActiveStories(LatLng location, double radiusMeters) async {
    final response = await _supabase.rpc(
      'get_active_stories',
      params: {
        'user_lat': location.latitude,
        'user_lng': location.longitude,
        'radius_meters': radiusMeters,
      },
    );
    return (response as List<dynamic>)
        .map((json) => StoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StoryModel> createStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
    String? textOverlay,
    required LatLng location,
  }) async {
    final urls = await _mediaUpload.uploadPostMedia(files: [mediaFile], userId: userId);
    if (urls.isEmpty) throw Exception('Failed to upload media');
    final response = await _supabase.from('stories').insert({
      'user_id': userId,
      'media_url': urls.first,
      'media_type': mediaType,
      'text_overlay': textOverlay,
      'location': 'POINT(${location.longitude} ${location.latitude})',
    }).select().single();
    return StoryModel.fromJson(response);
  }

  @override
  Future<void> viewStory(String storyId, String userId) async {
    await _supabase.from('story_views').upsert({
      'story_id': storyId,
      'user_id': userId,
    });
  }

  @override
  Future<List<String>> getViewedStories(String userId) async {
    final data = await _supabase
        .from('story_views')
        .select('story_id')
        .eq('user_id', userId);
    return data.map((json) => json['story_id'] as String).toList();
  }
}

final storyRepositoryProvider = Provider<IStoryRepository>((ref) {
  return SupabaseStoryRepository(
    supabase: Supabase.instance.client,
    mediaUpload: ref.watch(mediaUploadServiceProvider),
  );
});
