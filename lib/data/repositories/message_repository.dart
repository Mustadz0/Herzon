import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

/// Message Repository Interface
abstract class IMessageRepository {
  /// Get or create a conversation
  Future<String> getOrCreateConversation(String otherUserId);

  /// Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    String? stickerId,
  });

  /// Get messages in a conversation
  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 50});

  /// Get conversation list
  Future<List<ConversationModel>> getConversations();

  /// Mark messages as read
  Future<void> markAsRead(String conversationId);

  /// Subscribe to new messages
  Stream<MessageModel> subscribeToMessages(String conversationId);
}

class SupabaseMessageRepository implements IMessageRepository {
  final SupabaseClient _supabase;

  SupabaseMessageRepository({required SupabaseClient supabase}) : _supabase = supabase;

  @override
  Future<String> getOrCreateConversation(String otherUserId) async {
    final response = await _supabase.rpc('get_or_create_conversation', params: {
      'other_user_id': otherUserId,
    });
    return response as String;
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    String? stickerId,
  }) async {
    final response = await _supabase.rpc('send_message', params: {
      'p_conversation_id': conversationId,
      'p_content': content,
      'p_message_type': messageType,
      'p_media_url': mediaUrl,
      'p_sticker_id': stickerId,
    });
    return MessageModel.fromJson(response);
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 50}) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((json) => MessageModel.fromJson(json))
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await _supabase.rpc('get_conversations');
    return (response as List<dynamic>)
        .map((json) => ConversationModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    await _supabase.rpc('mark_messages_read', params: {
      'p_conversation_id': conversationId,
    });
  }

  @override
  Stream<MessageModel> subscribeToMessages(String conversationId) {
    // FIX: كان يرمي StateError عند stream فارغ — الآن يتجاهل الحدث الفارغ
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .where((events) => events.isNotEmpty)
        .map((events) => MessageModel.fromJson(events.last));
  }
}
