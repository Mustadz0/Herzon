import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/follow_repository.dart';

class FollowState {
  final bool isFollowing;
  final bool isLoading;
  final String? error;

  const FollowState({this.isFollowing = false, this.isLoading = false, this.error});
}

class FollowNotifier extends StateNotifier<FollowState> {
  final IFollowRepository _repo;
  final String _targetUserId;

  FollowNotifier(this._repo, this._targetUserId) : super(const FollowState()) {
    _check();
  }

  Future<void> _check() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final following = await _repo.isFollowing(user.id, _targetUserId);
      state = FollowState(isFollowing: following);
    } catch (e) {
      state = FollowState(isFollowing: false, error: e.toString());
    }
  }

  Future<void> follow() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    state = const FollowState(isFollowing: true, isLoading: true);
    try {
      await _repo.follow(user.id, _targetUserId);
      state = const FollowState(isFollowing: true);
    } catch (e) {
      state = FollowState(isFollowing: false, error: e.toString());
    }
  }

  Future<void> unfollow() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    state = const FollowState(isFollowing: false, isLoading: true);
    try {
      await _repo.unfollow(user.id, _targetUserId);
      state = const FollowState(isFollowing: false);
    } catch (e) {
      state = FollowState(isFollowing: true, error: e.toString());
    }
  }
}

final followProvider = StateNotifierProvider.family<FollowNotifier, FollowState, String>(
  (ref, targetUserId) => FollowNotifier(ref.watch(followRepositoryProvider), targetUserId),
);
