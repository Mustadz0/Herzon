import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotifState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const NotifState({this.notifications = const [], this.isLoading = false});

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotifState copyWith({List<NotificationModel>? notifications, bool? isLoading}) {
    return NotifState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotifState> {
  final INotificationRepository _repo;
  StreamSubscription? _sub;

  NotificationNotifier(this._repo) : super(const NotifState()) {
    _init();
  }

  void _init() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final notifs = await _repo.getNotifications(user.id);
      state = NotifState(notifications: notifs);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    state = state.copyWith(
      notifications: state.notifications.map((n) =>
        n.id == id ? NotificationModel(id: n.id, userId: n.userId, type: n.type, title: n.title, body: n.body, data: n.data, isRead: true, createdAt: n.createdAt) : n
      ).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await _repo.markAllAsRead(user.id);
    state = state.copyWith(
      notifications: state.notifications.map((n) =>
        NotificationModel(id: n.id, userId: n.userId, type: n.type, title: n.title, body: n.body, data: n.data, isRead: true, createdAt: n.createdAt)
      ).toList(),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotifState>((ref) {
  return NotificationNotifier(ref.watch(notificationRepositoryProvider));
});
