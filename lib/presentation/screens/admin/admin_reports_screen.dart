import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadReports());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.reports.isEmpty) {
      return const Center(child: Text('No reports'));
    }

    return ListView.builder(
      itemCount: state.reports.length,
      itemBuilder: (context, index) {
        final report = state.reports[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text('Report: ${report.reason}', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              'by ${report.reporterName ?? "unknown"} against ${report.reportedUserName ?? "unknown"}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _StatusBadge(report.status),
            onTap: () => _showReportDialog(report),
          ),
        );
      },
    );
  }

  void _showReportDialog(dynamic report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason: ${report.reason}'),
            const SizedBox(height: 8),
            Text('From: ${report.reporterName ?? "unknown"}'),
            Text('Against: ${report.reportedUserName ?? "unknown"}'),
            if (report.postId != null) Text('Post ID: ${report.postId}'),
            const SizedBox(height: 8),
            Text('Status: ${report.status}'),
          ],
        ),
        actions: [
          if (report.status == 'pending') ...[
            TextButton(
              onPressed: () {
                ref.read(adminProvider.notifier).resolveReport(report.id, 'dismissed');
                Navigator.pop(ctx);
              },
              child: const Text('Dismiss'),
            ),
            TextButton(
              onPressed: () {
                ref.read(adminProvider.notifier).resolveReport(report.id, 'actioned');
                Navigator.pop(ctx);
              },
              child: const Text('Action Taken'),
            ),
          ],
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending' => Colors.orange,
      'dismissed' => Colors.grey,
      'reviewed' => Colors.blue,
      'actioned' => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
