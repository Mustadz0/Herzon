import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_post_model.dart';

abstract class IZoneFeedRepository {
  Future<List<ZonePostModel>> getZonePosts({
    required String zoneKey,
    required double userLat,
    required double userLng,
    int radiusMeters = 500,
    int limit = 30,
  });
}

class SupabaseZoneFeedRepository implements IZoneFeedRepository {
  final SupabaseClient _client;

  const SupabaseZoneFeedRepository(this._client);

  @override
  Future<List<ZonePostModel>> getZonePosts({
    required String zoneKey,
    required double userLat,
    required double userLng,
    int radiusMeters = 500,
    int limit = 30,
  }) async {
    final result = await _client.rpc(
      'get_zone_posts',
      params: {
        'p_zone_key': zoneKey,
        'p_user_lat': userLat,
        'p_user_lng': userLng,
        'p_radius_meters': radiusMeters,
        'p_limit': limit,
      },
    );
    return (result as List)
        .map((e) => ZonePostModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
