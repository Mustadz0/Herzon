import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../providers/follow_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/block_provider.dart';
import '../../data/repositories/follow_repository.dart';
import '../widgets/post_card.dart';
import '../widgets/xp_level_badge.dart';
import '../../data/models/post_model.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  List<PostModel> _posts = [];
  bool _isLoading = true;
  int _postCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationProvider.notifier).loadUserStats(widget.userId);
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await Supabase.instance.client
          .from('profiles').select().eq('id', widget.userId).single();
      final posts = await Supabase.instance.client.rpc('get_user_posts',
        params: {'target_user_id': widget.userId, 'page': 1, 'page_size': 50});
      await _refreshCounts();
      await ref.read(gamificationProvider.notifier).loadUserStats(widget.userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _posts = (posts as List).map((p) => PostModel(
            id: p['id'], userId: p['user_id'], content: p['content'],
            mediaUrls: List<String>.from(p['media_urls'] ?? []),
            mediaType: p['media_type'] == 'image' ? MediaType.image : MediaType.text,
            latitude: 0, longitude: 0,
            contextTag: p['context_tag'],
            reactionCounts: Map<String, int>.from(p['reaction_counts'] ?? {}),
            createdAt: p['created_at'] != null ? DateTime.parse(p['created_at'] as String) : null,
            userUsername: p['username'], userDisplayName: p['display_name'], userAvatarUrl: p['avatar_url'],
            distanceMeters: 0, commentCount: (p['comment_count'] as num?)?.toInt() ?? 0,
          )).toList();
          _postCount = _posts.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Refresh only follower/following counts (cheap, called after follow/unfollow)
  Future<void> _refreshCounts() async {
    final followRepo = ref.read(followRepositoryProvider);
    final fc = await followRepo.getFollowerCount(widget.userId);
    final fwc = await followRepo.getFollowingCount(widget.userId);
    if (mounted) {
      setState(() {
        _followerCount = fc;
        _followingCount = fwc;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final followState = ref.watch(followProvider(widget.userId));
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnProfile = currentUser?.id == widget.userId;

    // Reactive: refresh counts whenever follow state changes (optimistic smooth UX)
    ref.listen<FollowState>(followProvider(widget.userId), (prev, next) {
      if (prev?.isFollowing != next.isFollowing && !next.isLoading) {
        _refreshCounts();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(_profile?['display_name'] ?? 'Profil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 96, height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.brandGradient,
                              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: _profile?['avatar_url'] != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(48),
                                    child: Image.network(_profile!['avatar_url'] as String, fit: BoxFit.cover))
                                : const Icon(Icons.person, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Text(_profile?['display_name'] ?? 'Utilisateur',
                            style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          if (_profile?['bio'] != null) ...[
                            const SizedBox(height: 6),
                            Text(_profile!['bio'] as String,
                              textAlign: TextAlign.center,
                              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                          ],
                          const SizedBox(height: 24),
                          // Stats card -- use FittedBox to avoid horizontal overflow on small screens
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            decoration: BoxDecoration(
                              color: t.isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _statItem(value: '$_postCount', label: 'Posts', t: t)),
                                Container(width: 1, height: 32,
                                  color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                 Expanded(child: _statItem(value: '$_followerCount', label: 'Fans', t: t)),
                                Container(width: 1, height: 32,
                                  color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                Expanded(child: _statItem(value: '$_followingCount', label: 'Cercle', t: t)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // XP / Level card
                          Consumer(builder: (context, ref, _) {
                            final gamification = ref.watch(gamificationProvider);
                            final level = gamification.userLevel;
                            return XpLevelBadge(
                              level: level?.level ?? 0,
                              xp: level?.xp ?? 0,
                              nextXp: level?.nextLevelXp ?? 100,
                              progressPercent: level?.progressPercent ?? 0,
                            );
                          }),
                          if (!isOwnProfile) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: followState.isLoading ? null : () {
                                  if (followState.isFollowing) {
                                    ref.read(followProvider(widget.userId).notifier).unfollow();
                                  } else {
                                    ref.read(followProvider(widget.userId).notifier).follow();
                                  }
                                },
                                icon: Icon(
                                  followState.isLoading
                                    ? Icons.hourglass_top_rounded
                                    : (followState.isFollowing ? Icons.check_circle_rounded : Icons.person_add_alt_1_rounded),
                                  size: 18,
                                ),
                                label: Text(followState.isLoading
                                  ? 'Chargementâ€¦'
                                  : (followState.isFollowing ? 'Dans mon Cercle' : 'Rejoindre le Cercle')),
                                style: FilledButton.styleFrom(
                                  backgroundColor: followState.isFollowing
                                    ? AppTheme.accent.withValues(alpha: 0.15)
                                    : null,
                                  foregroundColor: followState.isFollowing
                                    ? AppTheme.accent
                                    : null,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Consumer(builder: (context, ref, _) {
                                    final blockedIds = ref.watch(blockProvider.select((s) => s.blockedUsers));
                                    final isBlocked = blockedIds.contains(widget.userId);
                                    final isLoading = ref.watch(blockProvider).isLoading;
                                    return OutlinedButton.icon(
                                      onPressed: isLoading ? null : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        if (isBlocked) {
                                          await ref.read(blockProvider.notifier).unblockUser(widget.userId);
                                          if (mounted) {
                                            messenger.showSnackBar(const SnackBar(
                                              content: Text('Utilisateur dÃ©bloquÃ©'),
                                              behavior: SnackBarBehavior.floating,
                                              duration: Duration(seconds: 2),
                                          ));
                                          }
                                        } else {
                                          await ref.read(blockProvider.notifier).blockUser(widget.userId, null);
                                          if (mounted) {
                                            messenger.showSnackBar(SnackBar(
                                              content: const Text('Utilisateur bloquÃ©'),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 2),
                                              action: SnackBarAction(
                                                label: 'Annuler',
                                                onPressed: () => ref.read(blockProvider.notifier).unblockUser(widget.userId),
                                              ),
                                          ));
                                          }
                                        }
                                      },
                                      icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 16),
                                      label: Text(isBlocked ? 'DÃ©bloquer' : 'Bloquer'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isBlocked ? AppTheme.success : AppTheme.error,
                                        side: BorderSide(color: isBlocked ? AppTheme.success : AppTheme.error.withValues(alpha: 0.4)),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: 'profil:${widget.userId}'));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Profil copiÃ©'), 
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ));
                                    },
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text('Partager'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => PostCard(post: _posts[index]),
                      childCount: _posts.length,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statItem({required String value, required String label, required ThemeData t}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
            maxLines: 1,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 2),
        Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
