import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/message_repository.dart';

/// Provider for message repository
final messageRepositoryProvider = Provider<IMessageRepository>((ref) {
  return SupabaseMessageRepository(supabase: Supabase.instance.client);
});

/// Conversations list provider
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, AsyncValue<List<ConversationModel>>>((ref) {
  return ConversationsNotifier(ref.read(messageRepositoryProvider));
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final IMessageRepository _repository;

  ConversationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = const AsyncValue.loading();
    try {
      final conversations = await _repository.getConversations();
      state = AsyncValue.data(conversations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Messages provider for a specific conversation
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, AsyncValue<List<MessageModel>>, String>((ref, conversationId) {
  return MessagesNotifier(
    ref.read(messageRepositoryProvider),
    conversationId,
  );
});

class MessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final IMessageRepository _repository;
  final String conversationId;
  StreamSubscription? _subscription;

  MessagesNotifier(this._repository, this.conversationId) : super(const AsyncValue.loading()) {
    loadMessages();
    _subscribeToMessages();
  }

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getMessages(conversationId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToMessages() {
    _subscription = _repository.subscribeToMessages(conversationId).listen(
      (message) {
        state.whenData((messages) {
          if (!messages.any((m) => m.id == message.id)) {
            state = AsyncValue.data([...messages, message]);
          }
        });
      },
    );
  }

  Future<void> sendMessage({
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    String? stickerId,
  }) async {
    try {
      final message = await _repository.sendMessage(
        conversationId: conversationId,
        content: content,
        messageType: messageType,
        mediaUrl: mediaUrl,
        stickerId: stickerId,
      );
      state.whenData((messages) {
        state = AsyncValue.data([...messages, message]);
      });
    } catch (e) {
      // Error handled by state
    }
  }

  Future<void> markAsRead() async {
    try {
      await _repository.markAsRead(conversationId);
    } catch (e) {
      // Error handled silently
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Current conversation ID provider
final currentConversationIdProvider = StateProvider<String?>((ref) => null);

/// Total unread messages count provider
final totalUnreadProvider = Provider<AsyncValue<int>>((ref) {
  final conversationsAsync = ref.watch(conversationsProvider);
  return conversationsAsync.whenData(
    (conversations) => conversations.fold(0, (sum, c) => sum + c.unreadCount),
  );
});
