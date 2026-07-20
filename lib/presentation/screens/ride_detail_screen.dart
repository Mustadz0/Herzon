import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firebase_uuid.dart';
import '../../data/models/ride_model.dart';

class RideDetailScreen extends StatefulWidget {
  final RideModel ride;
  const RideDetailScreen({super.key, required this.ride});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  int  _seatsToBook = 1;
  bool _booking     = false;
  bool _alreadyBooked = false;
  bool _loadingCheck  = true;
  String? _driverName;

  @override
  void initState() {
    super.initState();
    _checkAlreadyBooked();
    _loadDriver();
  }

  Future<void> _checkAlreadyBooked() async {
    try {
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUid == null) return;
      final uid = FirebaseUuid.toUuid(firebaseUid);
      final res = await Supabase.instance.client
          .from('ride_passengers')
          .select('id')
          .eq('ride_id', widget.ride.id)
          .eq('passenger_id', uid)
          .maybeSingle();
      if (mounted) setState(() {
        _alreadyBooked = res != null;
        _loadingCheck  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCheck = false);
    }
  }

  Future<void> _loadDriver() async {
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .eq('id', widget.ride.driverId)
          .maybeSingle();
      if (mounted && res != null) {
        setState(() => _driverName = res['display_name'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _bookRide() async {
    setState(() => _booking = true);
    try {
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUid == null) throw Exception('Non connecté');
      final uid = FirebaseUuid.toUuid(firebaseUid);

      if (uid == widget.ride.driverId) {
        throw Exception('Vous ne pouvez pas réserver votre propre ride');
      }
      if (_seatsToBook > widget.ride.seatsAvailable) {
        throw Exception('Pas assez de places disponibles');
      }

      await Supabase.instance.client.from('ride_passengers').insert({
        'id':           const Uuid().v4(),
        'ride_id':      widget.ride.id,
        'passenger_id': uid,
        'seats_booked': _seatsToBook,
        'status':       'confirmed',
        'created_at':   DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation confirmée ✅')),
        );
        setState(() => _alreadyBooked = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t   = Theme.of(context);
    final r   = widget.ride;
    final cs  = t.colorScheme;

    final formattedDep =
        '${r.departureTime.day.toString().padLeft(2, '0')}'
        '/${r.departureTime.month.toString().padLeft(2, '0')}'
        '/${r.departureTime.year}  '
        '${r.departureTime.hour.toString().padLeft(2, '0')}'
        ':${r.departureTime.minute.toString().padLeft(2, '0')}';

    final isOwner = () {
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUid == null) return false;
      return FirebaseUuid.toUuid(firebaseUid) == r.driverId;
    }();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du ride'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Carte trajet ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.glassShadowHeavy,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trip_origin_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.originName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 9),
                    child: Column(
                      children: List.generate(
                        3,
                        (_) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: SizedBox(
                            width: 2,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white54,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(1)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.destinationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Infos ───────────────────────────────────────
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Départ',
              value: formattedDep,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.event_seat_rounded,
              label: 'Places disponibles',
              value: '${r.seatsAvailable}',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.euro_rounded,
              label: 'Prix / place',
              value: '${r.pricePerSeat.toStringAsFixed(2)} €',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person_rounded,
              label: 'Conducteur',
              value: _driverName ?? '…',
            ),
            if (r.description != null && r.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.notes_rounded,
                label: 'Note',
                value: r.description!,
              ),
            ],

            const SizedBox(height: 28),

            // ── Sélecteur de places ─────────────────────────
            if (!isOwner && !_alreadyBooked && r.seatsAvailable > 0) ...[
              Text(
                'Nombre de places à réserver',
                style: t.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_seatsToBook > 1)
                        setState(() => _seatsToBook--);
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: cs.primary,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_seatsToBook',
                        style: t.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_seatsToBook < r.seatsAvailable)
                        setState(() => _seatsToBook++);
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: cs.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ── Bouton réserver ─────────────────────────────
            if (!isOwner)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _loadingCheck
                    ? const Center(child: CircularProgressIndicator())
                    : _alreadyBooked
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Réservation confirmée',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : r.seatsAvailable == 0
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text('Complet',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w700)),
                                ),
                              )
                            : _booking
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.brandGradient,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: FilledButton(
                                      onPressed: _bookRide,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        'Réserver $_seatsToBook place'
                                        '${_seatsToBook > 1 ? 's' : ''}'
                                        ' · ${(r.pricePerSeat * _seatsToBook).toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
              ),

            if (isOwner)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car_rounded, color: cs.primary),
                    const SizedBox(width: 10),
                    Text(
                      'C\'est votre ride',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: t.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: t.textTheme.labelSmall?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: t.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
