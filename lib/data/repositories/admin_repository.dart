import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class ReportItem {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? postId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? reporterName;
  final String? reportedUserName;

  const ReportItem({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.postId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporterName,
    this.reportedUserName,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedUserId: json['reported_user_id'] as String,
      postId: json['post_id'] as String?,
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reporterName: json['reporter_name'] as String?,
      reportedUserName: json['reported_user_name'] as String?,
    );
  }
}

class DashboardStats {
  final int totalUsers;
  final int totalPosts;
  final int pendingReports;
  final int activeUsersToday;
  final List<Map<String, dynamic>> postsLast7Days;
  final List<Map<String, dynamic>> topZones;

  const DashboardStats({
    required this.totalUsers,
    required this.totalPosts,
    required this.pendingReports,
    required this.activeUsersToday,
    this.postsLast7Days = const [],
    this.topZones = const [],
  });
}

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository({required SupabaseClient supabase}) : _supabase = supabase;

  Future<DashboardStats> getStats() async {
    final result = await _supabase.rpc('admin_get_stats');
    final data = result as Map<String, dynamic>;
    return DashboardStats(
      totalUsers: (data['total_users'] as num?)?.toInt() ?? 0,
      totalPosts: (data['total_posts'] as num?)?.toInt() ?? 0,
      pendingReports: (data['pending_reports'] as num?)?.toInt() ?? 0,
      activeUsersToday: (data['active_today'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<UserModel>> getAllUsers({String? search}) async {
    final data = await _supabase.rpc('admin_get_users', params: {
      'search_term': search,
    }) as List<dynamic>;
    return data.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<PostModel>> getAllPosts({String? search}) async {
    final data = await _supabase.rpc('admin_get_posts', params: {
      'search_term': search,
    }) as List<dynamic>;
    return data.map((json) {
      final j = json as Map<String, dynamic>;
      final profile = j['profiles'] as Map<String, dynamic>?;
      final coords = ((j['location'] as Map<String, dynamic>?)?['coordinates'] as List?)?.cast<num>();
      return PostModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        content: j['content'] as String,
        latitude: coords?.lastOrNull?.toDouble() ?? 0.0,
        longitude: coords?.firstOrNull?.toDouble() ?? 0.0,
        contextTag: j['context_tag'] as String?,
        reactionCounts: j['reaction_counts'] != null ? Map<String, int>.from(j['reaction_counts'] as Map) : const {},
        userUsername: profile?['username'] as String?,
        userDisplayName: profile?['display_name'] as String?,
        userAvatarUrl: profile?['avatar_url'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
        commentCount: 0,
      );
    }).toList();
  }

  Future<List<ReportItem>> getReports() async {
    final data = await _supabase.rpc('admin_get_reports') as List<dynamic>;
    return data.map((json) => ReportItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _supabase.rpc('admin_update_report_status', params: {
      'target_report_id': reportId,
      'new_status': status,
    });
  }

  Future<void> deletePost(String postId) async {
    await _supabase.rpc('admin_delete_post', params: {'target_post_id': postId});
  }

  Future<void> toggleAdmin({required String userId, required bool isAdmin}) async {
    await _supabase.rpc('admin_set_user_admin', params: {
      'target_user_id': userId,
      'make_admin': isAdmin,
    });
  }

  Future<void> toggleVibes({required String userId, required bool canUseVibes}) async {
    await _supabase.rpc('admin_set_user_vibes', params: {
      'target_user_id': userId,
      'can_use_vibes_value': canUseVibes,
    });
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(supabase: Supabase.instance.client);
});
