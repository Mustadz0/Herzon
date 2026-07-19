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
///   • Search bar top.
class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  MapLibreMapController? _mapController;

  // Default centre: Bab Ezzouar, Alger
  double _lat = 36.7372;
  double _lng = 3.1874;
  bool _locating = false;
  bool _showSuggestions = false;

  static const String _osmStyle =
      'https://demotiles.maplibre.org/style.json';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────
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

  // ── Zone bottom sheet → zone feed ───────────────────────────────────────
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

  // ── Map callbacks ────────────────────────────────────────────────────────
  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zoneProvider);
    final t     = Theme.of(context);
    final cs    = t.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── MapLibre map ─────────────────────────────────────────────────
          MapLibreMap(
            styleString: _osmStyle,
            initialCameraPosition: CameraPosition(
              target: LatLng(_lat, _lng),
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            compassEnabled: false,
          ),

          // ── Zone emoji markers ───────────────────────────────────────────
          if (!state.isLoading)
            ...state.zones.asMap().entries.map((entry) {
              final i    = entry.key;
              final zone = entry.value;
              return Positioned(
                left: 40.0 +
                    (i * 80) %
                        (MediaQuery.of(context).size.width - 80),
                top: 180.0 +
                    (i * 60) %
                        (MediaQuery.of(context).size.height - 280),
                child: ZoneMapMarker(
                  zone: zone,
                  onTap: () => _openZoneSheet(zone),
                ),
              );
            }),

          // ── Top bar (search + recenter) ──────────────────────────────────
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: t.isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor:
                          AppTheme.primary.withValues(alpha: 0.12),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher une zone…',
                          hintStyle:
                              TextStyle(color: cs.onSurfaceVariant),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: cs.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
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
                        gradient:
                            _locating ? null : AppTheme.brandGradient,
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
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (state.isLoading)
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

          // ── Suggestion toggle FAB ────────────────────────────────────────
          if (!_showSuggestions)
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

          // ── Suggestion panel (slide up from bottom) ──────────────────────
          if (_showSuggestions)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SuggestionPanel(
                onClose: () => setState(() => _showSuggestions = false),
              ),
            ),
        ],
      ),
    );
  }
}
