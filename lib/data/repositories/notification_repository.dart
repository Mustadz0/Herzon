import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

abstract class INotificationRepository {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<List<NotificationModel>> getAdminNotifications(String adminId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> markAllAdminAsRead(String adminId);
  Future<void> createNotification({
    String? userId,
    String? adminId,
    required String recipientType,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
  Future<int> getUnreadAdminCount(String adminId);
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
        .eq('recipient_type', 'user')
        .order('created_at', ascending: false)
        .limit(50);
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  @override
  Future<List<NotificationModel>> getAdminNotifications(String adminId) async {
    final data = await _supabase
        .from('notifications')
        .select()
        .eq('admin_id', adminId)
        .eq('recipient_type', 'admin')
        .order('created_at', ascending: false)
        .limit(100);
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _supabase.from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('recipient_type', 'user')
        .eq('is_read', false);
  }

  @override
  Future<void> markAllAdminAsRead(String adminId) async {
    await _supabase.from('notifications')
        .update({'is_read': true})
        .eq('admin_id', adminId)
        .eq('recipient_type', 'admin')
        .eq('is_read', false);
  }

  @override
  Future<void> createNotification({
    String? userId,
    String? adminId,
    required String recipientType,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'admin_id': adminId,
      'recipient_type': recipientType,
      'type': type,
      'title': title,
      'body': body,
      'data': data ?? {},
    });
  }

  @override
  Future<int> getUnreadAdminCount(String adminId) async {
    final data = await _supabase
        .from('notifications')
        .select('id')
        .eq('admin_id', adminId)
        .eq('recipient_type', 'admin')
        .eq('is_read', false);
    return (data as List).length;
  }
}

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return SupabaseNotificationRepository(supabase: Supabase.instance.client);
});
