// Fix #2: _sub is now wired to Supabase Realtime so new notifications
// arrive instantly without requiring screen reload.
// Fix #6: markAsRead/markAllAsRead use copyWith instead of manual rebuild.
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/firebase_uuid.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotifState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const NotifState({this.notifications = const [], this.isLoading = false});

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotifState copyWith(
      {List<NotificationModel>? notifications, bool? isLoading}) {
    return NotifState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotifState> {
  final INotificationRepository _repo;
  RealtimeChannel? _channel; // Fix #2: was StreamSubscription — now Realtime

  NotificationNotifier(this._repo) : super(const NotifState()) {
    _init();
  }

  void _init() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    loadNotifications();
    _subscribeRealtime(FirebaseUuid.toUuid(firebaseUser.uid));
  }

  // Fix #2: subscribe to INSERT events on the notifications table
  void _subscribeRealtime(String userId) {
    _channel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Prepend the new notification from payload without full reload
            try {
              final newNotif =
                  NotificationModel.fromJson(payload.newRecord);
              if (mounted) {
                state = state.copyWith(
                  notifications: [newNotif, ...state.notifications],
                );
              }
            } catch (_) {
              // Fallback: full reload
              loadNotifications();
            }
          },
        )
        .subscribe();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      final userId = FirebaseUuid.toUuid(firebaseUser.uid);
      final notifs = await _repo.getNotifications(userId);
      if (mounted) state = NotifState(notifications: notifs);
    } catch (_) {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  // Fix #6: use copyWith
  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    if (mounted) {
      state = state.copyWith(
        notifications:
            state.notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
    }
  }

  // Fix #6: use copyWith
  Future<void> markAllAsRead() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final userId = FirebaseUuid.toUuid(firebaseUser.uid);
    await _repo.markAllAsRead(userId);
    if (mounted) {
      state = state.copyWith(
        notifications:
            state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotifState>((ref) {
  return NotificationNotifier(ref.watch(notificationRepositoryProvider));
});

// ── Admin Notifications ───────────────────────────────────────────────────────

class AdminNotifState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const AdminNotifState(
      {this.notifications = const [], this.isLoading = false});

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  AdminNotifState copyWith(
      {List<NotificationModel>? notifications, bool? isLoading}) {
    return AdminNotifState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdminNotificationNotifier extends StateNotifier<AdminNotifState> {
  final INotificationRepository _repo;
  RealtimeChannel? _channel;

  AdminNotificationNotifier(this._repo) : super(const AdminNotifState()) {
    _init();
  }

  void _init() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    loadNotifications();
    _subscribeRealtime(FirebaseUuid.toUuid(firebaseUser.uid));
  }

  void _subscribeRealtime(String adminId) {
    _channel = Supabase.instance.client
        .channel('admin_notifications:$adminId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'admin_id',
            value: adminId,
          ),
          callback: (payload) {
            try {
              final newNotif =
                  NotificationModel.fromJson(payload.newRecord);
              if (mounted) {
                state = state.copyWith(
                  notifications: [newNotif, ...state.notifications],
                );
              }
            } catch (_) {
              loadNotifications();
            }
          },
        )
        .subscribe();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      final userId = FirebaseUuid.toUuid(firebaseUser.uid);
      final notifs = await _repo.getAdminNotifications(userId);
      if (mounted) state = AdminNotifState(notifications: notifs);
    } catch (_) {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  // Fix #6
  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    if (mounted) {
      state = state.copyWith(
        notifications:
            state.notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
    }
  }

  // Fix #6
  Future<void> markAllAsRead() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final userId = FirebaseUuid.toUuid(firebaseUser.uid);
    await _repo.markAllAdminAsRead(userId);
    if (mounted) {
      state = state.copyWith(
        notifications:
            state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final adminNotificationProvider =
    StateNotifierProvider<AdminNotificationNotifier, AdminNotifState>((ref) {
  return AdminNotificationNotifier(
      ref.watch(notificationRepositoryProvider));
});
