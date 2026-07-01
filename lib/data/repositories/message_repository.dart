import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

/// Message Repository Interface
abstract class IMessageRepository {
  /// Send a message to another user
  Future<MessageModel> sendMessage({
    required String receiverId,
    required String content,
  });

  /// Get conversation between two users
  Future<List<MessageModel>> getConversation(String otherUserId);

  /// Mark messages as read
  Future<void> markAsRead(String messageId);
}

class SupabaseMessageRepository implements IMessageRepository {
  final SupabaseClient _supabase;

  SupabaseMessageRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<MessageModel> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final response = await _supabase.from('messages').insert({
      'sender_id': _supabase.auth.currentUser!.id,
      'receiver_id': receiverId,
      'content': content,
    }).select().single();

    return MessageModel.fromJson(response);
  }

  @override
  Future<List<MessageModel>> getConversation(String otherUserId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .or('sender_id.eq.${_supabase.auth.currentUser!.id},receiver_id.eq.${_supabase.auth.currentUser!.id}')
        .or('sender_id.eq.$otherUserId,receiver_id.eq.$otherUserId')
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((json) => MessageModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> markAsRead(String messageId) async {
    await _supabase.from('messages').update({'is_read': true}).eq('id', messageId);
  }
}
