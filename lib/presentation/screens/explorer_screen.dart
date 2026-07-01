import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/post_provider.dart';
import '../../services/location_service.dart';
import 'search_screen.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  LatLng? _userLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final loc = await ref.read(locationServiceProvider).initializeLocation();
      setState(() => _userLocation = loc);
      _mapController.move(loc, AppConstants.defaultZoom);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(postProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
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
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? const LatLng(36.7538, 3.0588),
          initialZoom: AppConstants.defaultZoom,
          minZoom: AppConstants.minZoom,
          maxZoom: AppConstants.maxZoom,
          onTap: (tapPosition, latLng) => _showZoneInfo(latLng, feed.posts),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.proximite',
          ),
          if (_userLocation != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _userLocation!,
                  radius: 2000,
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          if (_userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _userLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 32),
                ),
                ...feed.posts.map((post) => Marker(
                  point: LatLng(post.latitude, post.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showPostInfo(post.content, post.userDisplayName),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                      ),
                      child: const Icon(Icons.circle, color: AppTheme.secondaryColor, size: 32),
                    ),
                  ),
                )),
              ],
            ),
        ],
      ),
    );
  }

  void _showZoneInfo(LatLng latLng, List<dynamic> posts) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 8),
            Text('${posts.length} publications a proximite'),
          ],
        ),
      ),
    );
  }

  void _showPostInfo(String content, String? username) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(username ?? 'Anonyme', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
