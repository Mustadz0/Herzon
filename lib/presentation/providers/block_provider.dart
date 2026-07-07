import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/block_repository.dart';

class BlockState {
  final List<String> blockedUsers;
  final bool isLoading;
  final String? error;

  const BlockState({
    this.blockedUsers = const [],
    this.isLoading = false,
    this.error,
  });

  BlockState copyWith({
    List<String>? blockedUsers,
    bool? isLoading,
    String? error,
  }) {
    return BlockState(
      blockedUsers: blockedUsers ?? this.blockedUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BlockNotifier extends StateNotifier<BlockState> {
  final IBlockRepository _repo;

  BlockNotifier(this._repo) : super(const BlockState()) {
    _init();
  }

  Future<void> _init() async {
    await loadBlockedUsers();
  }

  Future<void> blockUser(String blockedId, String? reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.blockUser(blockedId, reason);
      final blockedIds = List<String>.from(state.blockedUsers)..add(blockedId);
      state = BlockState(blockedUsers: blockedIds);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> unblockUser(String blockedId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.unblockUser(blockedId);
      final blockedIds = state.blockedUsers.where((id) => id != blockedId).toList();
      state = BlockState(blockedUsers: blockedIds);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadBlockedUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getBlockedUserIds();
      state = BlockState(blockedUsers: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final blockProvider = StateNotifierProvider<BlockNotifier, BlockState>((ref) {
  return BlockNotifier(ref.watch(blockRepositoryProvider));
});
