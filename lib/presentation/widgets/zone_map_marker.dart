import 'package:flutter/material.dart';
import '../../data/models/zone_model.dart';

/// Floating emoji marker displayed on the Explorer map.
/// Size scales with heat level: calm → 28, active → 40, hot → 48, on-fire → 56.
class ZoneMapMarker extends StatelessWidget {
  final ZoneModel zone;
  final VoidCallback onTap;

  const ZoneMapMarker({
    super.key,
    required this.zone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final size = zone.markerSize;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.18),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          zone.emoji,
          style: TextStyle(fontSize: size * 0.44),
        ),
      ),
    );
  }
}
