// Fix: MarketplaceNotifier لم يكن يحمّل بيانات تلقائياً — أضيفنا استدعاء loadItems في البناء.
// Fix: mounted مضاف في كل عملية متأخرة.
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/firebase_uuid.dart';
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
      error: error,
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final IMarketplaceRepository _repo;
  final LocationService _locationService;

  MarketplaceNotifier(this._repo, this._locationService)
      : super(const MarketplaceState()) {
    loadItems(); // Fix: auto-load on creation
  }

  Future<void> loadItems({String? category}) async {
    state = state.copyWith(
        isLoading: true, error: null, selectedCategory: category);
    try {
      final pos = await _locationService.initializeLocation();
      final items = await _repo.getNearbyItems(
        pos,
        AppConstants.proximityRadiusMeters,
        category: category == 'Tout' ? null : category,
      );
      if (mounted) {
        state = state.copyWith(items: items, isLoading: false);
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createItem({
    required String title,
    String description = '',
    double? price,
    required String category,
    required List<File> mediaFiles,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw Exception('Not authenticated');
    final userId = FirebaseUuid.toUuid(firebaseUser.uid);
    final pos = await _locationService.initializeLocation();

    await _repo.createItem(
      userId: userId,
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
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final userId = FirebaseUuid.toUuid(firebaseUser.uid);
    try {
      await _repo.markAsSold(itemId, userId);
      if (mounted) await loadItems(category: state.selectedCategory);
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier(
    ref.watch(marketplaceRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});
