import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/checkin_provider.dart';
import '../../data/repositories/follow_repository.dart';
import '../../services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firebase_uuid.dart';
import 'feed_screen.dart';
import 'explorer_screen.dart';
import 'create_post_screen.dart';
import 'notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'search_screen.dart';
import 'leaderboard_screen.dart';
import 'badges_screen.dart';
import 'ride_sharing_screen.dart';
import 'settings_screen.dart';
import 'page_list_screen.dart';
import 'admin_feature_flags_screen.dart';
import 'vibes/vibe_viewer_screen.dart';
import 'messages_screen.dart';
import '../widgets/xp_level_badge.dart';
import '../widgets/conversations_list_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 0=Feed  1=Explorer  2=Vibes  3=Notifs  4=Profil
  // Le bouton "+" central (index -1) est un FAB hors IndexedStack
  int _currentIndex = 0;

  void _openFloatingMessages() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: const Color(0xFF121212),
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => AppTheme.brandGradient.createShader(b),
                        child: const Text(
                          'Messages',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                // Messages list
                Expanded(
                  child: ConversationsListWidget(scrollController: scrollCtrl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final auth = ref.watch(authProvider);
    final notifState = ref.watch(notificationProvider);
    final unreadCount = notifState.unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const FeedScreen(),                                              // 0 Feed
          const ExplorerScreen(),                                          // 1 Explorer
          const VibeViewerScreen(),                                        // 2 Vibes
          const NotificationsScreen(),                                     // 3 Notifs
          _ProfileTab(user: auth.user, unreadCount: unreadCount),         // 4 Profil
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: (t.isDark ? AppTheme.navDark : AppTheme.navLight),
              border: Border(
                top: BorderSide(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              boxShadow: AppTheme.glassShadowHeavy,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 0 Feed
                    _NavItem(
                      index: 0,
                      icon: Icons.dynamic_feed_outlined,
                      activeIcon: Icons.dynamic_feed,
                      label: 'Feed',
                      currentIndex: _currentIndex,
                      onTap: _onTap,
                    ),
                    // 1 Explorer
                    _NavItem(
                      index: 1,
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore,
                      label: 'Explorer',
                      currentIndex: _currentIndex,
                      onTap: _onTap,
                    ),
                    // FAB Centre — Créer un post
                    _CenterFab(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                      ),
                    ),
                    // 2 Vibes
                    _NavItem(
                      index: 2,
                      icon: Icons.play_circle_outline,
                      activeIcon: Icons.play_circle,
                      label: 'Vibes',
                      currentIndex: _currentIndex,
                      onTap: _onTap,
                    ),
                    // Messages — floating window (pas dans IndexedStack)
                    _NavItem(
                      index: -1,
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Messages',
                      currentIndex: _currentIndex,
                      onTap: (_) => _openFloatingMessages(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int i) {
    setState(() => _currentIndex = i);
  }
}

// ─────────────────────────────────────────────
// Nav Item
// ─────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = index >= 0 && index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.brandGradient : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? (activeIcon ?? icon) : icon,
              size: 24,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FAB Centre
// ─────────────────────────────────────────────
class _CenterFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _CenterFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile Tab
// ─────────────────────────────────────────────
class _ProfileTab extends ConsumerStatefulWidget {
  final dynamic user;
  final int unreadCount;
  const _ProfileTab({this.user, this.unreadCount = 0});

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  int _postCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = widget.user?.id as String?;
      if (uid != null) ref.read(gamificationProvider.notifier).loadUserStats(uid);
    });
  }

  Future<void> _loadStats() async {
    final uid = widget.user?.id as String?;
    if (uid == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', uid)
          .maybeSingle();
      if (profile == null) return;
      final fc = await ref.read(followRepositoryProvider).getFollowerCount(uid);
      final fwc = await ref.read(followRepositoryProvider).getFollowingCount(uid);
      final postsCount = await Supabase.instance.client
          .rpc('get_user_posts_count', params: {'target_user_id': uid})
          .maybeSingle();
      if (mounted) {
        setState(() {
          _postCount = postsCount is Map<String, dynamic>
              ? (postsCount.values.first as num?)?.toInt() ?? 0
              : (postsCount as num?)?.toInt() ?? 0;
          _followerCount = fc;
          _followingCount = fwc;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final uid = widget.user?.id as String?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: Badge(
              label: widget.unreadCount > 0 ? Text('${widget.unreadCount}') : null,
              isLabelVisible: widget.unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: widget.user?.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        widget.user!.avatarUrl as String,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              widget.user?.displayName ?? 'Utilisateur',
              style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (widget.user?.bio != null) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                widget.user!.bio,
                style: t.textTheme.bodyMedium?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (uid != null)
            Consumer(builder: (context, ref, _) {
              final gam = ref.watch(gamificationProvider);
              final lv = gam.userLevel;
              if (lv == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: XpLevelBadge(
                  level: lv.level,
                  xp: lv.xp,
                  nextXp: lv.nextLevelXp,
                  progressPercent: lv.progressPercent,
                  compact: false,
                ),
              );
            }),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: t.isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(value: _loadingStats ? '…' : '$_postCount', label: 'Posts', t: t),
                Container(width: 1, height: 32, color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                _statItem(value: _loadingStats ? '…' : '$_followerCount', label: 'Fans', t: t),
                Container(width: 1, height: 32, color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                _statItem(value: _loadingStats ? '…' : '$_followingCount', label: 'Cercle', t: t),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.user != null
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: widget.user),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Modifier le profil'),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.user?.isAdmin == true)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin'),
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: const Text('Administration'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ),
          if (widget.user?.isAdmin == true) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              icon: const Icon(Icons.logout, size: 18, color: Colors.red),
              label: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Plus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.emoji_events_rounded,
            label: 'Classement',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
          _MenuTile(
            icon: Icons.military_tech_rounded,
            label: 'Badges',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())),
          ),
          _MenuTile(
            icon: Icons.directions_car_rounded,
            label: 'Covoiturage',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RideSharingScreen())),
          ),
          _MenuTile(
            icon: Icons.check_circle_outline,
            label: 'Check-in',
            onTap: () => _showCheckInSheet(context),
          ),
          _MenuTile(
            icon: Icons.flag_outlined,
            label: 'Pages',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PageListScreen())),
          ),
          if (widget.user?.isAdmin == true)
            _MenuTile(
              icon: Icons.tune_rounded,
              label: 'Feature Flags',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminFeatureFlagsScreen()),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showCheckInSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _CheckInSheet(),
    );
  }

  Widget _statItem({required String value, required String label, required ThemeData t}) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _CheckInSheet extends ConsumerWidget {
  const _CheckInSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
              gradient: AppTheme.brandGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Vous êtes à proximité',
            style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Faites un check-in pour gagner des badges et grimper dans le classement !',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                // ✅ Fix: use FirebaseAuth + FirebaseUuid instead of Supabase.auth
                final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
                if (firebaseUid == null) return;
                final uid = FirebaseUuid.toUuid(firebaseUid);
                final loc =
                    await ref.read(locationServiceProvider).initializeLocation();
                await ref
                    .read(checkinProvider.notifier)
                    .checkin('Check-in', loc.latitude, loc.longitude);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Check-in effectué ! +10 XP'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ));
                  ref.read(gamificationProvider.notifier).loadUserStats(uid);
                }
              },
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Check-in maintenant'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: t.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
