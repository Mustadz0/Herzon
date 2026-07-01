import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune notification', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = state.notifications[index];
                return ListTile(
                  leading: _iconForType(notif.type),
                  title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(notif.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: notif.createdAt != null
                      ? Text(_formatTime(notif.createdAt!), style: const TextStyle(fontSize: 11, color: Colors.grey))
                      : null,
                  selected: !notif.isRead,
                  onTap: () => ref.read(notificationProvider.notifier).markAsRead(notif.id),
                );
              },
            ),
    );
  }

  Widget _iconForType(String type) {
    switch (type) {
      case 'reaction':
        return const CircleAvatar(child: Icon(Icons.emoji_emotions, color: Colors.orange));
      case 'comment':
        return const CircleAvatar(child: Icon(Icons.chat_bubble, color: Colors.blue));
      case 'follow':
        return const CircleAvatar(child: Icon(Icons.person_add, color: Colors.green));
      default:
        return const CircleAvatar(child: Icon(Icons.notifications, color: Colors.grey));
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
