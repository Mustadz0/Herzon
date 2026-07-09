import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: state.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: Icon(Icons.notifications_none, size: 36, color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(height: 20),
                  Text('Aucune notification', style: t.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Vous serez notifié des activités près de chez vous',
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const Divider(indent: 72, endIndent: 16),
              itemBuilder: (context, index) {
                final notif = state.notifications[index];
                final isUnread = !notif.isRead;
                return ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isUnread ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _iconForType(notif.type),
                  ),
                  title: Text(notif.body, style: TextStyle(
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400)),
                  subtitle: notif.createdAt != null
                      ? Text(_formatTime(notif.createdAt!),
                          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant))
                      : null,
                  trailing: isUnread
                      ? Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle))
                      : null,
                  onTap: isUnread ? () => ref.read(notificationProvider.notifier).markAsRead(notif.id) : null,
                );
              },
            ),
    );
  }

  Widget _iconForType(String type) {
    switch (type) {
      case 'reaction': return const Icon(Icons.emoji_emotions_outlined, color: AppTheme.accent);
      case 'comment': return const Icon(Icons.chat_bubble_outline, color: Colors.green);
      case 'follow': return const Icon(Icons.person_add_outlined, color: AppTheme.primary);
      default: return const Icon(Icons.notifications_outlined, color: Colors.grey);
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
