import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firebase_uuid.dart';
import '../providers/follow_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/block_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/xp_level_badge.dart';
import 'conversation_screen.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider(userId));
    final followState  = ref.watch(followProvider(userId));
    final gamification = ref.watch(gamificationProvider);

    // FIX: FirebaseAuth + UUID بدل Supabase.auth
    final firebaseUid   = FirebaseAuth.instance.currentUser?.uid;
    final currentUserId = firebaseUid != null ? FirebaseUuid.toUuid(firebaseUid) : null;
    final isOwnProfile  = currentUserId == userId;

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen<ProfileState>(profileProvider(userId), (prev, next) {
      if (prev?.isLoading == true && next.isLoading == false && next.error == null) {
        ref.read(gamificationProvider.notifier).loadUserStats(userId);
      }
    });

    ref.listen<FollowState>(followProvider(userId), (prev, next) {
      if (prev?.isFollowing != next.isFollowing && !next.isLoading) {
        ref.read(profileProvider(userId).notifier).refreshCounts();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(profileState.profile?.displayName ?? 'Profil'),
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: cs.error),
                      const SizedBox(height: 12),
                      Text(profileState.error!, style: TextStyle(color: cs.error)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.read(profileProvider(userId).notifier).load(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(profileProvider(userId).notifier).load(),
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
                                width: 96, height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.brandGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: profileState.profile?.avatarUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(48),
                                        child: Image.network(
                                          profileState.profile!.avatarUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 48, color: Colors.white),
                              ),
                              const SizedBox(height: 20),

                              // Name / Bio
                              Text(
                                profileState.profile?.displayName ?? 'Utilisateur',
                                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (profileState.profile?.bio != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  profileState.profile!.bio!,
                                  textAlign: TextAlign.center,
                                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Stats card
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: _StatItem(
                                        value: '${profileState.posts.length}',
                                        label: 'Posts',
                                      ),
                                    ),
                                    Container(width: 1, height: 32, color: cs.outlineVariant),
                                    Expanded(
                                      child: _StatItem(
                                        value: '${profileState.followerCount}',
                                        label: 'Fans',
                                      ),
                                    ),
                                    Container(width: 1, height: 32, color: cs.outlineVariant),
                                    Expanded(
                                      child: _StatItem(
                                        value: '${profileState.followingCount}',
                                        label: 'Cercle',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // XP / Level
                              XpLevelBadge(
                                level: gamification.userLevel?.level ?? 0,
                                xp: gamification.userLevel?.xp ?? 0,
                                nextXp: gamification.userLevel?.nextLevelXp ?? 100,
                                progressPercent: gamification.userLevel?.progressPercent ?? 0,
                              ),

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
                                              ref.read(followProvider(userId).notifier).unfollow();
                                            } else {
                                              ref.read(followProvider(userId).notifier).follow();
                                            }
                                          },
                                    icon: Icon(
                                      followState.isLoading
                                          ? Icons.hourglass_top_rounded
                                          : followState.isFollowing
                                              ? Icons.check_circle_rounded
                                              : Icons.person_add_alt_1_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      followState.isLoading
                                          ? 'Chargement…'
                                          : followState.isFollowing
                                              ? 'Dans mon Cercle'
                                              : 'Rejoindre le Cercle',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: followState.isFollowing
                                          ? cs.secondary.withValues(alpha: 0.15)
                                          : null,
                                      foregroundColor: followState.isFollowing ? cs.secondary : null,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Message button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final userName = profileState.profile?.displayName ?? 'Utilisateur';
                                      try {
                                        // FIX: pass current user UUID for RPC
                                        final convId = await Supabase.instance.client.rpc(
                                          'get_or_create_conversation',
                                          params: {'other_user_id': userId},
                                        );
                                        if (!context.mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ConversationScreen(
                                              conversationId: convId as String,
                                              otherUserId: userId,
                                              otherUserName: userName,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erreur: $e'),
                                            behavior: SnackBarBehavior.floating));
                                      }
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                    label: const Text('Envoyer un message'),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Block + Share
                                Row(
                                  children: [
                                    Expanded(
                                      child: Consumer(
                                        builder: (context, ref, _) {
                                          final blockedIds = ref.watch(
                                              blockProvider.select((s) => s.blockedUsers));
                                          final isBlocked = blockedIds.contains(userId);
                                          final isBlockLoading = ref.watch(blockProvider).isLoading;
                                          return OutlinedButton.icon(
                                            onPressed: isBlockLoading
                                                ? null
                                                : () async {
                                                    final messenger = ScaffoldMessenger.of(context);
                                                    if (isBlocked) {
                                                      await ref.read(blockProvider.notifier).unblockUser(userId);
                                                      if (context.mounted) {
                                                        messenger.showSnackBar(const SnackBar(
                                                          content: Text('Utilisateur débloqué'),
                                                          behavior: SnackBarBehavior.floating,
                                                          duration: Duration(seconds: 2),
                                                        ));
                                                      }
                                                    } else {
                                                      await ref.read(blockProvider.notifier).blockUser(userId, null);
                                                      if (context.mounted) {
                                                        messenger.showSnackBar(SnackBar(
                                                          content: const Text('Utilisateur bloqué'),
                                                          behavior: SnackBarBehavior.floating,
                                                          duration: const Duration(seconds: 2),
                                                          action: SnackBarAction(
                                                            label: 'Annuler',
                                                            onPressed: () => ref
                                                                .read(blockProvider.notifier)
                                                                .unblockUser(userId),
                                                          ),
                                                        ));
                                                      }
                                                    }
                                                  },
                                            icon: Icon(
                                              isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                                              size: 16,
                                            ),
                                            label: Text(isBlocked ? 'Débloquer' : 'Bloquer'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: isBlocked ? cs.tertiary : cs.error,
                                              side: BorderSide(
                                                color: isBlocked
                                                    ? cs.tertiary.withValues(alpha: 0.6)
                                                    : cs.error.withValues(alpha: 0.4),
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
                                          Clipboard.setData(ClipboardData(text: 'profil:$userId'));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Profil copié'),
                                              behavior: SnackBarBehavior.floating,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
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

                      // Posts list
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => PostCard(post: profileState.posts[index]),
                          childCount: profileState.posts.length,
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
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
