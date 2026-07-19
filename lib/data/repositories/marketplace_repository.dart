import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marketplace_item_model.dart';
import '../../services/media_upload_service.dart';

abstract class IMarketplaceRepository {
  Future<List<MarketplaceItemModel>> getNearbyItems(
    LatLng location,
    double radiusMeters, {
    String? category,
    int page = 1,
    int pageSize = 20,
  });
  Future<void> createItem({
    required String userId,
    required String title,
    String description = '',
    double? price,
    String currency = 'DZD',
    required String category,
    required List<File> mediaFiles,
    required LatLng location,
  });
  Future<void> markAsSold(String itemId, String userId);
}

class SupabaseMarketplaceRepository implements IMarketplaceRepository {
  final SupabaseClient _supabase;
  final MediaUploadService _mediaUpload;

  SupabaseMarketplaceRepository({
    required SupabaseClient supabase,
    required MediaUploadService mediaUpload,
  })  : _supabase = supabase,
        _mediaUpload = mediaUpload;

  @override
  Future<List<MarketplaceItemModel>> getNearbyItems(
    LatLng location,
    double radiusMeters, {
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _supabase.rpc(
      'get_nearby_marketplace_items',
      params: {
        'user_lat': location.latitude,
        'user_lng': location.longitude,
        'radius_meters': radiusMeters,
        'filter_category': category,
        'page': page,
        'page_size': pageSize,
      },
    );
    return (response as List<dynamic>)
        .map((json) => MarketplaceItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createItem({
    required String userId,
    required String title,
    String description = '',
    double? price,
    String currency = 'DZD',
    required String category,
    required List<File> mediaFiles,
    required LatLng location,
  }) async {
    final urls = await _mediaUpload.uploadPostMedia(
      files: mediaFiles,
      userId: userId,
    );
    await _supabase.from('marketplace_items').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'category': category,
      'images': urls,
      'location': 'POINT(${location.longitude} ${location.latitude})',
    });
  }

  @override
  Future<void> markAsSold(String itemId, String userId) async {
    await _supabase
        .from('marketplace_items')
        .update({'status': 'sold'})
        .eq('id', itemId)
        .eq('user_id', userId);
  }
}

final marketplaceRepositoryProvider = Provider<IMarketplaceRepository>((ref) {
  return SupabaseMarketplaceRepository(
    supabase: Supabase.instance.client,
    mediaUpload: ref.watch(mediaUploadServiceProvider),
  );
});
