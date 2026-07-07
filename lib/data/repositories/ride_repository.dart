import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IRideRepository {
  /// Get nearby available rides
  Future<List<Map<String, dynamic>>> getNearbyRides(double userLat, double userLng, {double radiusMeters = 5000});

  /// Create a new ride offer
  Future<Map<String, dynamic>> createRide(Map<String, dynamic> params);

  /// Book seats on a ride
  Future<void> bookRide(String rideId, int seats);

  /// Get details of a ride
  Future<Map<String, dynamic>> getRide(String rideId);
}

class SupabaseRideRepository implements IRideRepository {
  final SupabaseClient _supabase;

  SupabaseRideRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<List<Map<String, dynamic>>> getNearbyRides(double userLat, double userLng, {double radiusMeters = 5000}) async {
    final response = await _supabase.rpc('get_nearby_rides', params: {
      'user_lat': userLat,
      'user_lng': userLng,
      'radius_meters': radiusMeters,
    });

    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> createRide(Map<String, dynamic> params) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.from('rides').insert({
      'driver_id': userId,
      ...params,
    }).select().single();

    return response;
  }

  @override
  Future<void> bookRide(String rideId, int seats) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.rpc('book_ride', params: {
      'ride_id': rideId,
      'passenger_id': userId,
      'seats': seats,
    });
  }

  @override
  Future<Map<String, dynamic>> getRide(String rideId) async {
    final response = await _supabase
        .from('rides')
        .select('*, driver:profiles!driver_id(username, display_name, avatar_url)')
        .eq('id', rideId)
        .single();

    return response;
  }
}

final rideRepositoryProvider = Provider<IRideRepository>((ref) {
  return SupabaseRideRepository(supabase: Supabase.instance.client);
});
