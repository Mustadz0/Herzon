import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firebase_uuid.dart';

class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originCtrl      = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _priceCtrl       = TextEditingController(text: '0');
  int    _seats          = 1;
  DateTime _departureTime = DateTime.now().add(const Duration(hours: 1));
  bool   _loading        = false;

  @override
  void dispose() {
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _departureTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUid == null) throw Exception('Non connecté');
      final driverId = FirebaseUuid.toUuid(firebaseUid);

      await Supabase.instance.client.from('rides').insert({
        'id':               const Uuid().v4(),
        'driver_id':        driverId,
        'origin_lat':       0.0,
        'origin_lng':       0.0,
        'origin_name':      _originCtrl.text.trim(),
        'destination_lat':  0.0,
        'destination_lng':  0.0,
        'destination_name': _destinationCtrl.text.trim(),
        'departure_time':   _departureTime.toIso8601String(),
        'seats_available':  _seats,
        'price_per_seat':   double.tryParse(_priceCtrl.text) ?? 0.0,
        'description':      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'status':           'open',
        'created_at':       DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride créé avec succès ✅')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final formatted =
        '${_departureTime.day.toString().padLeft(2, '0')}'
        '/${_departureTime.month.toString().padLeft(2, '0')}'
        '/${_departureTime.year}  '
        '${_departureTime.hour.toString().padLeft(2, '0')}'
        ':${_departureTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppTheme.brandGradient.createShader(b),
          child: const Text('Proposer un ride',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Origine ──────────────────────────────
              _SectionLabel(label: 'Départ', icon: Icons.trip_origin_rounded),
              const SizedBox(height: 8),
              TextFormField(
                controller: _originCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex: Gare de Lyon, Paris',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),

              // ── Destination ──────────────────────────
              _SectionLabel(label: 'Destination', icon: Icons.flag_rounded),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destinationCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex: Aéroport CDG',
                  prefixIcon: Icon(Icons.location_searching_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),

              // ── Date / heure ─────────────────────────
              _SectionLabel(label: 'Date & heure de départ', icon: Icons.schedule_rounded),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: t.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 20, color: t.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(formatted,
                          style: t.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: t.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Places ────────────────────────────────
              _SectionLabel(label: 'Places disponibles', icon: Icons.event_seat_rounded),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_seats > 1) setState(() => _seats--);
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: t.colorScheme.primary,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_seats',
                        style: t.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_seats < 8) setState(() => _seats++);
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: t.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Prix ─────────────────────────────────
              _SectionLabel(label: 'Prix par place (€)', icon: Icons.euro_rounded),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.euro_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (double.tryParse(v) == null) return 'Nombre invalide';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Description ──────────────────────────
              _SectionLabel(label: 'Description (optionnel)', icon: Icons.notes_rounded),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText: 'Infos supplémentaires, bagages, animal…',
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Publier le ride',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
