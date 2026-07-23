import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository.dart';
import '../../core/utils/safe_error.dart';

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
  final AdminRepository _repo;

  AdminReportsNotifier(this._repo) : super(AdminReportsState()) {
    loadReports();
  }

  Future<void> loadReports({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      var reports = await _repo.getReports();
      if (status != null && status.isNotEmpty) {
        reports = reports.where((r) => r.status == status).toList();
      }
      state = state.copyWith(reports: reports, isLoading: false, filterStatus: status);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: safeErrorMessage(e));
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _repo.updateReportStatus(reportId, status);
      await loadReports(status: state.filterStatus);
    } catch (e) {
      state = state.copyWith(error: safeErrorMessage(e));
    }
  }
}

final adminReportsProvider =
    StateNotifierProvider<AdminReportsNotifier, AdminReportsState>((ref) {
  return AdminReportsNotifier(ref.watch(adminRepositoryProvider));
});
