import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A glass-card showing the user's current level, XP, and progress to the
/// next level. Used on the user profile and other gamification surfaces.
class XpLevelBadge extends StatelessWidget {
  final int level;
  final int xp;
  final int nextXp;
  final int progressPercent;
  final bool compact;

  const XpLevelBadge({
    super.key,
    required this.level,
    required this.xp,
    required this.nextXp,
    required this.progressPercent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final pct = (progressPercent.clamp(0, 100)) / 100.0;
    final xpInLevel = (xp % 100);
    final xpForNext = 100;

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 12 : 18, horizontal: compact ? 14 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: t.isDark
              ? [const Color(0xFF312E81).withValues(alpha: 0.4), AppTheme.cardDark]
              : [const Color(0xFFEEF2FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: t.isDark
              ? const Color(0xFF312E81).withValues(alpha: 0.6)
              : AppTheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: compact ? _buildCompact(t) : _buildFull(pct, xpInLevel, xpForNext, t),
    );
  }

  Widget _buildFull(double pct, int xpInLevel, int xpForNext, ThemeData t) {
    return Row(
      children: [
        _BadgeCircle(level: level, size: 56),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Niveau $level',
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('$xp XP',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    )),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 6)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('$xpInLevel / $xpForNext XP pour niveau ${level + 1}',
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  Icon(Icons.stars, size: 12, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text('$xp',
                    style: t.textTheme.bodySmall?.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(ThemeData t) {
    return Row(
      children: [
        _BadgeCircle(level: level, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Niveau $level Â· $xp XP',
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(height: 6, color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF)),
                    FractionallySizedBox(
                      widthFactor: progressPercent.clamp(0, 100) / 100.0,
                      child: Container(height: 6, decoration: const BoxDecoration(gradient: AppTheme.brandGradient)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular gradient badge with level number â€” used by [XpLevelBadge] and the
/// leaderboard / comment / reaction contexts.
class _BadgeCircle extends StatelessWidget {
  final int level;
  final double size;

  const _BadgeCircle({required this.level, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final showLevel = level > 0;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.brandGradient,
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
            ),
          ),
          showLevel
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$level', style: TextStyle(fontSize: size > 40 ? 18 : 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    if (size > 40)
                      Text('NIV', style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ],
                )
              : Icon(Icons.stars, size: size / 2.5, color: Colors.white),
        ],
      ),
    );
  }
}

/// Helper to show a one-off `+N XP` snackbar from any action context.
void showXpSnackBar(BuildContext context, int xp) {
  if (xp <= 0) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
        child: const Icon(Icons.stars, color: Colors.white, size: 14),
      ),
      const SizedBox(width: 12),
      Text('+$xp XP', style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 1, milliseconds: 500),
    backgroundColor: AppTheme.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}
