import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../providers/follow_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/block_provider.dart';
import '../../core/utils/firebase_uuid.dart';
import '../../data/repositories/follow_repository.dart';
import '../widgets/post_card.dart';
import '../widgets/xp_level_badge.dart';
import '../../data/models/post_model.dart';
import 'conversation_screen.dart';

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
  late final String _uuid = widget.userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationProvider.notifier).loadUserStats(_uuid);
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _uuid)
          .single();
      final posts = await Supabase.instance.client.rpc(
        'get_user_posts',
        params: {
          'target_user_id': _uuid,
          'page': 1,
          'page_size': 50,
        },
      );
      await _refreshCounts();
      await ref
          .read(gamificationProvider.notifier)
          .loadUserStats(_uuid);

      if (mounted) {
        setState(() {
          _profile = profile;
          _posts = (posts as List)
              .map((p) => PostModel(
                    id: p['id'],
                    userId: p['user_id'],
                    content: p['content'],
                    mediaUrls:
                        List<String>.from(p['media_urls'] ?? []),
                    mediaType: p['media_type'] == 'image'
                        ? MediaType.image
                        : MediaType.text,
                    latitude: 0,
                    longitude: 0,
                    contextTag: p['context_tag'],
                    reactionCounts: Map<String, int>.from(
                        p['reaction_counts'] ?? {}),
                    createdAt: p['created_at'] != null
                        ? DateTime.parse(p['created_at'] as String)
                        : null,
                    userUsername: p['username'],
                    userDisplayName: p['display_name'],
                    userAvatarUrl: p['avatar_url'],
                    distanceMeters: 0,
                    commentCount:
                        (p['comment_count'] as num?)?.toInt() ?? 0,
                  ))
              .toList();
          _postCount = _posts.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCounts() async {
    final followRepo = ref.read(followRepositoryProvider);
    final fc = await followRepo.getFollowerCount(_uuid);
    final fwc = await followRepo.getFollowingCount(_uuid);
    if (mounted) {
      setState(() {
        _followerCount = fc;
        _followingCount = fwc;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final followState = ref.watch(followProvider(_uuid));
    final fbUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = fbUser != null && FirebaseUuid.toUuid(fbUser.uid) == widget.userId;

    ref.listen<FollowState>(followProvider(_uuid), (prev, next) {
      if (prev?.isFollowing != next.isFollowing && !next.isLoading) {
        _refreshCounts();
      }
    });

    return Scaffold(
      appBar: AppBar(
          title: Text(_profile?['display_name'] ?? 'Profil')),
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

                          // Avatar
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.brandGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: _profile?['avatar_url'] != null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(48),
                                    child: Image.network(
                                      _profile!['avatar_url'] as String,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            _profile?['display_name'] ?? 'Utilisateur',
                            style: tt.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (_profile?['bio'] != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _profile!['bio'] as String,
                              textAlign: TextAlign.center,
                              style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Stats card
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: cs.outlineVariant
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: _StatItem(
                                    value: '$_postCount',
                                    label: 'Posts',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: cs.outlineVariant,
                                ),
                                Expanded(
                                  child: _StatItem(
                                    value: '$_followerCount',
                                    label: 'Fans',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: cs.outlineVariant,
                                ),
                                Expanded(
                                  child: _StatItem(
                                    value: '$_followingCount',
                                    label: 'Cercle',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // XP / Level
                          Consumer(builder: (context, ref, _) {
                            final gamification =
                                ref.watch(gamificationProvider);
                            final level = gamification.userLevel;
                            return XpLevelBadge(
                              level: level?.level ?? 0,
                              xp: level?.xp ?? 0,
                              nextXp: level?.nextLevelXp ?? 100,
                              progressPercent:
                                  level?.progressPercent ?? 0,
                            );
                          }),

                          if (!isOwnProfile) ...[
                            const SizedBox(height: 20),

                            // Follow button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: followState.isLoading
                                    ? null
                                    : () {
                                        if (followState.isFollowing) {
                                          ref
                                              .read(followProvider(
                                                      widget.userId)
                                                  .notifier)
                                              .unfollow();
                                        } else {
                                          ref
                                              .read(followProvider(
                                                      widget.userId)
                                                  .notifier)
                                              .follow();
                                        }
                                      },
                                icon: Icon(
                                  followState.isLoading
                                      ? Icons.hourglass_top_rounded
                                      : (followState.isFollowing
                                          ? Icons.check_circle_rounded
                                          : Icons
                                              .person_add_alt_1_rounded),
                                  size: 18,
                                ),
                                label: Text(
                                  followState.isLoading
                                      ? 'Chargement…'
                                      : (followState.isFollowing
                                          ? 'Dans mon Cercle'
                                          : 'Rejoindre le Cercle'),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: followState.isFollowing
                                      ? cs.secondary
                                          .withValues(alpha: 0.15)
                                      : null,
                                  foregroundColor: followState.isFollowing
                                      ? cs.secondary
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Message button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                   final userId = widget.userId;
                                   final userName =
                                       _profile?['display_name'] ??
                                           'Utilisateur';
                                   try {
                                     final convId = await Supabase
                                         .instance.client
                                         .rpc(
                                       'get_or_create_conversation',
                                       params: {
                                          'other_user_id': userId
                                      },
                                    );
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ConversationScreen(
                                          conversationId:
                                              convId as String,
                                          otherUserId: widget.userId,
                                          otherUserName: userName,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text('Erreur: $e'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ));
                                  }
                                },
                                icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16),
                                label:
                                    const Text('Envoyer un message'),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Block + Share
                            Row(
                              children: [
                                Expanded(
                                  child: Consumer(
                                    builder: (context, ref, _) {
                                      final blockedIds =
                                          ref.watch(blockProvider.select(
                                              (s) => s.blockedUsers));
                                      final isBlocked = blockedIds
                                          .contains(widget.userId);
                                      final isLoading = ref
                                          .watch(blockProvider)
                                          .isLoading;
                                      return OutlinedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () async {
                                                final messenger =
                                                    ScaffoldMessenger.of(
                                                        context);
                                                if (isBlocked) {
                                                  await ref
                                                      .read(blockProvider
                                                          .notifier)
                                                      .unblockUser(
                                                          widget.userId);
                                                  if (mounted) {
                                                    messenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Utilisateur débloqué'),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                } else {
                                                  await ref
                                                      .read(blockProvider
                                                          .notifier)
                                                      .blockUser(
                                                          widget.userId,
                                                          null);
                                                  if (mounted) {
                                                    messenger.showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                            'Utilisateur bloqué'),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        duration:
                                                            const Duration(
                                                                seconds: 2),
                                                        action: SnackBarAction(
                                                          label: 'Annuler',
                                                          onPressed: () => ref
                                                              .read(blockProvider
                                                                  .notifier)
                                                              .unblockUser(
                                                                  widget
                                                                      .userId),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                        icon: Icon(
                                          isBlocked
                                              ? Icons.lock_open_rounded
                                              : Icons.block_rounded,
                                          size: 16,
                                        ),
                                        label: Text(isBlocked
                                            ? 'Débloquer'
                                            : 'Bloquer'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isBlocked
                                              ? cs.tertiary
                                              : cs.error,
                                          side: BorderSide(
                                            color: isBlocked
                                                ? cs.tertiary
                                                    .withValues(alpha: 0.6)
                                                : cs.error
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                          text:
                                              'profil:${widget.userId}'));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Profil copié'),
                                          behavior:
                                              SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.share,
                                        size: 16),
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
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: tt.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
