import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:herzon/core/theme/app_theme.dart';
import '../../data/models/zone_model.dart';
import '../providers/zone_provider.dart';
import '../widgets/zone_bottom_sheet.dart';
import '../widgets/zone_map_marker.dart';
import '../widgets/suggestion_panel.dart';
import 'zone_feed_screen.dart';

/// Explorer screen — full-screen MapLibre map with hot zone overlays
/// and an interest-based suggestion panel.
///
/// Rules (CLAUDE.md §Two Modes):
///   • Read-only: no posting, commenting, or messaging.
///   • Tapping a zone → ZoneBottomSheet → ZoneFeedScreen (read-only).
///   • ✨ Toggle button bottom-right → SuggestionPanel slide-up.
///   • Recenter button top-right.
///   • Search bar top — debounced 400 ms, queries Supabase.
///
/// Map key is injected at build time:
///   flutter run --dart-define=MAPTILER_KEY=your_key_here
class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  MapLibreMapController? _mapController;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Default centre: Bab Ezzouar, Alger
  double _lat = 36.7372;
  double _lng = 3.1874;
  bool _locating = false;
  bool _showSuggestions = false;
  bool _searchFocused = false;

  // MapTiler key injected via --dart-define=MAPTILER_KEY=xxx
  static const String _mapTilerKey =
      String.fromEnvironment('MAPTILER_KEY', defaultValue: '');

  static String get _mapStyle =>
      'https://api.maptiler.com/maps/streets/style.json?key=$_mapTilerKey';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _mapController?.onSymbolTapped.remove(_onSymbolTapped);
    super.dispose();
  }

  void _onSymbolTapped(Symbol symbol) {}

  // ── Search (debounced 400 ms) ─────────────────────────────────────────────
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(zoneProvider.notifier).searchZones(value);
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(zoneProvider.notifier).searchZones('');
    setState(() => _searchFocused = false);
    FocusScope.of(context).unfocus();
  }

  // ── Location ──────────────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(_lat, _lng), 15),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
      _loadZones();
    }
  }

  void _loadZones() {
    ref.read(zoneProvider.notifier).loadNearbyZones(
          lat: _lat,
          lng: _lng,
          radiusMeters: 500,
        );
  }

  // ── Zone bottom sheet → zone feed ─────────────────────────────────────────
  void _openZoneSheet(ZoneModel zone) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      backgroundColor:
          Theme.of(context).isDark ? const Color(0xFF121212) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ZoneBottomSheet(
        zone: zone,
        onEnterZone: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ZoneFeedScreen(
                zone: zone,
                userLat: _lat,
                userLng: _lng,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Map created ────────────────────────────────────────────────────────────
  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.onSymbolTapped.add(_onSymbolTapped);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zoneProvider);
    final t  = Theme.of(context);
    final cs = t.colorScheme;
    final bool keyMissing = _mapTilerKey.isEmpty;
    final bool isSearching = state.searchQuery.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          // ── MapLibre map ───────────────────────────────────────────────────
          MapLibreMap(
            styleString: _mapStyle,
            initialCameraPosition: CameraPosition(
              target: LatLng(_lat, _lng),
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            compassEnabled: false,
            attributionButtonMargins: const Point(8, 8),
          ),

          // ── Dev warning: missing key ───────────────────────────────────────
          if (keyMissing)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Material(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: cs.onErrorContainer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MAPTILER_KEY manquant — '
                          'lancez avec --dart-define=MAPTILER_KEY=xxx',
                          style: TextStyle(
                              color: cs.onErrorContainer, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Zone markers ──────────────────────────────────────────────────
          if (!state.isLoading)
            ...state.displayedZones.map((zone) {
              return _GeoMarker(
                key: ValueKey(zone.id),
                zone: zone,
                mapController: _mapController,
                onTap: () => _openZoneSheet(zone),
              );
            }),

          // ── Top bar ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color:
                              t.isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 2,
                          shadowColor:
                              AppTheme.primary.withValues(alpha: 0.12),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            onTap: () =>
                                setState(() => _searchFocused = true),
                            decoration: InputDecoration(
                              hintText: 'Rechercher une zone…',
                              hintStyle: TextStyle(
                                  color: cs.onSurfaceVariant),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: isSearching
                                    ? AppTheme.primary
                                    : cs.onSurfaceVariant,
                              ),
                              suffixIcon: isSearching || _searchFocused
                                  ? IconButton(
                                      icon: const Icon(
                                          Icons.close_rounded),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Recenter button
                      GestureDetector(
                        onTap: _locating ? null : _fetchLocation,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: _locating
                                ? null
                                : AppTheme.brandGradient,
                            color: _locating
                                ? cs.surfaceContainerHighest
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _locating
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppTheme.secondary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: _locating
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Search results dropdown ──────────────────────────────
                if (isSearching)
                  _SearchDropdown(
                    zones: state.searchResults,
                    isLoading: state.isLoading,
                    onSelect: (zone) {
                      _clearSearch();
                      // Fly to selected zone on the map
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(zone.lat, zone.lng),
                          16,
                        ),
                      );
                      _openZoneSheet(zone);
                    },
                  ),
              ],
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (state.isLoading && !isSearching)
            const Center(child: CircularProgressIndicator()),

          // ── Error banner ──────────────────────────────────────────────────
          if (state.error != null && !_showSuggestions)
            Positioned(
              bottom: 88,
              left: 16,
              right: 16,
              child: Material(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: cs.onErrorContainer),
                  ),
                ),
              ),
            ),

          // ── Suggestion toggle FAB ──────────────────────────────────────────
          if (!_showSuggestions && !isSearching)
            Positioned(
              bottom: 24,
              right: 16,
              child: GestureDetector(
                onTap: () => setState(() => _showSuggestions = true),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Suggestions',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Suggestion panel ──────────────────────────────────────────────
          if (_showSuggestions)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SuggestionPanel(
                userLat: _lat,
                userLng: _lng,
                onClose: () => setState(() => _showSuggestions = false),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Search results dropdown ────────────────────────────────────────────────
class _SearchDropdown extends StatelessWidget {
  final List<ZoneModel> zones;
  final bool isLoading;
  final ValueChanged<ZoneModel> onSelect;

  const _SearchDropdown({
    required this.zones,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t  = Theme.of(context);
    final cs = t.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: t.isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: AppTheme.primary.withValues(alpha: 0.15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : zones.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Aucune zone trouvée',
                          style: TextStyle(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: zones.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                        itemBuilder: (_, i) {
                          final zone = zones[i];
                          return ListTile(
                            dense: true,
                            leading: Text(
                              zone.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                            title: Text(
                              zone.zoneName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              zone.heatLabel,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              '${zone.activeUsers} 👤',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () => onSelect(zone),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}

// ── Geo-positioned marker widget ───────────────────────────────────────────
class _GeoMarker extends StatefulWidget {
  final ZoneModel zone;
  final MapLibreMapController? mapController;
  final VoidCallback onTap;

  const _GeoMarker({
    super.key,
    required this.zone,
    required this.mapController,
    required this.onTap,
  });

  @override
  State<_GeoMarker> createState() => _GeoMarkerState();
}

class _GeoMarkerState extends State<_GeoMarker> {
  Offset? _screenPos;

  @override
  void initState() {
    super.initState();
    _updatePosition();
  }

  @override
  void didUpdateWidget(_GeoMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePosition();
  }

  Future<void> _updatePosition() async {
    final ctrl = widget.mapController;
    if (ctrl == null) return;
    try {
      final point = await ctrl.toScreenLocation(
        LatLng(widget.zone.lat, widget.zone.lng),
      );
      if (mounted) {
        setState(() =>
            _screenPos = Offset(point.x.toDouble(), point.y.toDouble()));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_screenPos == null) return const SizedBox.shrink();
    return Positioned(
      left: _screenPos!.dx - 24,
      top:  _screenPos!.dy - 24,
      child: ZoneMapMarker(
        zone: widget.zone,
        onTap: widget.onTap,
      ),
    );
  }
}
