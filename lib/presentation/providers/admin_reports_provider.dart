// Fix: AdminReportsNotifier استخدم SupabaseClient مباشرة — الآن عبر AdminRepository.
// Fix: تكرار تعريف ReportItem هنا وفي admin_repository — أبقيناه هنا كمصدر وحيد.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_provider.dart' show adminRepositoryProvider;

// ReportItem معرّف في admin_repository.dart — نعيد تصديره هنا لتجنب كسر الـ imports
export '../../data/repositories/admin_repository.dart' show ReportItem;

class AdminReportsState {
  final List<ReportItem> reports;
  final bool isLoading;
  final String? error;
  final String? filterStatus;

  const AdminReportsState({
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
  final AdminRepository _repo;

  AdminReportsNotifier(this._repo) : super(const AdminReportsState()) {
    loadReports();
  }

  Future<void> loadReports({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reports = await _repo.getReports(status: status);
      if (mounted) {
        state = state.copyWith(
          reports: reports,
          isLoading: false,
          filterStatus: status,
        );
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _repo.updateReportStatus(reportId, status);
      await loadReports(status: state.filterStatus);
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }
}

final adminReportsProvider =
    StateNotifierProvider<AdminReportsNotifier, AdminReportsState>((ref) {
  return AdminReportsNotifier(ref.watch(adminRepositoryProvider));
});
