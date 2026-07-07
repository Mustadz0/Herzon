import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';
import 'package:herzon/data/models/ride_model.dart';
import 'package:herzon/presentation/widgets/ride_card.dart';

class RideSharingScreen extends StatefulWidget {
  const RideSharingScreen({super.key});

  @override
  State<RideSharingScreen> createState() => _RideSharingScreenState();
}

class _RideSharingScreenState extends State<RideSharingScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _filterDate;
  bool _isLoading = true;

  List<RideModel> _rides = [];

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDummyData() {
    _rides = List.generate(
      6,
      (index) => RideModel(
        id: 'ride_$index',
        driverId: 'driver_$index',
        originLat: 52.52,
        originLng: 13.405,
        originName: 'Berlin Central Station',
        destinationLat: 48.1351,
        destinationLng: 11.582,
        destinationName: 'Munich City Center',
        departureTime: DateTime.now().add(Duration(days: index, hours: 3)),
        seatsAvailable: 3 - (index % 3),
        pricePerSeat: 15.0 + index * 2.5,
        description: 'Comfortable ride with AC',
        status: 'open',
        createdAt: DateTime.now().subtract(Duration(days: index)),
      ),
    );
    setState(() => _isLoading = false);
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
    final cs = context.cs;

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
                : RefreshIndicator(
                    onRefresh: () async => _loadDummyData(),
                    child: _filteredRides.isEmpty
                        ? const Center(child: Text('No rides found'))
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
