import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IPageRepository {
  /// Get nearby pages (with latitude/longitude and distance)
  Future<List<Map<String, dynamic>>> getNearbyPages(double userLat, double userLng, {String? category});

  /// Create a new page via RPC (sets geography server-side from lat/lng)
  Future<Map<String, dynamic>> createPage({
    required String name,
    required String slug,
    required String category,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    String? avatarUrl,
    String? bannerUrl,
    String? contactEmail,
    String? contactPhone,
    String? websiteUrl,
  });

  /// Get posts from a specific page
  Future<List<Map<String, dynamic>>> getPagePosts(String pageId);
}

class SupabasePageRepository implements IPageRepository {
  final SupabaseClient _supabase;

  SupabasePageRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<List<Map<String, dynamic>>> getNearbyPages(double userLat, double userLng, {String? category}) async {
    final params = <String, dynamic>{
      'p_user_lat': userLat,
      'p_user_lng': userLng,
    };
    if (category != null) params['p_category'] = category;

    final response = await _supabase.rpc('get_nearby_pages', params: params);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> createPage({
    required String name,
    required String slug,
    required String category,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    String? avatarUrl,
    String? bannerUrl,
    String? contactEmail,
    String? contactPhone,
    String? websiteUrl,
  }) async {
    final params = <String, dynamic>{
      'p_name': name,
      'p_slug': slug,
      'p_category': category,
    };
    if (description != null) params['p_description'] = description;
    if (latitude != null) params['p_lat'] = latitude;
    if (longitude != null) params['p_lng'] = longitude;
    if (address != null) params['p_address'] = address;
    if (avatarUrl != null) params['p_avatar_url'] = avatarUrl;
    if (bannerUrl != null) params['p_banner_url'] = bannerUrl;
    if (contactEmail != null) params['p_contact_email'] = contactEmail;
    if (contactPhone != null) params['p_contact_phone'] = contactPhone;
    if (websiteUrl != null) params['p_website_url'] = websiteUrl;

    final response = await _supabase.rpc('create_page', params: params);
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getPagePosts(String pageId) async {
    return await _supabase
        .from('page_posts')
        .select('*, profiles!user_id(username, display_name, avatar_url)')
        .eq('page_id', pageId)
        .order('created_at', ascending: false);
  }
}

final pageRepositoryProvider = Provider<IPageRepository>((ref) {
  return SupabasePageRepository(supabase: Supabase.instance.client);
});
