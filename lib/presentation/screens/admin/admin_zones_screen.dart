import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminZonesScreen extends StatefulWidget {
  const AdminZonesScreen({super.key});

  @override
  State<AdminZonesScreen> createState() => _AdminZonesScreenState();
}

class _AdminZonesScreenState extends State<AdminZonesScreen> {
  List<Map<String, dynamic>> _zones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('zones')
          .select('*')
          .order('name');

      // Count posts per zone separately (no FK between zones and posts)
      for (var zone in data) {
        try {
          final zoneId = zone['id'];
          if (zoneId != null) {
            final postCount = await Supabase.instance.client
                .from('posts')
                .select('id')
                .eq('zone_id', zoneId)
                .count();
            zone['post_count'] = postCount.count;
          } else {
            zone['post_count'] = 0;
          }
        } catch (_) {
          zone['post_count'] = 0;
        }
      }
      setState(() {
        _zones = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 16),
                      Text('Erreur: $_error', style: GoogleFonts.plusJakartaSans(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadZones, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _zones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune zone définie',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadZones,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _zones.length,
                        itemBuilder: (context, index) {
                          final zone = _zones[index];
                          final postCount = zone['posts'] is List ? (zone['posts'] as List).length : 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.map, color: Color(0xFF7C3AED), size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        zone['name'] ?? 'Zone inconnue',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$postCount posts',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Actif',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
