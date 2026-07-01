import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../providers/follow_provider.dart';
import '../widgets/post_card.dart';
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
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
      final posts = await Supabase.instance.client.rpc('get_user_posts', params: {'target_user_id': widget.userId, 'page': 1, 'page_size': 50});
      final followerCount = await Supabase.instance.client
          .from('follows')
          .select('count', count: CountOption.exact)
          .eq('following_id', widget.userId);
      final followingCount = await Supabase.instance.client
          .from('follows')
          .select('count', count: CountOption.exact)
          .eq('follower_id', widget.userId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _posts = (posts as List).map((p) => PostModel(
            id: p['id'],
            userId: p['user_id'],
            content: p['content'],
            mediaUrls: List<String>.from(p['media_urls'] ?? []),
            mediaType: p['media_type'] == 'image' ? MediaType.image : MediaType.text,
            latitude: 0, longitude: 0,
            contextTag: p['context_tag'],
            reactionCounts: Map<String, int>.from(p['reaction_counts'] ?? {}),
            createdAt: p['created_at'] != null ? DateTime.parse(p['created_at'] as String) : null,
            userUsername: p['username'],
            userDisplayName: p['display_name'],
            userAvatarUrl: p['avatar_url'],
            distanceMeters: 0,
            commentCount: (p['comment_count'] as num?)?.toInt() ?? 0,
          )).toList();
          _postCount = _posts.length;
          _followerCount = (followerCount as List?)?.length ?? 0;
          _followingCount = (followingCount as List?)?.length ?? 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final followState = ref.watch(followProvider(widget.userId));
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnProfile = currentUser?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?['display_name'] ?? 'Profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: _profile?['avatar_url'] != null
                                ? NetworkImage(_profile!['avatar_url'] as String)
                                : null,
                            backgroundColor: AppTheme.primaryColor,
                            child: _profile?['avatar_url'] == null
                                ? const Icon(Icons.person, size: 48, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profile?['display_name'] ?? 'Utilisateur',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          if (_profile?['bio'] != null) ...[
                            const SizedBox(height: 8),
                            Text(_profile!['bio'] as String, style: TextStyle(color: Colors.grey[600])),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statColumn('$_postCount', 'Posts'),
                              _statColumn('$_followerCount', 'Abonnes'),
                              _statColumn('$_followingCount', 'Abonnements'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!isOwnProfile)
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: followState.isLoading ? null : () {
                                  if (followState.isFollowing) {
                                    ref.read(followProvider(widget.userId).notifier).unfollow();
                                  } else {
                                    ref.read(followProvider(widget.userId).notifier).follow();
                                  }
                                },
                                icon: Icon(followState.isFollowing ? Icons.favorite : Icons.person_add),
                                label: Text(followState.isFollowing ? 'Abonne' : 'Suivre'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: followState.isFollowing ? Colors.grey : null,
                                ),
                              ),
                            ),
                          const Divider(height: 32),
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

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
