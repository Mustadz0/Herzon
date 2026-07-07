import 'package:flutter/material.dart';
import 'package:herzon/core/theme/app_theme.dart';
import 'package:herzon/data/models/badge_model.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final List<_BadgeViewModel> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    _badges.addAll([
      _BadgeViewModel(
        badge: BadgeModel(
          id: '1',
          name: 'First Post',
          description: 'Create your first post',
          category: 'Social',
          requiredXp: 0,
        ),
        earnedAt: DateTime.now().subtract(const Duration(days: 5)),
        progress: 1.0,
      ),
      _BadgeViewModel(
        badge: BadgeModel(
          id: '2',
          name: 'Influencer',
          description: 'Atteindre 100 Fans',
          category: 'Social',
          requiredXp: 500,
        ),
        progress: 0.75,
      ),
      _BadgeViewModel(
        badge: BadgeModel(
          id: '3',
          name: 'Check-in King',
          description: 'Check in at 10 different places',
          category: 'Explorer',
          requiredXp: 200,
        ),
        earnedAt: DateTime.now().subtract(const Duration(days: 2)),
        progress: 1.0,
      ),
      _BadgeViewModel(
        badge: BadgeModel(
          id: '4',
          name: 'Ride Sharing',
          description: 'Share 5 rides',
          category: 'Ride',
          requiredXp: 300,
        ),
        progress: 0.4,
      ),
      _BadgeViewModel(
        badge: BadgeModel(
          id: '5',
          name: 'Poll Master',
          description: 'Create 10 polls',
          category: 'Social',
          requiredXp: 150,
        ),
        progress: 0.0,
      ),
      _BadgeViewModel(
        badge: BadgeModel(
          id: '6',
          name: 'Top of Global',
          description: 'Rank #1 on global leaderboard',
          category: 'Competition',
          requiredXp: 1000,
        ),
        progress: 0.1,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Scaffold(
      appBar: AppBar(title: const Text('My Badges')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _badges.length,
        itemBuilder: (context, index) => _BadgeCard(badge: _badges[index]),
      ),
    );
  }
}

class _BadgeViewModel {
  final BadgeModel badge;
  final DateTime? earnedAt;
  final double progress;

  _BadgeViewModel({
    required this.badge,
    this.earnedAt,
    this.progress = 0.0,
  });

  bool get isEarned => earnedAt != null;
}

class _BadgeCard extends StatelessWidget {
  final _BadgeViewModel badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final isEarned = badge.isEarned;

    return Card(
      color: isEarned ? null : cs.surfaceContainerHighest?.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: isEarned ? cs.primaryContainer : cs.outline,
                  child: Icon(
                    isEarned ? Icons.emoji_events_rounded : Icons.lock_rounded,
                    size: 36,
                    color: isEarned ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  ),
                ),
                if (!isEarned)
                  Positioned.fill(
                    child: ClipOval(
                      child: Container(color: cs.surface.withValues(alpha: 0.4)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              badge.badge.name,
              style: context.theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              badge.badge.description,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isEarned) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: badge.progress,
                backgroundColor: cs.outlineVariant?.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Text(
                '${(badge.progress * 100).toStringAsFixed(0)}%',
                style: context.theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
