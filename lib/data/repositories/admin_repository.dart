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

  const DashboardStats({
    required this.totalUsers,
    required this.totalPosts,
    required this.pendingReports,
    required this.activeUsersToday,
  });
}

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository({required SupabaseClient supabase}) : _supabase = supabase;

  Future<DashboardStats> getStats() async {
    final userCount = (await _supabase.from('profiles').select('id')).length;
    final postCount = (await _supabase.from('posts').select('id')).length;
    final reportCount = (await _supabase.from('reports').select('id').eq('status', 'pending')).length;
    final activeCount = (await _supabase.from('profiles').select('id').gte('updated_at', DateTime.now().subtract(const Duration(hours: 24)).toIso8601String())).length;

    return DashboardStats(
      totalUsers: userCount,
      totalPosts: postCount,
      pendingReports: reportCount,
      activeUsersToday: activeCount,
    );
  }

  Future<List<UserModel>> getAllUsers({String? search}) async {
    var query = _supabase.from('profiles').select();
    if (search != null && search.isNotEmpty) {
      query = query.or('display_name.ilike.%$search%,username.ilike.%$search%');
    }
    final data = await query.order('created_at', ascending: false);
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<List<PostModel>> getAllPosts({String? search}) async {
    var query = _supabase.from('posts').select('*, profiles!inner(username, display_name, avatar_url)');
    if (search != null && search.isNotEmpty) {
      query = query.ilike('content', '%$search%');
    }
    final data = await query.order('created_at', ascending: false);
    return data.map((json) {
      final profile = json['profiles'] as Map<String, dynamic>?;
      return PostModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        content: json['content'] as String,
        latitude: ((json['location'] as Map<String, dynamic>?)?['coordinates'] as List?)?.last ?? 0.0,
        longitude: ((json['location'] as Map<String, dynamic>?)?['coordinates'] as List?)?.first ?? 0.0,
        contextTag: json['context_tag'] as String?,
        reactionCounts: json['reaction_counts'] != null ? Map<String, int>.from(json['reaction_counts'] as Map) : const {},
        userUsername: profile?['username'] as String?,
        userDisplayName: profile?['display_name'] as String?,
        userAvatarUrl: profile?['avatar_url'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        commentCount: 0,
      );
    }).toList();
  }

  Future<List<ReportItem>> getReports() async {
    final data = await _supabase
        .from('reports')
        .select('*, reporter:profiles!reporter_id(display_name), reported:profiles!reported_user_id(display_name)')
        .order('created_at', ascending: false);
    return data.map((json) {
      return ReportItem(
        id: json['id'] as String,
        reporterId: json['reporter_id'] as String,
        reportedUserId: json['reported_user_id'] as String,
        postId: json['post_id'] as String?,
        reason: json['reason'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        reporterName: (json['reporter'] as Map<String, dynamic>?)?['display_name'] as String?,
        reportedUserName: (json['reported'] as Map<String, dynamic>?)?['display_name'] as String?,
      );
    }).toList();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _supabase.from('reports').update({'status': status}).eq('id', reportId);
  }

  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }
}
