import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';
import '../../data/models/zone_model.dart';

/// Floating emoji marker displayed on the Explorer map.
/// Size scales with heat level: calm → 28 · active → 40 · hot → 48 · on-fire → 56.
/// Uses AppTheme tokens to match the rest of the app.
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
    final t    = Theme.of(context);
    final cs   = t.colorScheme;
    final size = zone.markerSize;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.isDark ? AppTheme.cardDark : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.22),
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
