import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

abstract class INotificationRepository {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Stream<List<NotificationModel>> subscribeToNotifications(String userId);
}

class SupabaseNotificationRepository implements INotificationRepository {
  final SupabaseClient _supabase;

  SupabaseNotificationRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final data = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('is_read', false);
  }

  @override
  Stream<List<NotificationModel>> subscribeToNotifications(String userId) {
    return _supabase
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (payload) {},
        )
        .subscribe()
        .cast();
  }
}

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return SupabaseNotificationRepository(supabase: Supabase.instance.client);
});
