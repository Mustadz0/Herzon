import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/firebase_uuid.dart';

abstract class IFeatureFlagRepository {
  /// Get all enabled feature flags
  Future<Map<String, dynamic>> getFeatureFlags();

  /// Get experiments assigned to the current user
  Future<List<Map<String, dynamic>>> getUserExperiments();

  /// Assign an experiment to the current user
  Future<void> assignExperiment(String experimentId);
}

class SupabaseFeatureFlagRepository implements IFeatureFlagRepository {
  final SupabaseClient _supabase;

  SupabaseFeatureFlagRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<Map<String, dynamic>> getFeatureFlags() async {
    final data = await _supabase.from('feature_flags').select('key, value');
    return {
      for (final row in (data as List<dynamic>)) row['key'] as String: row['value']
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getUserExperiments() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('User not authenticated');
    final userId = FirebaseUuid.toUuid(fbUser.uid);

    return await _supabase
        .from('user_experiments')
        .select('*, experiments(*)')
        .eq('user_id', userId);
  }

  @override
  Future<void> assignExperiment(String experimentId) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('User not authenticated');
    final userId = FirebaseUuid.toUuid(fbUser.uid);

    await _supabase.from('user_experiments').insert({
      'user_id': userId,
      'experiment_id': experimentId,
    });
  }
}

final featureFlagRepositoryProvider = Provider<IFeatureFlagRepository>((ref) {
  return SupabaseFeatureFlagRepository(supabase: Supabase.instance.client);
});
