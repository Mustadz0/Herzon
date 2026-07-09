import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

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
  final SupabaseClient _supabase;

  AdminUsersNotifier(this._supabase) : super(AdminUsersState()) {
    loadUsers();
  }

  Future<void> loadUsers({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      var query = _supabase.from('profiles').select();
      if (search != null && search.isNotEmpty) {
        final sanitized = search.replaceAll(RegExp(r'[%_]'), r'\\$&');
        query = query.or('display_name.ilike.%$sanitized%,username.ilike.%$sanitized%');
      }
      final data = await query.order('created_at', ascending: false);
      final users = data.map((json) => UserModel.fromJson(json)).toList();
      state = state.copyWith(users: users, isLoading: false, searchQuery: search);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleAdmin(String userId, bool isAdmin) async {
    try {
      await _supabase.rpc('admin_set_user_admin', params: {
        'target_user_id': userId,
        'make_admin': isAdmin,
      });
      await loadUsers(search: state.searchQuery);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleVibes(String userId, bool canUseVibes) async {
    try {
      await _supabase.rpc('admin_set_user_vibes', params: {
        'target_user_id': userId,
        'can_use_vibes_value': canUseVibes,
      });
      await loadUsers(search: state.searchQuery);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(Supabase.instance.client);
});
