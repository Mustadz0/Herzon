import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/notification_provider.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNotificationProvider);
    final filteredNotifs = _selectedFilter == 'all'
        ? state.notifications
        : state.notifications.where((n) => n.type == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Toutes'),
                  const SizedBox(width: 8),
                  _buildFilterChip('report', 'Signalements'),
                  const SizedBox(width: 8),
                  _buildFilterChip('user_verification', 'Verification'),
                  const SizedBox(width: 8),
                  _buildFilterChip('content_flagged', 'Contenu'),
                  const SizedBox(width: 8),
                  _buildFilterChip('support_request', 'Support'),
                  const SizedBox(width: 8),
                  _buildFilterChip('system_alert', 'Systeme'),
                ],
              ),
            ),
          ),
          // Unread count badge
          if (state.unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primary.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.circle_notifications, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${state.unreadCount} non lue(s)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref.read(adminNotificationProvider.notifier).markAllAsRead(),
                    child: const Text('Tout marquer lu'),
                  ),
                ],
              ),
            ),
          // Notifications list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                : filteredNotifs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune notification',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredNotifs.length,
                        separatorBuilder: (_, __) => const Divider(indent: 72, endIndent: 16),
                        itemBuilder: (context, index) {
                          final notif = filteredNotifs[index];
                          final isUnread = !notif.isRead;
                          return ListTile(
                            leading: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isUnread
                                    ? _colorForType(notif.type).withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _iconForType(notif.type),
                            ),
                            title: Text(
                              notif.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              notif.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            trailing: isUnread
                                ? Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                            onTap: isUnread
                                ? () => ref.read(adminNotificationProvider.notifier).markAsRead(notif.id)
                                : null,
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
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _iconForType(String type) {
    switch (type) {
      case 'report': return const Icon(Icons.flag_outlined, color: Colors.orange);
      case 'user_verification': return const Icon(Icons.verified_user_outlined, color: Colors.blue);
      case 'content_flagged': return const Icon(Icons.warning_amber_outlined, color: Colors.red);
      case 'support_request': return const Icon(Icons.support_agent_outlined, color: Colors.teal);
      case 'system_alert': return const Icon(Icons.system_update_outlined, color: Colors.purple);
      default: return const Icon(Icons.notifications_outlined, color: Colors.grey);
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'report': return Colors.orange;
      case 'user_verification': return Colors.blue;
      case 'content_flagged': return Colors.red;
      case 'support_request': return Colors.teal;
      case 'system_alert': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
