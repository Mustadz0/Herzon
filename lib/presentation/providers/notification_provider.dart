import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../core/utils/firebase_uuid.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final notifs = await _repo.getNotifications(FirebaseUuid.toUuid(user.uid));
      state = NotifState(notifications: notifs);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    state = state.copyWith(
      notifications: state.notifications.map((n) =>
        n.id == id ? NotificationModel(
          id: n.id, userId: n.userId, adminId: n.adminId, type: n.type,
          recipientType: n.recipientType, title: n.title, body: n.body,
          data: n.data, isRead: true, createdAt: n.createdAt,
        ) : n
      ).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _repo.markAllAsRead(FirebaseUuid.toUuid(user.uid));
    state = state.copyWith(
      notifications: state.notifications.map((n) =>
        NotificationModel(
          id: n.id, userId: n.userId, adminId: n.adminId, type: n.type,
          recipientType: n.recipientType, title: n.title, body: n.body,
          data: n.data, isRead: true, createdAt: n.createdAt,
        )
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

// --- Admin Notifications ---

class AdminNotifState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const AdminNotifState({this.notifications = const [], this.isLoading = false});

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  AdminNotifState copyWith({List<NotificationModel>? notifications, bool? isLoading}) {
    return AdminNotifState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdminNotificationNotifier extends StateNotifier<AdminNotifState> {
  final INotificationRepository _repo;

  AdminNotificationNotifier(this._repo) : super(const AdminNotifState()) {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final notifs = await _repo.getAdminNotifications(FirebaseUuid.toUuid(user.uid));
      state = AdminNotifState(notifications: notifs);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    state = state.copyWith(
      notifications: state.notifications.map((n) =>
        n.id == id ? NotificationModel(
          id: n.id, userId: n.userId, adminId: n.adminId, type: n.type,
          recipientType: n.recipientType, title: n.title, body: n.body,
          data: n.data, isRead: true, createdAt: n.createdAt,
        ) : n
      ).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _repo.markAllAdminAsRead(FirebaseUuid.toUuid(user.uid));
    state = state.copyWith(
      notifications: state.notifications.map((n) =>
        NotificationModel(
          id: n.id, userId: n.userId, adminId: n.adminId, type: n.type,
          recipientType: n.recipientType, title: n.title, body: n.body,
          data: n.data, isRead: true, createdAt: n.createdAt,
        )
      ).toList(),
    );
  }
}

final adminNotificationProvider = StateNotifierProvider<AdminNotificationNotifier, AdminNotifState>((ref) {
  return AdminNotificationNotifier(ref.watch(notificationRepositoryProvider));
});
