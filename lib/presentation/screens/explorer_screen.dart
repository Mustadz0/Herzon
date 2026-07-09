import 'dart:math';
import 'dart:ui';
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
  bool _isSatelliteMode = false;
  bool _symbolHandlerAdded = false;
  ll.LatLng? _selectedZoneLatLng;
  String? _selectedZoneName;
  int _selectedZonePeople = 0;

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
    } catch (e) {
      debugPrint('Location init error: $e');
    }
  }

  void _toggleMapStyle() {
    setState(() => _isSatelliteMode = !_isSatelliteMode);
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

    // Build circle polygon (500m radius)
    final pts = LocationUtils.createCirclePolygon(loc, AppConstants.proximityRadiusMeters);
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

    // Register symbol tap handler (only once)
    if (!_symbolHandlerAdded) {
      _symbolHandlerAdded = true;
      ctrl.onSymbolTapped.add((Symbol symbol) {
        final content = symbol.data?['content'] as String? ?? '';
        final username = symbol.data?['username'] as String?;
        _showPostInfo(content, username);
      });
    }
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
    final suggestions = ref.watch(suggestionProvider);

    // Refresh markers when posts change
    ref.listen(postProvider, (_, next) {
      if (_styleLoaded && _userLocation != null) _addPostMarkers();
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.explore, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Explorer',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: t.isDark ? Colors.white : AppTheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: (t.isDark ? AppTheme.inverseSurface : Colors.white).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(_isSatelliteMode ? Icons.map : Icons.satellite_alt, size: 20),
              onPressed: _toggleMapStyle,
              tooltip: _isSatelliteMode ? 'Carte' : 'Satellite',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: (t.isDark ? AppTheme.inverseSurface : Colors.white).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(_showSuggestions ? Icons.map_outlined : Icons.lightbulb_outline, size: 20),
              onPressed: () => setState(() => _showSuggestions = !_showSuggestions),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: (t.isDark ? AppTheme.inverseSurface : Colors.white).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, size: 20),
              onPressed: _initLocation,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: _isSatelliteMode
                ? 'https://basemaps.cartocdn.com/gl/imagery-gl-style/style.json'
                : MapLibreStyles.openfreemapLiberty,
            initialCameraPosition: CameraPosition(
              target: LatLng(_userLocation?.latitude ?? 36.7538, _userLocation?.longitude ?? 3.0588),
              zoom: AppConstants.defaultZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(AppConstants.minZoom, AppConstants.maxZoom),
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: (point, latLng) {
              setState(() {
                _selectedZoneLatLng = ll.LatLng(latLng.latitude, latLng.longitude);
                _selectedZoneName = 'Zone ${(latLng.latitude + latLng.longitude).toStringAsFixed(1)}';
                _selectedZonePeople = Random().nextInt(20) + 3;
              });
            },
            compassEnabled: false,
            logoEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomRight,
          ),

          // Glass panel search bar
          Positioned(
            left: 20, right: 20, top: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: (t.isDark ? AppTheme.inverseSurface : Colors.white).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppTheme.outline, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Explorer les zones chaudes...',
                              style: TextStyle(
                                color: AppTheme.outlineVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.tune, color: AppTheme.primary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Zone info bottom panel on map click
          if (_selectedZoneLatLng != null)
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: _buildZonePanel(),
            ),

          // Active zones at top
          Positioned(
            left: 16, right: 16, top: 80,
            child: _buildActiveZonesRow(),
          ),
          if (_showSuggestions)
            Positioned(
              left: 20, right: 20, bottom: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                    decoration: BoxDecoration(
                      color: (t.isDark ? AppTheme.inverseSurface : Colors.white).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 48, height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.brandGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.lightbulb, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
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
                        Divider(height: 1, color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
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
                                          Icon(Icons.lightbulb_outline, size: 32, color: AppTheme.outline.withValues(alpha: 0.3)),
                                          const SizedBox(height: 8),
                                          Text('Aucune suggestion', style: TextStyle(color: AppTheme.outline)),
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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZonePanel() {
    if (_selectedZoneLatLng == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xB31E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: AppTheme.glassShadowHeavy,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedZoneName ?? 'Zone',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.white54, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '$_selectedZonePeople personnes ici',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedZoneLatLng = null),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white54, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Rejoindre cette zone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Explorer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border, color: Colors.white.withValues(alpha: 0.6), size: 14),
                            const SizedBox(width: 4),
                            Text('Enregistrer', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.my_location, color: AppTheme.primary, size: 14),
                            const SizedBox(width: 4),
                            Text('Je suis la', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveZonesRow() {
    final zones = [
      {'name': 'Centre-Ville', 'icon': Icons.location_city, 'count': 24},
      {'name': 'Plage', 'icon': Icons.beach_access, 'count': 18},
      {'name': 'Campus', 'icon': Icons.school, 'count': 15},
      {'name': 'Stade', 'icon': Icons.sports_soccer, 'count': 12},
      {'name': 'Marche', 'icon': Icons.store, 'count': 9},
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: zones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final z = zones[i];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedZoneName = z['name'] as String;
                _selectedZonePeople = z['count'] as int;
                _selectedZoneLatLng = _userLocation;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(z['icon'] as IconData, color: const Color(0xFF4F46E5), size: 14),
                  const SizedBox(width: 6),
                  Text(z['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${z['count']}', style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPostInfo(String content, String? username) {
    final t = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            decoration: BoxDecoration(
              color: (t.isDark ? AppTheme.inverseSurface : Colors.white).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48, height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      username ?? 'Anonyme',
                      style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(content, style: t.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
