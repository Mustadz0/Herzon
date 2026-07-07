import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ISuggestionRepository {
  Future<List<Map<String, dynamic>>> getSuggestedPosts(
    double userLat, double userLng,
    {double radiusMeters = 2000, int limit = 20});
}

class SupabaseSuggestionRepository implements ISuggestionRepository {
  final SupabaseClient _supabase;

  SupabaseSuggestionRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<List<Map<String, dynamic>>> getSuggestedPosts(
    double userLat, double userLng,
    {double radiusMeters = 2000, int limit = 20}) async {
    final response = await _supabase.rpc('get_suggested_posts', params: {
      'p_user_lat': userLat,
      'p_user_lng': userLng,
      'p_radius_meters': radiusMeters,
      'p_limit': limit,
    });
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }
}

final suggestionRepositoryProvider = Provider<ISuggestionRepository>((ref) {
  return SupabaseSuggestionRepository(supabase: Supabase.instance.client);
});
