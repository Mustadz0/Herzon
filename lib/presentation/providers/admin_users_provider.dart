import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../core/utils/safe_error.dart';

class AdminUsersState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  AdminUsersState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final AdminRepository _repo;

  AdminUsersNotifier(this._repo) : super(AdminUsersState()) {
    loadUsers();
  }

  Future<void> loadUsers({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.getAllUsers(search: search);
      state = state.copyWith(users: users, isLoading: false, searchQuery: search);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: safeErrorMessage(e));
    }
  }

  Future<void> toggleAdmin(String userId, bool isAdmin) async {
    try {
      await _repo.toggleAdmin(userId: userId, isAdmin: isAdmin);
      await loadUsers(search: state.searchQuery);
    } catch (e) {
      state = state.copyWith(error: safeErrorMessage(e));
    }
  }

  Future<void> toggleVibes(String userId, bool canUseVibes) async {
    try {
      await _repo.toggleVibes(userId: userId, canUseVibes: canUseVibes);
      await loadUsers(search: state.searchQuery);
    } catch (e) {
      state = state.copyWith(error: safeErrorMessage(e));
    }
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(ref.watch(adminRepositoryProvider));
});
