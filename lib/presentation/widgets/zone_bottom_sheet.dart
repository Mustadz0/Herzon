import 'package:flutter/material.dart';
import '../../data/models/zone_model.dart';

/// Bottom sheet shown when the user taps a zone emoji on the Explorer map.
/// Displays: name, heat label, progress bar, 3 counters, dominant activity,
/// and an "Entrer dans la zone" CTA button.
class ZoneBottomSheet extends StatelessWidget {
  final ZoneModel zone;
  final VoidCallback onEnterZone;

  const ZoneBottomSheet({
    super.key,
    required this.zone,
    required this.onEnterZone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Zone name + emoji
            Row(
              children: [
                Text(zone.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.zoneName,
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        zone.heatLabel,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Heat progress bar
            LinearProgressIndicator(
              value: (zone.heatScore.clamp(0, 50)) / 50,
              minHeight: 8,
              borderRadius: BorderRadius.circular(100),
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
            const SizedBox(height: 14),

            // 3 counters
            Row(
              children: [
                _Counter(
                  label: 'Présents',
                  value: zone.activeUsers.toString(),
                ),
                const SizedBox(width: 8),
                _Counter(
                  label: 'Posts',
                  value: zone.recentPosts.toString(),
                ),
                const SizedBox(width: 8),
                _Counter(
                  label: 'Vibes',
                  value: zone.recentVibes.toString(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dominant activity (optional)
            if (zone.dominantActivity != null) ...
              [
                Text(
                  'Activité dominante : \${zone.dominantActivity}',
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
              ],

            // CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onEnterZone,
                child: const Text('Entrer dans la zone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final String value;

  const _Counter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: tt.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
