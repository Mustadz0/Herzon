import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_model.dart';

abstract class IZoneRepository {
  Future<List<ZoneModel>> getNearbyZones({
    required double userLat,
    required double userLng,
    int radiusMeters = 500,
  });

  Future<List<ZoneModel>> searchZonesByName(String query);
}

class SupabaseZoneRepository implements IZoneRepository {
  final SupabaseClient _client;

  const SupabaseZoneRepository(this._client);

  @override
  Future<List<ZoneModel>> getNearbyZones({
    required double userLat,
    required double userLng,
    int radiusMeters = 500,
  }) async {
    final result = await _client.rpc(
      'get_nearby_zones',
      params: {
        'p_user_lat': userLat,
        'p_user_lng': userLng,
        'p_radius_meters': radiusMeters,
      },
    );

    return (result as List)
        .map((e) => ZoneModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Full-text search on zone_name — returns up to 20 results globally.
  @override
  Future<List<ZoneModel>> searchZonesByName(String query) async {
    final result = await _client
        .from('zones')
        .select(
          'id, zone_key, zone_name, center_lat, center_lng, '
          'heat_score, active_users, recent_posts, '
          'recent_vibes, recent_checkins, dominant_activity, updated_at',
        )
        .ilike('zone_name', '%$query%')
        .order('heat_score', ascending: false)
        .limit(20);

    return (result as List)
        .map((e) => ZoneModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
