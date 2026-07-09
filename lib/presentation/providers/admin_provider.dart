import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(supabase: Supabase.instance.client);
});

class AdminState {
  final DashboardStats? stats;
  final List<UserModel> users;
  final List<PostModel> posts;
  final List<ReportItem> reports;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.stats,
    this.users = const [],
    this.posts = const [],
    this.reports = const [],
    this.isLoading = false,
    this.error,
  });
}

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminRepository _repo;

  AdminNotifier(this._repo) : super(const AdminState());

  Future<void> loadStats() async {
    state = const AdminState(isLoading: true);
    try {
      final stats = await _repo.getStats(); // admin check inside repo
      state = AdminState(stats: stats);
    } catch (e) {
      state = AdminState(error: e.toString());
    }
  }

  Future<void> loadUsers({String? search}) async {
    state = const AdminState(isLoading: true);
    try {
      final users = await _repo.getAllUsers(search: search);
      state = AdminState(users: users);
    } catch (e) {
      state = AdminState(error: e.toString());
    }
  }

  Future<void> loadPosts({String? search}) async {
    state = const AdminState(isLoading: true);
    try {
      final posts = await _repo.getAllPosts(search: search);
      state = AdminState(posts: posts);
    } catch (e) {
      state = AdminState(error: e.toString());
    }
  }

  Future<void> loadReports() async {
    state = const AdminState(isLoading: true);
    try {
      final reports = await _repo.getReports(); // admin check inside repo
      state = AdminState(reports: reports);
    } catch (e) {
      state = AdminState(error: e.toString());
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _repo.deletePost(postId); // admin check inside repo
      state = AdminState(posts: state.posts.where((p) => p.id != postId).toList());
    } catch (e) {
      state = AdminState(error: e.toString());
    }
  }

  Future<void> resolveReport(String reportId, String status) async {
    try {
      await _repo.updateReportStatus(reportId, status); // admin check inside repo
      await loadReports();
    } catch (e) {
      state = AdminState(error: e.toString());
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref.watch(adminRepositoryProvider));
});
