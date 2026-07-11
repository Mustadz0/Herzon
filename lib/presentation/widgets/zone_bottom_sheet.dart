import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';
import '../../data/models/zone_model.dart';

/// Bottom sheet shown when the user taps a zone emoji on the Explorer map.
/// Design tokens: AppTheme.brandGradient (CTA), AppTheme.cardDark (dark bg),
/// same shape/handle as _CheckInSheet in home_screen.dart.
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
    final t  = Theme.of(context);
    final cs = t.colorScheme;
    final tt = t.textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle — same as _CheckInSheet: 36×4, grey[300]
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
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
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        zone.heatLabel,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Heat progress bar — uses AppTheme.primary
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: (zone.heatScore.clamp(0, 50)) / 50,
                minHeight: 8,
                backgroundColor: t.isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 14),

            // 3 counters — same card style as profile stats in home_screen
            Row(
              children: [
                _Counter(label: 'Présents', value: zone.activeUsers.toString()),
                const SizedBox(width: 8),
                _Counter(label: 'Posts',    value: zone.recentPosts.toString()),
                const SizedBox(width: 8),
                _Counter(label: 'Vibes',    value: zone.recentVibes.toString()),
              ],
            ),
            const SizedBox(height: 12),

            // Dominant activity
            if (zone.dominantActivity != null) ...[
              Text(
                'Activité dominante : ${zone.dominantActivity}',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
            ],

            // CTA — AppTheme.brandGradient (same as _CenterFab + _MenuTile icons)
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: onEnterZone,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Entrer dans la zone',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
    final t  = Theme.of(context);
    final cs = t.colorScheme;
    final tt = t.textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: t.isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: t.isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
