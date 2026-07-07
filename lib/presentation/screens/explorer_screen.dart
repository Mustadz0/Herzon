import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_utils.dart';
import '../providers/post_provider.dart';
import '../providers/suggestion_provider.dart';
import '../../services/location_service.dart';
import '../widgets/post_card.dart';
import 'search_screen.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  MapLibreMapController? _mapController;
  ll.LatLng? _userLocation;
  bool _styleLoaded = false;
  final _sheetController = DraggableScrollableController();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(suggestionProvider.notifier).loadSuggestions();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final loc = await ref.read(locationServiceProvider).initializeLocation();
      setState(() => _userLocation = loc);
      await _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(loc.latitude, loc.longitude), zoom: AppConstants.defaultZoom),
      ));
      await _addMapContent();
    } catch (_) {}
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    if (_userLocation != null) _addMapContent();
  }

  Future<void> _addMapContent() async {
    if (_mapController == null || _userLocation == null || !_styleLoaded) return;
    final ctrl = _mapController!;
    final loc = _userLocation!;

    // Remove old radius source
    try { await ctrl.addGeoJsonSource('radius-source', {
      "type": "FeatureCollection",
      "features": []
    }); } catch (_) {}

    // Build circle polygon (2000m radius)
    final pts = LocationUtils.createCirclePolygon(loc, 2000);
    final coords = pts.map((p) => [p.longitude, p.latitude]).toList();
    coords.add(coords.first);

    await ctrl.setGeoJsonSource('radius-source', {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": {"type": "Polygon", "coordinates": [coords]},
        "properties": {}
      }]
    });

    // Add layers
    try {
      await ctrl.addFillLayer('radius-source', 'radius-fill',
        const FillLayerProperties(fillColor: '#146366F1', fillOpacity: 0.08),
        enableInteraction: false,
      );
    } catch (_) {}
    try {
      await ctrl.addLineLayer('radius-source', 'radius-outline',
        const LineLayerProperties(lineColor: '#4D6366F1', lineWidth: 2),
        enableInteraction: false,
      );
    } catch (_) {}

    // Add post markers
    await _addPostMarkers();

    // Register symbol tap handler
    ctrl.onSymbolTapped.add((Symbol symbol) {
      final content = symbol.data?['content'] as String? ?? '';
      final username = symbol.data?['username'] as String?;
      _showPostInfo(content, username);
    });
  }

  Future<void> _addPostMarkers() async {
    if (_mapController == null || !_styleLoaded) return;
    final ctrl = _mapController!;
    await ctrl.clearSymbols();

    final feed = ref.read(postProvider);
    final options = feed.posts.map((post) => SymbolOptions(
      geometry: LatLng(post.latitude, post.longitude),
      iconImage: 'marker-15',
      iconSize: 1.0,
      iconColor: '#6366F1',
      iconHaloColor: '#FFFFFF',
      iconHaloWidth: 1,
    )).toList();

    if (options.isEmpty) return;
    final dataList = feed.posts.map((post) => <String, dynamic>{
      'content': post.content,
      'username': post.userDisplayName,
    }).toList();
    await ctrl.addSymbols(options, dataList);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final feed = ref.watch(postProvider);
    final suggestions = ref.watch(suggestionProvider);

    // Refresh markers when posts change
    ref.listen(postProvider, (_, next) {
      if (_styleLoaded && _userLocation != null) _addPostMarkers();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
          IconButton(
            icon: Icon(_showSuggestions ? Icons.map_outlined : Icons.lightbulb_outline),
            onPressed: () => setState(() => _showSuggestions = !_showSuggestions),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _initLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: MapLibreStyles.openfreemapLiberty,
            initialCameraPosition: CameraPosition(
              target: LatLng(_userLocation?.latitude ?? 36.7538, _userLocation?.longitude ?? 3.0588),
              zoom: AppConstants.defaultZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(AppConstants.minZoom, AppConstants.maxZoom),
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: (point, latLng) => _showZoneInfo(latLng, feed.posts),
            compassEnabled: false,
            logoEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomRight,
          ),

          // Search bar (unchanged)
          Positioned(
            left: 16, right: 16, top: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              color: t.isDark ? AppTheme.cardDark : Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: t.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text('Rechercher...', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Suggestion panel (unchanged)
          if (_showSuggestions)
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                decoration: BoxDecoration(
                  color: t.isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 36, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.lightbulb, color: AppTheme.accent, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text('Suggestions', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: () => ref.read(suggestionProvider.notifier).loadSuggestions(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: suggestions.isLoading
                          ? const Center(child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ))
                          : suggestions.posts.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Icon(Icons.lightbulb_outline, size: 32, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                      const SizedBox(height: 8),
                                      Text('Aucune suggestion', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  shrinkWrap: true,
                                  itemCount: min(suggestions.posts.length, 5),
                                  itemBuilder: (_, i) => PostCard(post: suggestions.posts[i]),
                                ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showZoneInfo(LatLng latLng, List<dynamic> posts) {
    final t = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.location_on, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zone', style: t.textTheme.titleMedium),
                    Text('${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.article_outlined, size: 18, color: t.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('${posts.length} publications Ã  proximitÃ©',
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPostInfo(String content, String? username) {
    final t = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(gradient: AppTheme.brandGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(username ?? 'Anonyme', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(content, style: t.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
