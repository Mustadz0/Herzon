// Fix #5: changed ref.read → ref.watch for repositories so the notifier
// correctly tracks provider updates (e.g., after sign-out/sign-in).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/follow_repository.dart';
import '../../data/repositories/profile_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ProfileState {
  final bool isLoading;
  final ProfileData? profile;
  final List<PostModel> posts;
  final int followerCount;
  final int followingCount;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.posts = const [],
    this.followerCount = 0,
    this.followingCount = 0,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    ProfileData? profile,
    List<PostModel>? posts,
    int? followerCount,
    int? followingCount,
    String? error,
  }) =>
      ProfileState(
        isLoading: isLoading ?? this.isLoading,
        profile: profile ?? this.profile,
        posts: posts ?? this.posts,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount ?? this.followingCount,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  final IProfileRepository _profileRepo;
  final IFollowRepository _followRepo;
  final String userId;

  ProfileNotifier({
    required IProfileRepository profileRepo,
    required IFollowRepository followRepo,
    required this.userId,
  })  : _profileRepo = profileRepo,
        _followRepo = followRepo,
        super(const ProfileState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _profileRepo.getProfile(userId),
        _profileRepo.getUserPosts(userId),
        _followRepo.getFollowerCount(userId),
        _followRepo.getFollowingCount(userId),
      ]);

      final profile = results[0] as ProfileData;
      final posts = results[1] as List<PostModel>;
      final fc = results[2] as int;
      final fwc = results[3] as int;

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          profile: profile,
          posts: posts,
          followerCount: fc,
          followingCount: fwc,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Impossible de charger le profil.',
        );
      }
    }
  }

  Future<void> refreshCounts() async {
    final fc = await _followRepo.getFollowerCount(userId);
    final fwc = await _followRepo.getFollowingCount(userId);
    if (mounted) state = state.copyWith(followerCount: fc, followingCount: fwc);
  }
}

// ── Family provider — Fix #5: ref.watch instead of ref.read ───────────────────

final profileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileState, String>(
  (ref, userId) {
    final notifier = ProfileNotifier(
      profileRepo: ref.watch(profileRepositoryProvider), // Fix #5
      followRepo: ref.watch(followRepositoryProvider),   // Fix #5
      userId: userId,
    );
    notifier.load();
    return notifier;
  },
);
