import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_model.dart';

abstract class IZoneRepository {
  Future<List<ZoneModel>> getNearbyZones({
    required double userLat,
    required double userLng,
    int radiusMeters = 500,
  });
}

class SupabaseZoneRepository implements IZoneRepository {
  final SupabaseClient _client;

  SupabaseZoneRepository(this._client);

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
}
