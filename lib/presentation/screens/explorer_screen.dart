import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/zone_model.dart';
import '../providers/zone_provider.dart';
import '../widgets/zone_bottom_sheet.dart';
import '../widgets/zone_map_marker.dart';

/// Explorer screen — full-screen map with hot zone overlays.
///
/// Rules (from specs):
///   • Read-only: no posting, commenting, or messaging.
///   • Tapping a zone opens ZoneBottomSheet → then zone feed (read-only).
///   • Recenter button top-right.
///   • Search bar top.
class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  double _lat = 36.7372;  // Default: Bab Ezzouar, Algiers
  double _lng = 3.1874;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } finally {
      setState(() => _locating = false);
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

  void _openZoneSheet(ZoneModel zone) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ZoneBottomSheet(
        zone: zone,
        onEnterZone: () {
          Navigator.pop(context);
          // TODO: push ZoneFeedScreen(zone: zone, readOnly: true)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entrée dans ${zone.zoneName} — lecture seule'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zoneProvider);
    final cs    = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map layer ────────────────────────────────────────
          // Replace the Container below with GoogleMap / MapboxMap widget.
          // Pass markers via CustomPainter or GoogleMap markers.
          Container(
            color: cs.surfaceContainerLowest,
            child: Center(
              child: Text(
                '🗺️  Map placeholder\n(integrate google_maps_flutter here)',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),

          // ── Zone emoji markers ───────────────────────────────
          // In production: use GoogleMap markers / CustomPainter.
          // Here we use Positioned stubs for layout preview.
          if (!state.isLoading)
            ...state.zones.asMap().entries.map((entry) {
              final i    = entry.key;
              final zone = entry.value;
              return Positioned(
                left: 40.0 + (i * 80) % (MediaQuery.of(context).size.width - 80),
                top:  180.0 + (i * 60) % (MediaQuery.of(context).size.height - 280),
                child: ZoneMapMarker(
                  zone: zone,
                  onTap: () => _openZoneSheet(zone),
                ),
              );
            }),

          // ── Top UI bar ───────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Search bar
                  Expanded(
                    child: Material(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher une zone…',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Recenter button
                  IconButton.filledTonal(
                    onPressed: _locating ? null : _fetchLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading spinner ──────────────────────────────────
          if (state.isLoading)
            const Center(child: CircularProgressIndicator()),

          // ── Error banner ─────────────────────────────────────
          if (state.error != null)
            Positioned(
              bottom: 24,
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
        ],
      ),
    );
  }
}
