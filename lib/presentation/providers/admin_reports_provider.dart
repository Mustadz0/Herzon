import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/admin_repository.dart';
class AdminReportsState {
  final List<ReportItem> reports;
  final bool isLoading;
  final String? error;
  final String? filterStatus;

  AdminReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });

  AdminReportsState copyWith({
    List<ReportItem>? reports,
    bool? isLoading,
    String? error,
    String? filterStatus,
  }) {
    return AdminReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }
}

class AdminReportsNotifier extends StateNotifier<AdminReportsState> {
  final SupabaseClient _supabase;

  AdminReportsNotifier(this._supabase) : super(AdminReportsState()) {
    loadReports();
  }

  Future<void> loadReports({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      var query = _supabase.from('reports').select('''
        *,
        reporter:profiles!reports_reporter_id_fkey(display_name),
        reported:profiles!reports_reported_user_id_fkey(display_name)
      ''');
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      final data = await query.order('created_at', ascending: false);
      final reports = data.map((json) => ReportItem.fromJson(json)).toList();
      state = state.copyWith(reports: reports, isLoading: false, filterStatus: status);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _supabase.rpc('admin_update_report_status', params: {
        'target_report_id': reportId,
        'new_status': status,
      });
      await loadReports(status: state.filterStatus);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final adminReportsProvider = StateNotifierProvider<AdminReportsNotifier, AdminReportsState>((ref) {
  return AdminReportsNotifier(Supabase.instance.client);
});
