import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_post_model.dart';

abstract class IZoneFeedRepository {
  /// Fetch posts for a zone by its UUID [zoneId].
  Future<List<ZonePostModel>> getZonePosts({
    required String zoneId,
    int page = 1,
    int pageSize = 20,
  });
}

class SupabaseZoneFeedRepository implements IZoneFeedRepository {
  final SupabaseClient _client;

  const SupabaseZoneFeedRepository(this._client);

  @override
  Future<List<ZonePostModel>> getZonePosts({
    required String zoneId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _client.rpc(
      'get_zone_posts',
      params: {
        'p_zone_id': zoneId,
        'page': page,
        'page_size': pageSize,
      },
    );
    return (result as List)
        .map((e) =>
            ZonePostModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

final zoneFeedRepositoryProvider = Provider<IZoneFeedRepository>((ref) {
  return SupabaseZoneFeedRepository(Supabase.instance.client);
});
