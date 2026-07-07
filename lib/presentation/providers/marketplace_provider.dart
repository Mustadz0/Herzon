import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/marketplace_item_model.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../services/location_service.dart';
import '../../core/constants/app_constants.dart';

class MarketplaceState {
  final List<MarketplaceItemModel> items;
  final bool isLoading;
  final String? selectedCategory;
  final String? error;

  const MarketplaceState({
    this.items = const [],
    this.isLoading = false,
    this.selectedCategory,
    this.error,
  });

  MarketplaceState copyWith({
    List<MarketplaceItemModel>? items,
    bool? isLoading,
    String? selectedCategory,
    String? error,
  }) {
    return MarketplaceState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error: error ?? this.error,
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final IMarketplaceRepository _repo;
  final LocationService _locationService;

  MarketplaceNotifier(this._repo, this._locationService) : super(const MarketplaceState());

  Future<void> loadItems({String? category}) async {
    state = state.copyWith(isLoading: true, error: null, selectedCategory: category);
    try {
      final pos = await _locationService.initializeLocation();
      final items = await _repo.getNearbyItems(
        pos, AppConstants.proximityRadiusMeters,
        category: category == 'Tout' ? null : category,
      );
      state = MarketplaceState(items: items, selectedCategory: category);
    } catch (e) {
      state = MarketplaceState(error: e.toString());
    }
  }

  Future<void> createItem({
    required String title,
    String description = '',
    double? price,
    required String category,
    required List<File> mediaFiles,
  }) async {
    final pos = await _locationService.initializeLocation();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _repo.createItem(
      userId: user.id,
      title: title,
      description: description,
      price: price,
      currency: 'DZD',
      category: category,
      mediaFiles: mediaFiles,
      location: pos,
    );
    await loadItems();
  }

  Future<void> markAsSold(String itemId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await _repo.markAsSold(itemId, user.id);
      await loadItems(category: state.selectedCategory);
    } catch (_) {}
  }
}

final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier(
    ref.watch(marketplaceRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
