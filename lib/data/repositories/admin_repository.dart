import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../../core/utils/firebase_uuid.dart';

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

  Future<void> _verifyAdmin() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) throw Exception('Not authenticated');
    final userId = FirebaseUuid.toUuid(fbUser.uid);
    final profile = await _supabase.from('profiles').select('is_admin').eq('id', userId).single();
    if (profile['is_admin'] != true) throw Exception('Unauthorized: admin only');
  }

  String _sanitizeSearch(String query) => query.replaceAll(RegExp(r'[%_]'), r'\$0');

  Future<DashboardStats> getStats() async {
    await _verifyAdmin();
    final usersCountResp = await _supabase.from('profiles').select('id').count();
    final postsCountResp = await _supabase.from('posts').select('id').count();
    final reportsCountResp = await _supabase.from('reports').select('id').eq('status', 'pending').count();
    final activeCountResp = await _supabase.from('profiles').select('id').gte('last_active_at', DateTime.now().subtract(const Duration(hours: 24)).toIso8601String()).count();

    return DashboardStats(
      totalUsers: usersCountResp.count,
      totalPosts: postsCountResp.count,
      pendingReports: reportsCountResp.count,
      activeUsersToday: activeCountResp.count,
    );
  }

  Future<List<UserModel>> getAllUsers({String? search}) async {
    await _verifyAdmin();
    var query = _supabase.from('profiles').select();
    if (search != null && search.isNotEmpty) {
      final sanitized = _sanitizeSearch(search);
      query = query.or('display_name.ilike.%$sanitized%,username.ilike.%$sanitized%');
    }
    final data = await query.order('created_at', ascending: false);
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<List<PostModel>> getAllPosts({String? search}) async {
    await _verifyAdmin();
    var query = _supabase.from('posts').select('*, profiles!inner(username, display_name, avatar_url)');
    if (search != null && search.isNotEmpty) {
      final sanitized = _sanitizeSearch(search);
      query = query.ilike('content', '%$sanitized%');
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
    await _verifyAdmin();
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
    await _supabase.rpc('admin_update_report_status', params: {
      'target_report_id': reportId,
      'new_status': status,
    });
  }

  Future<void> deletePost(String postId) async {
    await _supabase.rpc('admin_delete_post', params: {'target_post_id': postId});
  }
}
