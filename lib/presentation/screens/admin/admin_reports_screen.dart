import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_reports_provider.dart';
import '../../widgets/admin/admin_report_card.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(adminReportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('pending', 'En attente'),
                const SizedBox(width: 8),
                _buildFilterChip('reviewed', 'Examinés'),
                const SizedBox(width: 8),
                _buildFilterChip('resolved', 'Résolus'),
                const SizedBox(width: 8),
                _buildFilterChip('dismissed', 'Rejetés'),
              ],
            ),
          ),
          Expanded(
            child: reportsState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                : reportsState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur: ${reportsState.error}',
                              style: GoogleFonts.plusJakartaSans(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(adminReportsProvider.notifier).loadReports(status: _selectedFilter),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : reportsState.reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flag_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun signalement',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: reportsState.reports.length,
                            itemBuilder: (context, index) {
                              final report = reportsState.reports[index];
                              return AdminReportCard(
                                report: report,
                                onStatusChanged: (status) {
                                  ref.read(adminReportsProvider.notifier).updateReportStatus(
                                        report.id,
                                        status,
                                      );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = value);
          ref.read(adminReportsProvider.notifier).loadReports(status: value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
