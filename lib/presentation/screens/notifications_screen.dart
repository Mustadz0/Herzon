import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import 'user_profile_screen.dart';
import 'post_detail_screen.dart';

extension _ThemeDark on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}

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
          if (state.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 56,
                        color: t.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Aucune notification', style: t.textTheme.bodyLarge),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationProvider.notifier).loadNotifications(),
                  child: ListView.separated(
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = state.notifications[index];
                      return ListTile(
                        tileColor: n.isRead
                            ? null
                            : AppTheme.primary.withValues(alpha: 0.06),
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                n.actorAvatarUrl == null ? AppTheme.brandGradient : null,
                          ),
                          child: n.actorAvatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.network(n.actorAvatarUrl!, fit: BoxFit.cover))
                              : Icon(_iconForType(n.type),
                                  color: Colors.white, size: 20),
                        ),
                        title: Text(
                          _labelForNotif(n),
                          style: t.textTheme.bodyMedium?.copyWith(
                            fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        subtitle: n.createdAt != null
                            ? Text(_formatTime(n.createdAt!),
                                style: t.textTheme.bodySmall)
                            : null,
                        trailing: n.isRead
                            ? null
                            : Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary,
                                ),
                              ),
                        onTap: () {
                          if (!n.isRead) {
                            ref.read(notificationProvider.notifier).markAsRead(n.id);
                          }
                          _handleTap(context, n);
                        },
                      );
                    },
                  ),
                ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'like': return Icons.favorite;
      case 'comment': return Icons.chat_bubble;
      case 'follow': return Icons.person_add;
      case 'mention': return Icons.alternate_email;
      default: return Icons.notifications;
    }
  }

  String _labelForNotif(dynamic n) {
    final actor = n.actorName ?? 'Quelqu\'un';
    switch (n.type) {
      case 'like': return '$actor a réagi à votre publication';
      case 'comment': return '$actor a commenté votre publication';
      case 'follow': return '$actor vous suit maintenant';
      case 'mention': return '$actor vous a mentionné';
      default: return n.body ?? 'Nouvelle notification';
    }
  }

  void _handleTap(BuildContext context, dynamic n) {
    if (n.actorId != null && (n.type == 'follow')) {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: n.actorId!)));
    }
    // post-related → navigate to post (requires postId on model)
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
