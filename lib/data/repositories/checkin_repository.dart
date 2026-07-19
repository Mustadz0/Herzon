import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/firebase_uuid.dart';

abstract class ICheckinRepository {
  /// Check in at a place
  Future<Map<String, dynamic>> checkinPlace(
      String placeName, double placeLat, double placeLng);

  /// Get check-in history for the current user
  Future<List<Map<String, dynamic>>> getUserCheckins();

  /// Get gamification badges earned by the current user
  Future<List<Map<String, dynamic>>> getUserBadges();
}

class SupabaseCheckinRepository implements ICheckinRepository {
  final SupabaseClient _supabase;

  SupabaseCheckinRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  /// Returns the current user's UUID v5 (converted from Firebase UID).
  String _currentUuid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseUuid.toUuid(uid);
  }

  @override
  Future<Map<String, dynamic>> checkinPlace(
      String placeName, double placeLat, double placeLng) async {
    final uuid = _currentUuid();
    final response = await _supabase.rpc('checkin_place', params: {
      'user_id': uuid,
      'place_name': placeName,
      'place_lat': placeLat,
      'place_lng': placeLng,
    });
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getUserCheckins() async {
    final uuid = _currentUuid();
    return await _supabase
        .from('checkins')
        .select()
        .eq('user_id', uuid)
        .order('created_at', ascending: false);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserBadges() async {
    final uuid = _currentUuid();
    return await _supabase
        .from('user_badges')
        .select('*, badges(*)')
        .eq('user_id', uuid)
        .order('awarded_at', ascending: false);
  }
}

final checkinRepositoryProvider = Provider<ICheckinRepository>((ref) {
  return SupabaseCheckinRepository(supabase: Supabase.instance.client);
});
