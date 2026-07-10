import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificationProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.navDark : AppTheme.navLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: const SizedBox.expand(),
          ),
        ),
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (b) => AppTheme.brandGradient.createShader(b),
              child: Text(
                'Notifications',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (state.unreadCount > 0) ...
              [
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.unreadCount}',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
          ],
        ),
        actions: [
          if (state.notifications.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              child: Text(
                'Tout lire',
                style: tt.labelMedium?.copyWith(color: cs.primary),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? _EmptyNotifications(cs: cs, tt: tt)
              : ListView.separated(
                  padding: const EdgeInsets.only(top: kToolbarHeight + 16, bottom: 24),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (_, i) => _NotificationTile(
                    notification: state.notifications[i],
                    onTap: () => ref
                        .read(notificationProvider.notifier)
                        .markRead(state.notifications[i].id),
                  ),
                ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _EmptyNotifications({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded,
                size: 44, color: cs.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('Aucune notification',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Vous serez notifié ici des nouvelles activités',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;
  const _NotificationTile(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bool isRead = notification.isRead as bool? ?? true;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead
            ? Colors.transparent
            : cs.primary.withValues(alpha: 0.05),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / icon
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Colors.white, size: 22),
                ),
                if (!isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: cs.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title as String? ?? '',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                  if ((notification.body as String?)?.isNotEmpty == true)
                    Text(
                      notification.body as String,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
