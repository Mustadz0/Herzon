import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/story_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/checkin_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_circle_row.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'explorer_screen.dart';
import '../../core/theme/app_theme.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  bool _showTop = false;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(postProvider.notifier).loadFeed();
      ref.read(storyProvider.notifier).loadStories();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Je suis là — check-in with location ──────────────────────
  Future<void> _jesuisLa() async {
    if (_isCheckingIn) return;
    setState(() => _isCheckingIn = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation requise'),
              behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _StaggerEntry extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerEntry({required this.index, required this.child});

  @override
  State<_StaggerEntry> createState() => _StaggerEntryState();
}

class _StaggerEntryState extends State<_StaggerEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: (widget.index * 60).clamp(0, 600)),
        () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // checkinProvider uses: checkin(placeName, lat, lng)
      await ref.read(checkinProvider.notifier).checkin(
            'La Zone',
            position.latitude,
            position.longitude,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-in réussi ! +10 XP'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        ref.read(postProvider.notifier).loadFeed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur check-in: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  // ─── build ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedState = ref.watch(postProvider);
    final unread = ref.watch(notificationProvider).unreadCount;

    // Use visiblePosts (excludes hidden)
    final rawPosts = feedState.visiblePosts;
    final List<PostModel> posts;
    if (_showTop) {
      posts = List<PostModel>.of(rawPosts);
      posts.sort((a, b) {
        final aScore =
            (a.reactionCounts['herz'] ?? 0) + (a.commentCount * 2);
        final bScore =
            (b.reactionCounts['herz'] ?? 0) + (b.commentCount * 2);
        return bScore.compareTo(aScore);
      });
    } else {
      posts = rawPosts;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: RefreshIndicator(
          color: cs.primary,
          onRefresh: () async {
            await ref.read(postProvider.notifier).loadFeed();
            await ref.read(storyProvider.notifier).loadStories();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── SliverAppBar ──────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: true,
                expandedHeight: 0,
                backgroundColor:
                    isDark ? AppTheme.navDark : AppTheme.navLight,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: const SizedBox.expand(),
                  ),
                ),
                title: ShaderMask(
                  shaderCallback: (b) =>
                      AppTheme.brandGradient.createShader(b),
                  child: Text(
                    'Herzon',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.search_rounded, color: cs.onSurface),
                    tooltip: 'Search',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SearchScreen()),
                    ),
                  ),
                  IconButton(
                    icon: Badge(
                      label: unread > 0 ? Text('$unread') : null,
                      isLabelVisible: unread > 0,
                      backgroundColor: cs.error,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: cs.onSurface,
                      ),
                    ),
                    tooltip: 'Notifications',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              // ── Zone bar ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _GradientPill(icon: Icons.whatshot, label: 'Hot'),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ExplorerScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cs.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.near_me,
                                    color: cs.primary, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'La Zone',
                                    style: tt.labelMedium?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${posts.length}',
                                    style: tt.labelSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _isCheckingIn ? null : _jesuisLa,
                        icon: _isCheckingIn
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Icon(Icons.my_location,
                                size: 14, color: cs.primary),
                        label: Text(
                          'Je suis là',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          side: BorderSide(
                              color:
                                  cs.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recent / Top toggle ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _PillToggle(
                        showTop: _showTop,
                        onChanged: (v) => setState(() => _showTop = v),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stories ───────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: StoryCircleRow(),
                ),
              ),

              // ── Section header ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _showTop
                            ? 'Les plus populaires'
                            : 'Ce qui se passe',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Feed content ──────────────────────────────
              if (feedState.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => _shimmerCard(cs),
                    childCount: 3,
                  ),
                )
              else if (feedState.error != null)
                SliverToBoxAdapter(
                    child: _errorState(feedState.error!, cs, tt))
              else if (posts.isEmpty)
                SliverToBoxAdapter(child: _emptyState(cs, tt))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _StaggerEntry(
                      index: i,
                      child: PostCard(post: posts[i]),
                    ),
                    childCount: posts.length,
                  ),
                ),

              if (feedState.isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 280,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _errorState(String error, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text('Erreur',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(error,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => ref.read(postProvider.notifier).loadFeed(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.near_me_disabled,
                size: 44, color: cs.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text('Rien dans la zone',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Soyez le premier à publier !',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreatePostScreen()),
              );
              if (created == true) {
                ref.read(postProvider.notifier).loadFeed();
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Créer un post'),
          ),
        ],
      ),
    );
  }
}

// ─── Gradient Pill ────────────────────────────────────────────
class _GradientPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GradientPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Pill Toggle (Récent / Top) ──────────────────────────────
class _PillToggle extends StatelessWidget {
  final bool showTop;
  final ValueChanged<bool> onChanged;
  const _PillToggle({required this.showTop, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill('Récent', !showTop, cs, tt, () => onChanged(false)),
          _pill('Top', showTop, cs, tt, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _pill(String label, bool selected, ColorScheme cs, TextTheme tt,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.brandGradient : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: tt.labelMedium?.copyWith(
            color: selected ? Colors.white : cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
