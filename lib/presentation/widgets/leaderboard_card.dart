import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';
import 'package:herzon/data/models/gamification_model.dart';

class LeaderboardCard extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final VoidCallback? onTap;

  const LeaderboardCard({super.key, required this.entry, this.onTap});

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  Color get _rankColor => switch (entry.rank) {
        1 => _gold,
        2 => _silver,
        3 => _bronze,
        _ => Colors.transparent,
      };

  bool get _isTopThree => entry.rank > 0 && entry.rank <= 3;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final bg = _isTopThree
        ? _rankColor.withValues(alpha: 0.06)
        : cs.surface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      elevation: _isTopThree ? 4 : 1,
      shadowColor: _isTopThree ? _rankColor.withValues(alpha: 0.25) : cs.primary.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _RankBadge(rank: entry.rank, color: _rankColor, isTopThree: _isTopThree),
              const SizedBox(width: 12),
              _Avatar(url: entry.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName ?? entry.username,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Level ${entry.level}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.xp}',
                    style: tt.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'XP',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;
  final bool isTopThree;
  const _RankBadge({required this.rank, required this.color, required this.isTopThree});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    if (isTopThree) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.emoji_events_rounded,
          size: 20,
          color: rank == 1 ? const Color(0xFF8B6914) : Colors.white,
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return CircleAvatar(
      radius: 24,
      backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      backgroundColor: cs.primaryContainer,
      child: (url == null || url!.isEmpty)
          ? Icon(Icons.person_rounded, color: cs.onPrimaryContainer, size: 22)
          : null,
    );
  }
}
