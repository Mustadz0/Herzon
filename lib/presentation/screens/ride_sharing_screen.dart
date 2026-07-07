import 'package:flutter/material.dart';
import 'package:herzon/data/models/ride_model.dart';
import 'package:herzon/presentation/widgets/ride_card.dart';
import 'package:herzon/services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideSharingScreen extends StatefulWidget {
  const RideSharingScreen({super.key});

  @override
  State<RideSharingScreen> createState() => _RideSharingScreenState();
}

class _RideSharingScreenState extends State<RideSharingScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _filterDate;
  bool _isLoading = true;
  String? _error;

  List<RideModel> _rides = [];

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final locationService = LocationService();
      final pos = await locationService.initializeLocation();

      final response = await Supabase.instance.client.rpc('get_nearby_rides', params: {
        'p_user_lat': pos.latitude,
        'p_user_lng': pos.longitude,
        'p_radius_meters': 50000,
        'p_limit': 50,
      });

      final data = response as List<dynamic>;
      _rides = data.map((json) {
        final m = json as Map<String, dynamic>;
        return RideModel(
          id: m['id'] as String,
          driverId: m['driver_id'] as String,
          originLat: (m['origin_lat'] ?? pos.latitude) as double,
          originLng: (m['origin_lng'] ?? pos.longitude) as double,
          originName: (m['origin_name'] ?? 'Position actuelle') as String,
          destinationLat: (m['destination_lat'] ?? pos.latitude) as double,
          destinationLng: (m['destination_lng'] ?? pos.longitude) as double,
          destinationName: (m['destination_name'] ?? 'Destination') as String,
          departureTime: DateTime.parse(m['departure_time'] as String),
          seatsAvailable: (m['seats_available'] as num).toInt(),
          pricePerSeat: (m['price_per_seat'] ?? 0) as double,
          description: m['description'] as String?,
          status: (m['status'] ?? 'active') as String,
          createdAt: DateTime.parse(m['created_at'] as String),
        );
      }).toList();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<RideModel> get _filteredRides {
    return _rides.where((ride) {
      final matchesSearch = _searchController.text.isEmpty ||
          ride.originName
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          ride.destinationName
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesDate = _filterDate == null ||
          (ride.departureTime.year == _filterDate!.year &&
              ride.departureTime.month == _filterDate!.month &&
              ride.departureTime.day == _filterDate!.day);
      return matchesSearch && matchesDate;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rides Nearby')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search origin or destination...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                  tooltip: 'Filter by date',
                ),
                if (_filterDate != null)
                  IconButton(
                    onPressed: () => setState(() => _filterDate = null),
                    icon: const Icon(Icons.clear_rounded),
                    tooltip: 'Clear date filter',
                  ),
              ],
            ),
          ),
          if (_filterDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                label: Text(
                  '${_filterDate!.day}/${_filterDate!.month}/${_filterDate!.year}',
                ),
                onDeleted: () => setState(() => _filterDate = null),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                            const SizedBox(height: 16),
                            Text('Erreur: $_error', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadRides, child: const Text('Réessayer')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRides,
                        child: _filteredRides.isEmpty
                            ? const Center(child: Text('Aucune ride à proximité'))
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _filteredRides.length,
                                itemBuilder: (context, index) => RideCard(
                                  ride: _filteredRides[index],
                                  onTap: () {
                                    // Navigate to ride detail
                                  },
                                ),
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create ride screen
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
