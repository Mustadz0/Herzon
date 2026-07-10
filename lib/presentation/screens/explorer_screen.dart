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

  void _toggleMapStyle() => setState(() => _isSatelliteMode = !_isSatelliteMode);

  void _onMapCreated(MapLibreMapController controller) => _mapController = controller;

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    if (_userLocation != null) _addMapContent();
  }

  Future<void> _addMapContent() async {
    if (_mapController == null || _userLocation == null || !_styleLoaded) return;
    final ctrl = _mapController!;
    final loc = _userLocation!;

    try {
      await ctrl.addGeoJsonSource('radius-source', {
        'type': 'FeatureCollection',
        'features': [],
      });
    } catch (_) {}

    final pts = LocationUtils.createCirclePolygon(loc, AppConstants.proximityRadiusMeters);
    final coords = pts.map((p) => [p.longitude, p.latitude]).toList();
    coords.add(coords.first);

    await ctrl.setGeoJsonSource('radius-source', {
      'type': 'FeatureCollection',
      'features': [{
        'type': 'Feature',
        'geometry': {'type': 'Polygon', 'coordinates': [coords]},
        'properties': {},
      }],
    });

    try {
      await ctrl.addFillLayer('radius-source', 'radius-fill',
        const FillLayerProperties(fillColor: '#146366F1', fillOpacity: 0.08),
        enableInteraction: false);
    } catch (_) {}
    try {
      await ctrl.addLineLayer('radius-source', 'radius-outline',
        const LineLayerProperties(lineColor: '#4D6366F1', lineWidth: 2),
        enableInteraction: false);
    } catch (_) {}

    await _addPostMarkers();

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = ref.watch(suggestionProvider);

    ref.listen(postProvider, (_, next) {
      if (_styleLoaded && _userLocation != null) _addPostMarkers();
    });

    final surfaceOverlay = isDark
        ? cs.inverseSurface.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);

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
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          _AppBarAction(
            icon: _isSatelliteMode ? Icons.map : Icons.satellite_alt,
            surfaceOverlay: surfaceOverlay,
            onPressed: _toggleMapStyle,
            tooltip: _isSatelliteMode ? 'Carte' : 'Satellite',
          ),
          _AppBarAction(
            icon: _showSuggestions ? Icons.map_outlined : Icons.lightbulb_outline,
            surfaceOverlay: surfaceOverlay,
            onPressed: () => setState(() => _showSuggestions = !_showSuggestions),
          ),
          _AppBarAction(
            icon: Icons.my_location,
            surfaceOverlay: surfaceOverlay,
            onPressed: _initLocation,
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
              target: LatLng(
                _userLocation?.latitude ?? 36.7538,
                _userLocation?.longitude ?? 3.0588,
              ),
              zoom: AppConstants.defaultZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(
                AppConstants.minZoom, AppConstants.maxZoom),
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: (point, latLng) {
              // People count should come from backend; using fixed seed for determinism
              final seed = (latLng.latitude * 1000).truncate() +
                  (latLng.longitude * 1000).truncate();
              setState(() {
                _selectedZoneLatLng =
                    ll.LatLng(latLng.latitude, latLng.longitude);
                _selectedZoneName =
                    'Zone ${(latLng.latitude + latLng.longitude).toStringAsFixed(1)}';
                _selectedZonePeople = (seed.abs() % 20) + 3;
              });
            },
            compassEnabled: false,
            logoEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomRight,
          ),

          // Glass search bar
          Positioned(
            left: 20,
            right: 20,
            top: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceOverlay,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SearchScreen())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 22, color: cs.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Explorer les zones chaudes...',
                              style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.tune,
                                size: 18, color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Zone info bottom panel
          if (_selectedZoneLatLng != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ZonePanel(
                zoneName: _selectedZoneName,
                zonePeople: _selectedZonePeople,
                onClose: () => setState(() => _selectedZoneLatLng = null),
              ),
            ),

          // Active zones chips
          Positioned(
            left: 16,
            right: 16,
            top: 80,
            child: _ActiveZonesRow(
              userLocation: _userLocation,
              onZoneTap: (name, count, loc) => setState(() {
                _selectedZoneName = name;
                _selectedZonePeople = count;
                _selectedZoneLatLng = loc;
              }),
            ),
          ),

          // Suggestions panel
          if (_showSuggestions)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: _SuggestionsPanel(
                suggestions: suggestions,
                onRefresh: () =>
                    ref.read(suggestionProvider.notifier).loadSuggestions(),
              ),
            ),
        ],
      ),
    );
  }

  void _showPostInfo(String content, String? username) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isDark
                  ? cs.surfaceContainer
                  : Colors.white.withValues(alpha: 0.97),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      username ?? 'Anonyme',
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Text(content, style: tt.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Extracted Widgets ────────────────────────────────────────────────────────

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final Color surfaceOverlay;
  final VoidCallback onPressed;
  final String? tooltip;

  const _AppBarAction({
    required this.icon,
    required this.surfaceOverlay,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: surfaceOverlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: cs.onSurface),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class _ZonePanel extends StatelessWidget {
  final String? zoneName;
  final int zonePeople;
  final VoidCallback onClose;

  const _ZonePanel({
    required this.zoneName,
    required this.zonePeople,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainer.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
            boxShadow: AppTheme.glassShadowHeavy,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zoneName ?? 'Zone',
                          style: tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.people,
                                color: cs.onSurfaceVariant, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '$zonePeople personnes ici',
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close,
                        color: cs.onSurfaceVariant, size: 16),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text('Rejoindre cette zone'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Explorer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border, size: 14),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.my_location, size: 14),
                          const SizedBox(width: 4),
                          const Text('Je suis là'),
                        ],
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
}

class _ActiveZonesRow extends StatelessWidget {
  final ll.LatLng? userLocation;
  final void Function(String name, int count, ll.LatLng? loc) onZoneTap;

  const _ActiveZonesRow(
      {required this.userLocation, required this.onZoneTap});

  static const _zones = [
    {'name': 'Centre-Ville', 'icon': Icons.location_city, 'count': 24},
    {'name': 'Plage', 'icon': Icons.beach_access, 'count': 18},
    {'name': 'Campus', 'icon': Icons.school, 'count': 15},
    {'name': 'Stade', 'icon': Icons.sports_soccer, 'count': 12},
    {'name': 'Marché', 'icon': Icons.store, 'count': 9},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _zones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final z = _zones[i];
          return GestureDetector(
            onTap: () => onZoneTap(
              z['name'] as String,
              z['count'] as int,
              userLocation,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(z['icon'] as IconData,
                      color: cs.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    z['name'] as String,
                    style: tt.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${z['count']}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  final dynamic suggestions;
  final VoidCallback onRefresh;

  const _SuggestionsPanel(
      {required this.suggestions, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainer.withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
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
                      child: const Icon(Icons.lightbulb,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text('Suggestions',
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: onRefresh,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.2)),
              Flexible(
                child: suggestions.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                    : suggestions.posts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    size: 32,
                                    color: cs.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text('Aucune suggestion',
                                    style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            shrinkWrap: true,
                            itemCount:
                                min(suggestions.posts.length, 5),
                            itemBuilder: (_, i) =>
                                PostCard(post: suggestions.posts[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
