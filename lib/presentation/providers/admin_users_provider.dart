// Fix: AdminUsersNotifier استخدم SupabaseClient مباشرة — الآن عبر AdminRepository.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_provider.dart' show adminRepositoryProvider;

class AdminUsersState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  const AdminUsersState({
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

  AdminUsersNotifier(this._repo) : super(const AdminUsersState()) {
    loadUsers();
  }

  Future<void> loadUsers({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.getAllUsers(search: search);
      if (mounted) {
        state = state.copyWith(
          users: users,
          isLoading: false,
          searchQuery: search,
        );
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleAdmin(String userId, bool isAdmin) async {
    try {
      await _repo.setUserAdmin(userId, isAdmin);
      await loadUsers(search: state.searchQuery);
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleVibes(String userId, bool canUseVibes) async {
    try {
      await _repo.setUserVibes(userId, canUseVibes);
      await loadUsers(search: state.searchQuery);
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(ref.watch(adminRepositoryProvider));
});
