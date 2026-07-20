// Fix: كل method في AdminNotifier تعيد state من صفر (تمسح users/posts/reports
// الأخرى) — ثم حدّثنا لنستخدم copyWith بدل إنشاء AdminState جديد في كل مرة.
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

  AdminState copyWith({
    DashboardStats? stats,
    List<UserModel>? users,
    List<PostModel>? posts,
    List<ReportItem>? reports,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      stats: stats ?? this.stats,
      users: users ?? this.users,
      posts: posts ?? this.posts,
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminRepository _repo;

  AdminNotifier(this._repo) : super(const AdminState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _repo.getStats();
      if (mounted) state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUsers({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.getAllUsers(search: search);
      if (mounted) state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPosts({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _repo.getAllPosts(search: search);
      if (mounted) state = state.copyWith(posts: posts, isLoading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reports = await _repo.getReports();
      if (mounted) state = state.copyWith(reports: reports, isLoading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _repo.deletePost(postId);
      if (mounted) {
        state = state.copyWith(
          posts: state.posts.where((p) => p.id != postId).toList(),
        );
      }
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resolveReport(String reportId, String status) async {
    try {
      await _repo.updateReportStatus(reportId, status);
      await loadReports();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }
}

final adminProvider =
    StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref.watch(adminRepositoryProvider));
});
