import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:herzon/core/theme/app_theme.dart';
import 'package:herzon/data/models/gamification_model.dart';
import 'package:herzon/presentation/widgets/leaderboard_card.dart';
import 'package:herzon/presentation/providers/gamification_provider.dart';
import 'package:herzon/presentation/screens/user_profile_screen.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationProvider.notifier).loadLeaderboard();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      if (userId.isNotEmpty) {
        ref.read(gamificationProvider.notifier).loadUserStats(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final gamState = ref.watch(gamificationProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: Text('Classement',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Actualiser',
                onPressed: () =>
                    ref.read(gamificationProvider.notifier).loadLeaderboard(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: cs.surface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: cs.primary,
                  indicatorWeight: 3,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelStyle:
                      tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'À proximité'),
                    Tab(text: 'Mon niveau'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(gamificationProvider.notifier).loadLeaderboard();
          },
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboard(gamState),
              _buildMyLevel(gamState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard(GamificationState gamState) {
    if (gamState.isLoading && gamState.leaderboard.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final entries = gamState.leaderboard;
    final cs = context.cs;
    final tt = context.tt;

    if (entries.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_rounded,
                  size: 56, color: cs.onPrimary),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Devenez le premier !',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Postez, interagissez, gagnez des XP\net grimpez au sommet.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _Podium(top: top3, gold: _gold, silver: _silver, bronze: _bronze),
        ),
        if (rest.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardGlassLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Soyez le prochain challenger !',
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...rest.map((e) => LeaderboardCard(
                entry: e,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: e.userId),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildMyLevel(GamificationState gamState) {
    final myLevel = gamState.userLevel;
    final cs = context.cs;
    final tt = context.tt;

    if (myLevel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = (myLevel.xp % 100) / 100;
    final xpIntoLevel = myLevel.xp % 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            height: 220,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      backgroundColor: cs.outlineVariant,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.brandGradient,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Nv.',
                            style: tt.labelSmall?.copyWith(
                                color: cs.onPrimary.withValues(alpha: 0.8),
                                letterSpacing: 1)),
                        Text('${myLevel.level}',
                            style: tt.displaySmall?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('${myLevel.xp} XP',
              style: tt.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppTheme.primary)),
          const SizedBox(height: 4),
          Text('$xpIntoLevel / 100 XP vers le niveau ${myLevel.level + 1}',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.accent.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(value: '${myLevel.totalPosts}', label: 'Posts'),
                Container(width: 1, height: 32, color: cs.outlineVariant),
                _Stat(
                    value: '${myLevel.totalReactionsReceived}',
                    label: 'Réactions'),
                Container(width: 1, height: 32, color: cs.outlineVariant),
                _Stat(
                    value: '${myLevel.totalCommentsReceived}',
                    label: 'Commentaires'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _AchievementsGrid(level: myLevel.level),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntryModel> top;
  final Color gold;
  final Color silver;
  final Color bronze;

  const _Podium({
    required this.top,
    required this.gold,
    required this.silver,
    required this.bronze,
  });

  @override
  Widget build(BuildContext context) {
    if (top.isEmpty) return const SizedBox.shrink();

    final r1 = top.isNotEmpty ? top[0] : null;
    final r2 = top.length > 1 ? top[1] : null;
    final r3 = top.length > 2 ? top[2] : null;

    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (r2 != null)
            const Positioned(left: 16, bottom: 0, child: SizedBox.shrink()),
          Positioned(
            left: 16,
            bottom: 0,
            child: r2 == null
                ? const SizedBox.shrink()
                : _PodiumUser(entry: r2, color: silver, height: 120),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: r1 == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.center,
                    child:
                        _PodiumUser(entry: r1, color: gold, height: 160),
                  ),
          ),
          Positioned(
            right: 16,
            bottom: 0,
            child: r3 == null
                ? const SizedBox.shrink()
                : _PodiumUser(entry: r3, color: bronze, height: 90),
          ),
        ],
      ),
    );
  }
}

class _PodiumUser extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final Color color;
  final double height;
  const _PodiumUser(
      {required this.entry, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: entry.userId)),
      ),
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundImage:
                    (entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty)
                        ? NetworkImage(entry.avatarUrl!)
                        : null,
                backgroundColor: cs.surfaceContainerLowest,
                child: entry.avatarUrl == null
                    ? Icon(Icons.person_rounded, color: cs.onSurface)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.displayName ?? entry.username,
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text('${entry.xp} XP',
                style: tt.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              height: height,
              width: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.4)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              alignment: Alignment.center,
              child: Text('${entry.rank}',
                  style: tt.headlineMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return Column(
      children: [
        Text(value,
            style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, color: AppTheme.primary)),
        const SizedBox(height: 4),
        Text(label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final int level;
  const _AchievementsGrid({required this.level});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGlassLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Succès débloqués',
                  style:
                      tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AchievementBadge(
                  emoji: '\u{1F331}', label: 'Nouveau', unlocked: level >= 1),
              _AchievementBadge(
                  emoji: '\u{1F52E}', label: 'Explorateur', unlocked: level >= 5),
              _AchievementBadge(
                  emoji: '\u{1F5FC}', label: 'Ambassadeur', unlocked: level >= 10),
              _AchievementBadge(
                  emoji: '\u{1F451}', label: 'Legende', unlocked: level >= 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final bool unlocked;
  const _AchievementBadge(
      {required this.emoji, required this.label, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked
                ? AppTheme.primary.withValues(alpha: 0.15)
                : cs.surfaceContainerHighest,
            border: Border.all(
              color: unlocked ? AppTheme.primary : cs.outlineVariant,
              width: 2,
            ),
          ),
          child: Opacity(
            opacity: unlocked ? 1 : 0.35,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
